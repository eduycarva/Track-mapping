function [lat, lon, ele] = parseGPX(gpxFile)
% PARSEGPX  Read a .gpx file and extract track point coordinates.
%
%   [lat, lon, ele] = parseGPX(gpxFile)
%
%   Inputs:
%       gpxFile - Path (string or char) to the .gpx file.
%
%   Outputs:
%       lat - Column vector of latitudes  [deg] (N x 1)
%       lon - Column vector of longitudes [deg] (N x 1)
%       ele - Column vector of elevations [m]   (N x 1)
%
%   The function reads all <trkpt> elements from every <trkseg> block
%   inside every <trk>, concatenating them in document order.
%   If a track point has no <ele> child, its elevation defaults to 0.
%
%   Example:
%       [lat, lon, ele] = parseGPX('track.gpx');
%
%   See also: xmlread, gpx_to_carsim

% -------------------------------------------------------------------------
%  GPX-to-CarSim Track Builder  |  FSAE eesc-usp Tupã  |  Performance
% -------------------------------------------------------------------------

    %% Validate input
    if nargin < 1 || isempty(gpxFile)
        error('parseGPX:noInput', 'You must provide a path to a .gpx file.');
    end
    if ~isfile(gpxFile)
        error('parseGPX:fileNotFound', 'File not found: %s', gpxFile);
    end

    %% Parse the XML document
    xDoc = xmlread(gpxFile);

    %% Collect all <trkpt> elements (works across multiple trk / trkseg)
    trkpts = xDoc.getElementsByTagName('trkpt');
    nPts   = trkpts.getLength();

    if nPts == 0
        error('parseGPX:noTrackPoints', ...
              'No <trkpt> elements found in the GPX file.');
    end

    %% Pre-allocate
    lat = zeros(nPts, 1);
    lon = zeros(nPts, 1);
    ele = zeros(nPts, 1);

    %% Extract coordinates
    for i = 0 : nPts - 1
        node = trkpts.item(i);

        % lat and lon are XML attributes of <trkpt>
        lat(i+1) = str2double(char(node.getAttribute('lat')));
        lon(i+1) = str2double(char(node.getAttribute('lon')));

        % <ele> is a child element (may be absent)
        eleNodes = node.getElementsByTagName('ele');
        if eleNodes.getLength() > 0
            ele(i+1) = str2double(char( ...
                eleNodes.item(0).getTextContent()));
        else
            ele(i+1) = 0;   % default if elevation missing
        end
    end

    %% Summary to command window
    fprintf('parseGPX: loaded %d track points from "%s"\n', nPts, gpxFile);
    fprintf('  Lat  range: [%.6f, %.6f] deg\n', min(lat), max(lat));
    fprintf('  Lon  range: [%.6f, %.6f] deg\n', min(lon), max(lon));
    fprintf('  Ele  range: [%.2f, %.2f] m\n',   min(ele), max(ele));
end
