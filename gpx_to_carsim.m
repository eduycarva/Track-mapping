%% GPX_TO_CARSIM  —  Convert a .gpx track file into CarSim road data.
%
%  Main script that orchestrates the full pipeline:
%    1. Parse .gpx file  →  lat, lon, ele
%    2. Convert to local Cartesian  →  X, Y, Z  [meters]
%    3. Clean, smooth, and compute track geometry
%    4. Export CarSim-ready tables (S vs curvature, elevation, grade)
%    5. Generate diagnostic plots
%
%  USAGE:
%    Run this script. A file browser will open for you to select a .gpx file.
%    Alternatively, set the variable 'gpxFile' below to a fixed path.
%
%  OUTPUTS (saved to ./output/):
%    carsim_curvature.csv  — Station [m] vs Curvature [1/m]
%    carsim_elevation.csv  — Station [m] vs Elevation [m]
%    carsim_grade.csv      — Station [m] vs Grade [%]
%    track_data.mat        — Full trackData struct for later use
%
%  After running, copy the CSV table contents into CarSim:
%    • Curvature  → Road: Path (VS Reference Path) → curvature vs S table
%    • Elevation  → Road: Elevation → Z vs S table
%    • Grade      → Road: Elevation → Grade vs S table (alternative)
%
%  See also: parseGPX, geo2local, computeTrackGeometry, plotTrackDiagnostics

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE eesc-usp Tupã  |  Performance
% -------------------------------------------------------------------------

clear; clc; close all;

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

% File selection dialog
[fileName, filePath] = uigetfile({'*.gpx', 'GPX Files (*.gpx)'}, ...
                                  'Select a GPX track file');
if isequal(fileName, 0)
    error('gpx_to_carsim:cancelled', 'No file selected. Aborting.');
end
gpxFile = fullfile(filePath, fileName);
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
%  STAGE 8 — EXPORT CARSIM-READY TABLES
%  ========================================================================

% Create output directory if it doesn't exist
if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
    fprintf('Created output directory: %s\n', OUTPUT_DIR);
end

% --- Table 1: Station vs Curvature ---
T_curv = table(trackData.S, trackData.curvature, ...
               'VariableNames', {'S_m', 'Curvature_1_per_m'});
curvFile = fullfile(OUTPUT_DIR, 'carsim_curvature.csv');
writetable(T_curv, curvFile);
fprintf('Exported: %s\n', curvFile);

% --- Table 2: Station vs Elevation ---
T_elev = table(trackData.S, trackData.Z, ...
               'VariableNames', {'S_m', 'Elevation_m'});
elevFile = fullfile(OUTPUT_DIR, 'carsim_elevation.csv');
writetable(T_elev, elevFile);
fprintf('Exported: %s\n', elevFile);

% --- Table 3: Station vs Grade ---
T_grade = table(trackData.S, trackData.grade, ...
                'VariableNames', {'S_m', 'Grade_percent'});
gradeFile = fullfile(OUTPUT_DIR, 'carsim_grade.csv');
writetable(T_grade, gradeFile);
fprintf('Exported: %s\n', gradeFile);

% --- Save full struct as .mat ---
matFile = fullfile(OUTPUT_DIR, 'track_data.mat');
save(matFile, 'trackData', 'lat', 'lon', 'ele');
fprintf('Exported: %s\n', matFile);

fprintf('\n');

%% ========================================================================
%  STAGE 9 — DIAGNOSTIC PLOTS
%  ========================================================================

plotTrackDiagnostics(trackData);

%% ========================================================================
%  SUMMARY TABLE (console)
%  ========================================================================

fprintf('\n');
fprintf('╔══════════════════════════════════════════════╗\n');
fprintf('║         GPX → CarSim  —  SUMMARY            ║\n');
fprintf('╠══════════════════════════════════════════════╣\n');
fprintf('║  Track points (after cleaning) : %4d        ║\n', trackData.nPoints);
fprintf('║  Total track length            : %7.2f m   ║\n', trackData.totalLength);
fprintf('║  Smoothing window              : %4d pts    ║\n', trackData.smoothWindow);
fprintf('║  Elevation gain (max ΔZ)       : %+7.2f m   ║\n', max(trackData.Z));
fprintf('║  Elevation drop (min ΔZ)       : %+7.2f m   ║\n', min(trackData.Z));
fprintf('║  Max curvature |κ|             : %.4f 1/m  ║\n', max(abs(trackData.curvature)));
fprintf('║  Min turn radius               : %7.2f m   ║\n', ...
        1/max(abs(trackData.curvature(abs(trackData.curvature)>1e-6))));
fprintf('║  Grade range                   : [%+.1f, %+.1f] %%  ║\n', ...
        min(trackData.grade), max(trackData.grade));
fprintf('╠══════════════════════════════════════════════╣\n');
fprintf('║  OUTPUT FILES:                               ║\n');
fprintf('║   • carsim_curvature.csv  (S vs κ)          ║\n');
fprintf('║   • carsim_elevation.csv  (S vs Z)          ║\n');
fprintf('║   • carsim_grade.csv      (S vs Grade%%)     ║\n');
fprintf('║   • track_data.mat        (full struct)      ║\n');
fprintf('╚══════════════════════════════════════════════╝\n');
fprintf('\n');
fprintf('Next steps:\n');
fprintf('  1. Open CarSim → Road: Path definition\n');
fprintf('  2. Paste curvature data from carsim_curvature.csv\n');
fprintf('  3. Go to Road: Elevation and paste from carsim_elevation.csv\n');
fprintf('  4. Run your simulation!\n');
