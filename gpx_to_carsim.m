%% GPX_TO_CARSIM  —  Convert a .gpx track file into CarSim road data.
%
%  Main script that orchestrates the full pipeline:
%    1. Parse .gpx file  →  lat, lon, ele
%    2. Convert to local Cartesian  →  X, Y, Z  [meters]
%    3. Clean, smooth, and compute track geometry
%    4. Rotate coordinates so initial heading aligns with East (+X)
%       (CarSim always starts the vehicle heading East)
%    5. Export CarSim-ready 3D coordinate tables (RdEdges format: X, Y, Z, S)
%    6. Generate diagnostic plots
%
%  USAGE:
%    Run this script. A file browser will open for you to select a .gpx file.
%    Alternatively, set the variable 'gpxFile' before running to automate.
%
%  OUTPUTS (saved to ./output/<trackName>_<timestamp>/):
%    carsim_rdedges.csv    — X [m], Y [m], Z [m], Station [m] (Header '0, 1, 2, 3')
%    rdedges.csv           — Alias to carsim_rdedges.csv
%    carsim_xyz.csv        — X [m], Y [m], Z [m] (Header '0, 1, 2')
%    elevation.csv         — Station [m] vs Elevation [m]
%    grade.csv             — Station [m] vs Grade [%]
%    track_data.mat        — Full trackData struct for later use
%    track_diagnostics.png — 6-panel diagnostic figure
%
%  After running, insert the data into CarSim:
%    • Road: 3D Surface / X-Y-Z Coordinates of Edges (ou Reference Line)
%      Paste or import carsim_rdedges.csv (columns: X, Y, Z, S).
%      CarSim automatically computes the path, curvature, and elevation!
%
%  See also: parseGPX, geo2local, computeTrackGeometry, plotTrackDiagnostics

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE EESC-USP Tupã  |  Performance
% -------------------------------------------------------------------------

% Clear workspace variables except if explicitly automated via gpxFile
if exist('gpxFile', 'var') && ~isempty(gpxFile)
    clearvars -except gpxFile;
else
    clear;
end
clc; close all;

%% ========================================================================
%  USER CONFIGURATION
%  ========================================================================

% Smoothing window size (number of points for moving average).
% Smaller = preserves sharp corners, Larger = smoother curve.
% Recommended range: 3–7 for typical GPX density.
SMOOTH_WINDOW = 5;

% Output directory (relative to this script's location)
OUTPUT_DIR = fullfile(fileparts(mfilename('fullpath')), 'output');

%% ========================================================================
%  STAGE 1 — SELECT AND PARSE GPX FILE
%  ========================================================================

fprintf('=== GPX-to-CarSim Track Builder ===\n\n');

% Default search directory for tracks
tracksDir = fullfile(fileparts(mfilename('fullpath')), 'pistas');
if ~exist(tracksDir, 'dir')
    tracksDir = pwd;
end

% File selection dialog — always prompts user unless gpxFile was pre-defined
if ~exist('gpxFile', 'var') || isempty(gpxFile)
    [fileName, filePath] = uigetfile({'*.gpx', 'GPX Files (*.gpx)'}, ...
                                      'Select a GPX track file', tracksDir);
    if isequal(fileName, 0)
        fprintf('No file selected. Aborting.\n');
        return;
    end
    gpxFile = fullfile(filePath, fileName);
end

[~, trackName, ~] = fileparts(gpxFile);
fileName = [trackName, '.gpx'];
fprintf('Selected file: %s\n\n', gpxFile);

% Parse
[lat, lon, ele] = parseGPX(gpxFile);
fprintf('\n');

%% ========================================================================
%  STAGE 2 — COORDINATE CONVERSION
%  ========================================================================

[X, Y, Z] = geo2local(lat, lon, ele);
fprintf('\n');

%% ========================================================================
%  STAGES 3–7 — GEOMETRY COMPUTATION
%  ========================================================================

trackData = computeTrackGeometry(X, Y, Z, SMOOTH_WINDOW);
fprintf('\n');

%% ========================================================================
%  STAGE 8 — ROTATE COORDINATES TO ALIGN INITIAL HEADING WITH EAST (+X)
%  ========================================================================
%  CarSim always starts the vehicle heading East (positive X direction).
%  If the track's initial segment points in a different direction, the car
%  will start "sideways" or even backwards.  We fix this by rotating all
%  X-Y coordinates so that the first segment of the smoothed track points
%  exactly along +X.  Station S, curvature, and grade are invariant under
%  rotation, so they need no change.

theta0 = trackData.theta(1);   % initial heading [rad], already from smoothed data

cosA = cos(-theta0);
sinA = sin(-theta0);

% Pivot point = start of smoothed path
x0 = trackData.X(1);
y0 = trackData.Y(1);

% Rotate smoothed coordinates
dX = trackData.X - x0;
dY = trackData.Y - y0;
trackData.X = x0 + dX * cosA - dY * sinA;
trackData.Y = y0 + dX * sinA + dY * cosA;

% Rotate raw coordinates (used in diagnostic plots)
dX_raw = trackData.X_raw - x0;
dY_raw = trackData.Y_raw - y0;
trackData.X_raw = x0 + dX_raw * cosA - dY_raw * sinA;
trackData.Y_raw = y0 + dX_raw * sinA + dY_raw * cosA;

% Adjust heading angles (subtract the initial offset)
trackData.theta = trackData.theta - theta0;

fprintf('Rotated track by %.1f deg so initial heading aligns with East (+X).\n', ...
        rad2deg(-theta0));
fprintf('\n');

%% ========================================================================
%  STAGE 9 — EXPORT CARSIM-READY TABLES
%  ========================================================================

% Create run-specific output folder: output/trackName_YYYY-MM-DD_HH-MM-SS/
runTimestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
runFolder    = sprintf('%s_%s', trackName, runTimestamp);
RUN_DIR      = fullfile(OUTPUT_DIR, runFolder);

if ~exist(RUN_DIR, 'dir')
    mkdir(RUN_DIR);
end
fprintf('Output folder: %s\n\n', RUN_DIR);

% --- Table 1: Road Edges / 3D Coordinates with Station (X, Y, Z, S) ---
% Formato RdEdges CarSim: cabeçalho '0, 1, 2, 3' com colunas X, Y, Z e S (Station)
rdedgesFile = fullfile(RUN_DIR, 'carsim_rdedges.csv');
fid = fopen(rdedgesFile, 'w');
if fid ~= -1
    fprintf(fid, '0, 1, 2, 3\n');
    for i = 1:trackData.nPoints
        fprintf(fid, '%.3f, %.3f, %.3f, %.4f\n', ...
                trackData.X(i), trackData.Y(i), trackData.Z(i), trackData.S(i));
    end
    fclose(fid);
    fprintf('Exported: %s\n', rdedgesFile);
    
    % Salva também cópia com nome rdedges.csv
    try
        copyfile(rdedgesFile, fullfile(RUN_DIR, 'rdedges.csv'));
        fprintf('Exported: %s\n', fullfile(RUN_DIR, 'rdedges.csv'));
    catch
    end
else
    warning('gpx_to_carsim:writeError', 'Could not open %s for writing.', rdedgesFile);
end

% --- Table 2: 3D Coordinates only (X, Y, Z) format ---
% Formato 3 coordenadas: cabeçalho '0, 1, 2' com colunas X, Y e Z
xyzFile = fullfile(RUN_DIR, 'carsim_xyz.csv');
fidXYZ = fopen(xyzFile, 'w');
if fidXYZ ~= -1
    fprintf(fidXYZ, '0, 1, 2\n');
    for i = 1:trackData.nPoints
        fprintf(fidXYZ, '%.3f, %.3f, %.3f\n', ...
                trackData.X(i), trackData.Y(i), trackData.Z(i));
    end
    fclose(fidXYZ);
    fprintf('Exported: %s\n', xyzFile);
else
    warning('gpx_to_carsim:writeError', 'Could not open %s for writing.', xyzFile);
end

% --- Table 3: Station vs Elevation ---
elevFile = fullfile(RUN_DIR, 'elevation.csv');
try
    T_elev = table(trackData.S, trackData.Z, ...
                   'VariableNames', {'S_m', 'Elevation_m'});
    writetable(T_elev, elevFile);
    fprintf('Exported: %s\n', elevFile);
catch ME
    warning('gpx_to_carsim:writeElev', 'Could not write %s: %s', elevFile, ME.message);
end

% --- Table 4: Station vs Grade ---
gradeFile = fullfile(RUN_DIR, 'grade.csv');
try
    T_grade = table(trackData.S, trackData.grade, ...
                    'VariableNames', {'S_m', 'Grade_percent'});
    writetable(T_grade, gradeFile);
    fprintf('Exported: %s\n', gradeFile);
catch ME
    warning('gpx_to_carsim:writeGrade', 'Could not write %s: %s', gradeFile, ME.message);
end

% --- Save full struct as .mat ---
matFile = fullfile(RUN_DIR, 'track_data.mat');
try
    save(matFile, 'trackData', 'lat', 'lon', 'ele');
    fprintf('Exported: %s\n', matFile);
catch ME
    warning('gpx_to_carsim:writeMat', 'Could not save %s: %s', matFile, ME.message);
end

fprintf('\n');

%% ========================================================================
%  STAGE 10 — DIAGNOSTIC PLOTS
%  ========================================================================

plotTrackDiagnostics(trackData);
fig = gcf;
plotFile = fullfile(RUN_DIR, 'track_diagnostics.png');
try
    saveas(fig, plotFile);
    fprintf('Saved plot: %s\n', plotFile);
catch
end

%% ========================================================================
%  SUMMARY TABLE (console)
%  ========================================================================

fprintf('\n');
fprintf('==================================================\n');
fprintf('         GPX -> CarSim  —  SUMMARY                \n');
fprintf('==================================================\n');
fprintf('  Source file                  : %s\n', fileName);
fprintf('  Track points (after cleaning): %d\n', trackData.nPoints);
fprintf('  Total track length           : %.2f m\n', trackData.totalLength);
fprintf('  Smoothing window             : %d pts\n', trackData.smoothWindow);
fprintf('  Elevation gain (max dZ)      : %+.2f m\n', max(trackData.Z));
fprintf('  Elevation drop (min dZ)      : %+.2f m\n', min(trackData.Z));
fprintf('  Max curvature |k|            : %.4f 1/m\n', max(abs(trackData.curvature)));
fprintf('  Min turn radius              : %.2f m\n', ...
        1/max(abs(trackData.curvature(abs(trackData.curvature)>1e-6))));
fprintf('  Grade range                  : [%+.1f, %+.1f] %%\n', ...
        min(trackData.grade), max(trackData.grade));
fprintf('--------------------------------------------------\n');
fprintf('  OUTPUT FOLDER:\n');
fprintf('    %s\n', RUN_DIR);
fprintf('  FILES GENERATED:\n');
fprintf('    • carsim_rdedges.csv    (0, 1, 2, 3 -> X, Y, Z, S for CarSim)\n');
fprintf('    • carsim_xyz.csv        (0, 1, 2    -> X, Y, Z)\n');
fprintf('    • elevation.csv         (S vs Z)\n');
fprintf('    • grade.csv             (S vs Grade%%)\n');
fprintf('    • track_data.mat        (full struct)\n');
fprintf('    • track_diagnostics.png (diagnostic plot)\n');
fprintf('==================================================\n');
fprintf('\n');
fprintf('Next steps in CarSim:\n');
fprintf('  1. Open CarSim -> Road: 3D Surface (X-Y-Z Coordinates of Edges / Reference Line)\n');
fprintf('  2. Import or paste data from carsim_rdedges.csv (or rdedges.csv)\n');
fprintf('     (CarSim will automatically build the path, curvature, and elevation!)\n');
fprintf('  3. Run your simulation!\n');

% Clear gpxFile from base workspace so the next run prompts user again
clear gpxFile;
