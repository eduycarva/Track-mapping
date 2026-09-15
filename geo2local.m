function [X, Y, Z] = geo2local(lat, lon, ele)
% GEO2LOCAL  Convert geodetic (lat, lon, ele) to local Cartesian (X, Y, Z).
%
%   [X, Y, Z] = geo2local(lat, lon, ele)
%
%   Uses a flat-Earth approximation with the first point as the origin.
%   No Mapping Toolbox required.
%
%   Inputs:
%       lat - Column vector of latitudes  [deg]
%       lon - Column vector of longitudes [deg]
%       ele - Column vector of elevations [m]
%
%   Outputs:
%       X - East  displacement from origin [m] (N x 1)
%       Y - North displacement from origin [m] (N x 1)
%       Z - Elevation relative to origin   [m] (N x 1)
%
%   The approximation is accurate to < 0.1% for distances under 10 km,
%   which is more than sufficient for any FSAE track.
%
%   Example:
%       [X, Y, Z] = geo2local(lat, lon, ele);
%
%   See also: parseGPX, gpx_to_carsim

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE eesc-usp Tupã  |  Performance
% -------------------------------------------------------------------------

    %% Earth radius (WGS-84 mean radius)
    R_EARTH = 6371000;  % [m]

    %% Reference origin = first point
    lat0 = lat(1);
    lon0 = lon(1);
    ele0 = ele(1);

    %% Convert degrees to radians for trig functions
    lat0_rad = deg2rad(lat0);

    %% Flat-Earth projection
    %   X (East)  = R * cos(lat0) * delta_lon
    %   Y (North) = R * delta_lat
    X = R_EARTH * cos(lat0_rad) .* deg2rad(lon - lon0);
    Y = R_EARTH                 .* deg2rad(lat - lat0);
    Z = ele - ele0;

    %% Summary
    fprintf('geo2local: origin at (%.6f, %.6f), ele = %.2f m\n', ...
            lat0, lon0, ele0);
    fprintf('  X range: [%.2f, %.2f] m  (East)\n',  min(X), max(X));
    fprintf('  Y range: [%.2f, %.2f] m  (North)\n', min(Y), max(Y));
    fprintf('  Z range: [%.2f, %.2f] m  (Up)\n',    min(Z), max(Z));
end
