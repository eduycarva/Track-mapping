function fig = plotTrackDiagnostics(trackData)
% PLOTTRACKDIAGNOSTICS  Generate diagnostic plots for track verification.
%
%   plotTrackDiagnostics(trackData)
%
%   Creates a figure with 6 subplots to help the user verify that the
%   GPX data was processed correctly before entering it into CarSim.
%
%   Input:
%       trackData - struct returned by computeTrackGeometry()
%
%   Plots generated:
%       1. XY Track Map  (raw vs smoothed, with start/end markers)
%       2. 3D Track View (colored by elevation)
%       3. Curvature κ vs Station S
%       4. Elevation Z vs Station S
%       5. Grade % vs Station S
%       6. Heading θ vs Station S
%
%   See also: computeTrackGeometry, gpx_to_carsim

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE eesc-usp Tupã  |  Performance
% -------------------------------------------------------------------------

    S   = trackData.S;
    X   = trackData.X;
    Y   = trackData.Y;
    Z   = trackData.Z;
    kap = trackData.curvature;
    grd = trackData.grade;
    th  = trackData.theta;

    X_raw = trackData.X_raw;
    Y_raw = trackData.Y_raw;

    %% Create figure
    fig = figure('Name', 'GPX-to-CarSim Track Diagnostics', ...
                 'NumberTitle', 'off', ...
                 'Color', 'w', ...
                 'Position', [50, 50, 1400, 900]);

    % =====================================================================
    %  Plot 1 — XY Track Map
    % =====================================================================
    subplot(2, 3, 1);
    plot(X_raw, Y_raw, 'o', 'Color', [0.7 0.7 0.7], ...
         'MarkerSize', 4, 'DisplayName', 'Raw GPS');
    hold on;
    plot(X, Y, '-b', 'LineWidth', 1.5, 'DisplayName', 'Smoothed');
    if isfield(trackData, 'isClosed') && trackData.isClosed
        plot(X(1), Y(1), 'gs', 'MarkerSize', 12, 'MarkerFaceColor', 'g', ...
             'DisplayName', 'Start / Finish');
    else
        plot(X(1), Y(1), 'gs', 'MarkerSize', 12, 'MarkerFaceColor', 'g', ...
             'DisplayName', 'Start');
        plot(X(end), Y(end), 'r^', 'MarkerSize', 12, 'MarkerFaceColor', 'r', ...
             'DisplayName', 'End');
    end

    % Direction arrows every ~10% of the track
    nArrows = 10;
    idxArrows = round(linspace(2, length(X)-1, nArrows));
    for k = idxArrows
        dx = X(k+1) - X(k-1);
        dy = Y(k+1) - Y(k-1);
        sc = 0.15 * trackData.totalLength / nArrows;
        norm_d = sqrt(dx^2 + dy^2);
        if norm_d > 0
            quiver(X(k), Y(k), dx/norm_d*sc, dy/norm_d*sc, 0, ...
                   'Color', [0 0.5 1], 'MaxHeadSize', 2, ...
                   'LineWidth', 1.2, 'HandleVisibility', 'off');
        end
    end

    hold off;
    axis equal; grid on;
    xlabel('East X [m]');
    ylabel('North Y [m]');
    title('Track Map (XY)');
    legend('Location', 'best');

    % =====================================================================
    %  Plot 2 — 3D Track View
    % =====================================================================
    subplot(2, 3, 2);
    % Color by elevation
    patch([X; NaN], [Y; NaN], [Z; NaN], [Z; NaN], ...
          'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 2);
    colorbar;
    hold on;
    plot3(X(1), Y(1), Z(1), 'gs', 'MarkerSize', 12, ...
          'MarkerFaceColor', 'g');
    hold off;
    axis equal; grid on; view(3);
    xlabel('East X [m]');
    ylabel('North Y [m]');
    zlabel('Elevation Z [m]');
    title('3D Track View');

    % =====================================================================
    %  Plot 3 — Curvature vs Station
    % =====================================================================
    subplot(2, 3, 3);
    plot(S, kap, '-r', 'LineWidth', 1.2);
    hold on;
    yline(0, '--', 'Color', [0.5 0.5 0.5]);
    hold off;
    grid on;
    xlabel('Station S [m]');
    ylabel('Curvature \kappa [1/m]');
    title('Curvature Profile');

    % Add a secondary Y-axis for turn radius
    yyaxis right;
    R_turn = 1 ./ max(abs(kap), 1e-6);
    R_turn(abs(kap) < 1e-4) = NaN;  % suppress near-straight values
    plot(S, R_turn, ':m', 'LineWidth', 0.8);
    ylabel('Turn Radius R [m]');
    set(gca, 'YScale', 'log');
    ylim([1, max(R_turn(~isnan(R_turn)))*2]);

    % =====================================================================
    %  Plot 4 — Elevation vs Station
    % =====================================================================
    subplot(2, 3, 4);
    eleAbsolute = Z + trackData.Z_raw(1);  % recover absolute elevation
    plot(S, eleAbsolute, '-k', 'LineWidth', 1.5);
    grid on;
    xlabel('Station S [m]');
    ylabel('Elevation [m a.s.l.]');
    title('Elevation Profile');

    % Add ΔZ on right axis
    yyaxis right;
    plot(S, Z, '-', 'Color', [0 0.6 0.3], 'LineWidth', 1);
    ylabel('\DeltaZ from start [m]');

    % =====================================================================
    %  Plot 5 — Grade vs Station
    % =====================================================================
    subplot(2, 3, 5);
    area(S, grd, 'FaceColor', [0.3 0.6 1], 'FaceAlpha', 0.4, ...
         'EdgeColor', [0 0.3 0.7], 'LineWidth', 1.2);
    hold on;
    yline(0, '--', 'Color', [0.5 0.5 0.5]);
    hold off;
    grid on;
    xlabel('Station S [m]');
    ylabel('Grade [%]');
    title('Grade Profile');

    % =====================================================================
    %  Plot 6 — Heading vs Station
    % =====================================================================
    subplot(2, 3, 6);
    plot(S, rad2deg(th), '-', 'Color', [0.6 0.2 0.8], 'LineWidth', 1.2);
    grid on;
    xlabel('Station S [m]');
    ylabel('Heading \theta [deg]');
    title('Heading Profile');

    %% Super-title
    sgtitle(sprintf('GPX → CarSim  |  Track Length = %.1f m  |  %d points  |  Smooth window = %d', ...
            trackData.totalLength, trackData.nPoints, trackData.smoothWindow), ...
            'FontSize', 13, 'FontWeight', 'bold');

    fprintf('plotTrackDiagnostics: figure created.\n');
end
