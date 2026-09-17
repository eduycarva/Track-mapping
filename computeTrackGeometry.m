function trackData = computeTrackGeometry(X, Y, Z, smoothWindow)
% COMPUTETRACKGEOMETRY  Compute station, heading, curvature, and grade.
%
%   trackData = computeTrackGeometry(X, Y, Z)
%   trackData = computeTrackGeometry(X, Y, Z, smoothWindow)
%
%   Cleans the input path (removes duplicates), applies smoothing (with
%   periodic/circular boundary conditions for closed circuits), then
%   computes all geometric properties that CarSim needs for road definition.
%
%   Inputs:
%       X            - East  coordinates [m] (N x 1)
%       Y            - North coordinates [m] (N x 1)
%       Z            - Elevation relative to start [m] (N x 1)
%       smoothWindow - (optional) Smoothing window size [points]. Default: 5
%
%   Output:
%       trackData - struct with fields:
%           .X_raw, .Y_raw, .Z_raw     - Original input (before cleaning)
%           .X, .Y, .Z                 - Cleaned & smoothed coordinates
%           .S                         - Cumulative station [m]
%           .theta                     - Heading angle [rad]
%           .curvature                 - Signed curvature κ [1/m]
%           .grade                     - Road grade [%]
%           .totalLength               - Total track length [m]
%           .nPoints                   - Number of points after cleaning
%           .smoothWindow              - Smoothing window used
%           .isClosed                  - Boolean: true if track is a closed loop
%
%   Curvature sign convention (matches CarSim):
%       κ > 0  →  turning LEFT
%       κ < 0  →  turning RIGHT
%
%   See also: parseGPX, geo2local, gpx_to_carsim

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE EESC-USP Tupã  |  Performance
% -------------------------------------------------------------------------

    %% Default smoothing window
    if nargin < 4 || isempty(smoothWindow)
        smoothWindow = 5;
    end

    % Ensure column vectors
    X = X(:);  Y = Y(:);  Z = Z(:);

    % Store raw data
    trackData.X_raw = X;
    trackData.Y_raw = Y;
    trackData.Z_raw = Z;

    % =====================================================================
    %  STAGE 3 — DATA CLEANING & CLOSED-LOOP DETECTION
    % =====================================================================

    %% 3a. Remove duplicate / near-duplicate consecutive points
    dXY = sqrt(diff(X).^2 + diff(Y).^2);
    keep = [true; dXY > 0.01];   % keep points that moved > 1 cm
    X = X(keep);
    Y = Y(keep);
    Z = Z(keep);

    nRemoved = sum(~keep);
    if nRemoved > 0
        fprintf('computeTrackGeometry: removed %d duplicate point(s)\n', ...
                nRemoved);
    end

    N = length(X);
    if N < 4
        error('computeTrackGeometry:tooFewPoints', ...
              'Need at least 4 unique points, got %d.', N);
    end

    %% 3b. Detect if track is a closed loop
    % Check distance between the first and last point
    dStartEnd = sqrt((X(1) - X(end))^2 + (Y(1) - Y(end))^2);
    approxLength = sum(sqrt(diff(X).^2 + diff(Y).^2));
    
    % Closed circuit if endpoints are within 15 meters or 5% of path length
    isClosed = (dStartEnd < 15) || (dStartEnd < 0.05 * approxLength);

    if isClosed
        % Snap the end point exactly to the start point so the loop is mathematically closed
        X(end) = X(1);
        Y(end) = Y(1);
        Z(end) = Z(1);
        fprintf('computeTrackGeometry: closed loop detected (gap = %.2f m -> snapped to 0.00 m).\n', dStartEnd);
    end

    %% 3c. Smoothing (moving average with periodic boundary condition)
    w = min(smoothWindow, N);
    if w >= 3
        if isClosed && N > w
            % Circular/periodic padding for closed loops:
            % For index 1, the preceding points are N-k .. N-1 (since point N == point 1)
            % For index N, the succeeding points are 2 .. k+1
            k = floor(w / 2);
            X_ext = [X(N-k:N-1); X; X(2:k+1)];
            Y_ext = [Y(N-k:N-1); Y; Y(2:k+1)];
            Z_ext = [Z(N-k:N-1); Z; Z(2:k+1)];

            Xs = smoothdata(X_ext, 'movmean', w);
            Ys = smoothdata(Y_ext, 'movmean', w);
            Zs = smoothdata(Z_ext, 'movmean', w);

            X = Xs(k+1 : k+N);
            Y = Ys(k+1 : k+N);
            Z = Zs(k+1 : k+N);

            % Re-enforce exact closure after smoothing
            X(end) = X(1);
            Y(end) = Y(1);
            Z(end) = Z(1);
        else
            X = smoothdata(X, 'movmean', w);
            Y = smoothdata(Y, 'movmean', w);
            Z = smoothdata(Z, 'movmean', w);
        end
    end

    % =====================================================================
    %  STAGE 4 — CUMULATIVE DISTANCE  (STATION  S)
    % =====================================================================

    ds = sqrt(diff(X).^2 + diff(Y).^2 + diff(Z).^2);
    S  = [0; cumsum(ds)];

    % =====================================================================
    %  STAGE 5 — HEADING ANGLE  θ(S)
    % =====================================================================

    dX = zeros(N, 1);
    dY = zeros(N, 1);

    % Interior points (central difference)
    dX(2:N-1) = X(3:N) - X(1:N-2);
    dY(2:N-1) = Y(3:N) - Y(1:N-2);

    if isClosed
        % Continuous tangent at start/finish line
        dX(1) = X(2) - X(N-1);
        dY(1) = Y(2) - Y(N-1);
        dX(N) = dX(1);
        dY(N) = dY(1);
    else
        % Boundaries (forward / backward)
        dX(1) = X(2) - X(1);    dY(1) = Y(2) - Y(1);
        dX(N) = X(N) - X(N-1);  dY(N) = Y(N) - Y(N-1);
    end

    theta = atan2(dY, dX);
    theta = unwrap(theta);     % remove ±π jumps

    % =====================================================================
    %  STAGE 6 — CURVATURE  κ(S)   (parametric formula)
    % =====================================================================

    % First derivatives (central differences)
    Xp = zeros(N, 1);   Yp = zeros(N, 1);
    Xp(2:N-1) = (X(3:N) - X(1:N-2)) ./ (S(3:N) - S(1:N-2));
    Yp(2:N-1) = (Y(3:N) - Y(1:N-2)) ./ (S(3:N) - S(1:N-2));

    if isClosed
        dS_seam = (S(N) - S(N-1)) + (S(2) - S(1));
        Xp(1) = (X(2) - X(N-1)) / dS_seam;
        Yp(1) = (Y(2) - Y(N-1)) / dS_seam;
        Xp(N) = Xp(1);
        Yp(N) = Yp(1);
    else
        Xp(1) = (X(2) - X(1)) / ds(1);
        Yp(1) = (Y(2) - Y(1)) / ds(1);
        Xp(N) = (X(N) - X(N-1)) / ds(N-1);
        Yp(N) = (Y(N) - Y(N-1)) / ds(N-1);
    end

    % Second derivatives (central differences)
    Xpp = zeros(N, 1);  Ypp = zeros(N, 1);
    Xpp(2:N-1) = (Xp(3:N) - Xp(1:N-2)) ./ (S(3:N) - S(1:N-2));
    Ypp(2:N-1) = (Yp(3:N) - Yp(1:N-2)) ./ (S(3:N) - S(1:N-2));

    if isClosed
        dS_seam = (S(N) - S(N-1)) + (S(2) - S(1));
        Xpp(1) = (Xp(2) - Xp(N-1)) / dS_seam;
        Ypp(1) = (Yp(2) - Yp(N-1)) / dS_seam;
        Xpp(N) = Xpp(1);
        Ypp(N) = Ypp(1);
    else
        Xpp(1) = Xpp(2);    Ypp(1) = Ypp(2);
        Xpp(N) = Xpp(N-1);  Ypp(N) = Ypp(N-1);
    end

    % Signed curvature:   κ = (X' Y'' - Y' X'') / (X'^2 + Y'^2)^(3/2)
    denom     = (Xp.^2 + Yp.^2).^(3/2);
    curvature = (Xp .* Ypp - Yp .* Xpp) ./ denom;

    % Guard against division by zero (stationary points)
    curvature(denom < 1e-12) = 0;

    % =====================================================================
    %  STAGE 7 — GRADE & ELEVATION
    % =====================================================================

    grade = zeros(N, 1);
    grade(2:N-1) = (Z(3:N) - Z(1:N-2)) ./ (S(3:N) - S(1:N-2)) * 100;

    if isClosed
        dS_seam = (S(N) - S(N-1)) + (S(2) - S(1));
        grade(1) = (Z(2) - Z(N-1)) / dS_seam * 100;
        grade(N) = grade(1);
    else
        grade(1) = (Z(2) - Z(1)) / ds(1) * 100;
        grade(N) = (Z(N) - Z(N-1)) / ds(N-1) * 100;
    end

    % =====================================================================
    %  PACK OUTPUT
    % =====================================================================

    trackData.X            = X;
    trackData.Y            = Y;
    trackData.Z            = Z;
    trackData.S            = S;
    trackData.theta        = theta;
    trackData.curvature    = curvature;
    trackData.grade        = grade;
    trackData.totalLength  = S(end);
    trackData.nPoints      = N;
    trackData.smoothWindow = w;
    trackData.isClosed     = isClosed;

    %% Summary
    fprintf('computeTrackGeometry: %d points, total length = %.2f m\n', ...
            N, S(end));
    if isClosed
        fprintf('  Circuit type   : Closed loop\n');
    else
        fprintf('  Circuit type   : Open track\n');
    end
    fprintf('  Curvature range: [%.4f, %.4f] 1/m\n', ...
            min(curvature), max(curvature));
    fprintf('  Min turn radius: %.2f m\n', ...
            1 / max(abs(curvature(abs(curvature) > 1e-6))));
    fprintf('  Grade range:     [%.2f, %.2f] %%\n', ...
            min(grade), max(grade));
end
