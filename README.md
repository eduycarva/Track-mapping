# GPX → CarSim Track Builder

**MATLAB tool to convert GPS files (.gpx) into 3D track data compatible with CarSim.**
<img width="2188" height="1275" alt="track_diagnostics" src="https://github.com/user-attachments/assets/a52f414c-a355-4b12-a97e-56b7bf38afbe" />

Developed by the **Performance Subsystem** of the FSAE team **EESC-USP Tupã**.

---

## About

This project solves a recurring challenge for the team: the lack of an accurate, scientific, and reproducible method to map real tracks and import them into the vehicle dynamics software **CarSim**. Previously, corner geometry was estimated visually (using MS Paint and empirical methods) — now, the process is 100% automated from GPS coordinates.

The software takes a `.gpx` file (standard GPS Exchange Format), processes the geodetic coordinates (latitude, longitude, altitude), adjusts the track layout to CarSim's native coordinate system, and creates a dedicated folder inside `output/` (formatted as `<track_name>_<YYYY-MM-DD_HH-MM-SS>/`) containing:

| Output File | Contents | CarSim Destination |
|---|---|---|
| `rdedges.csv` | $X$ (m), $Y$ (m), $Z$ (m), Station (m) [Header `0, 1, 2, 3`] | Road → 3D Surface / X-Y-Z Coordinates of Edges / Reference Line |
| `carsim_xyz.csv` | $X$ (m), $Y$ (m), $Z$ (m) [Header `0, 1, 2`] | Road → X-Y-Z Coordinates (3 coordinates) |
| `elevation.csv` | Station (m) × Elevation (m) | Road → Elevation (reference / validation) |
| `grade.csv` | Station (m) × Grade (%) | Road → Elevation (alternative) |
| `track_data.mat` | Complete MATLAB struct | Offline analysis / telemetry / scripts |
| `track_diagnostics.png` | Image with 6 diagnostic plots | Visual record and technical validation |

> **Note on 3D Coordinates and Curvature:** CarSim natively supports direct import of 3D spatial coordinates through the screen **Road: 3D Surface (X-Y-Z Coordinates of Edges / Reference Line)** using the `rdedges.csv` format (header `0, 1, 2, 3`). CarSim automatically computes horizontal curvature, tangential heading, and elevation in a continuous and unified manner, eliminating the need for standalone curvature tables and preventing numerical discrepancies between axes.

---

## Reference Frame and Automatic Orientation for CarSim

In CarSim, the vehicle is initialized by default at the origin $(X = 0, Y = 0, Z = 0)$ facing the positive $X$-axis direction (East, heading $0^\circ$), delimited by the dashed reference grid lines.

If the track were imported using raw local geographic coordinates and the start/finish straight pointed North, West, or diagonally, the car would initialize off-track or facing sideways/backwards relative to the CarSim grid lines.

To ensure immediate, out-of-the-box compatibility without manual adjustments:
1. **Origin at $(0, 0, 0)$:** The first point of the track is translated exactly to the origin $(X_1 = 0, Y_1 = 0, Z_1 = 0)$.
2. **Automatic Rotation ($-\theta_0$):** All horizontal coordinates are rotated relative to the origin by the initial heading angle $-\theta_0$, strictly aligning the initial straight-line vector with the $+X$ axis (East).
3. **Geometric Invariance:** Accumulated distance (Station $S$), elevation profile, grade, and curvature $\kappa$ are invariant under rigid body translation and rotation, preserving the exact physics of the original track layout.

---

## How to Use

### 1. Obtain the Track GPX File

Draw the track layout by clicking points along the path and export it as `.gpx`.

> **Recommendation:** We strongly recommend using **[plotaroute.com](https://www.plotaroute.com/)** (*Create a Route* tool). It is significantly easier and more intuitive for Formula SAE layouts (parking lots, karting tracks, and test pads) than alternatives like *gpx.studio*, as it features a freehand drawing mode (*Straight / Freehand*) without forcing the route to snap to public roads. When finished, download the file in **.gpx** format with elevation enabled.

### 2. Run in MATLAB

In the MATLAB command window, run:

```matlab
gpx_to_carsim
```

A file picker dialog will open. Select the `.gpx` file, and the script will execute the complete processing pipeline automatically.

### 3. Import into CarSim (Notepad Method)

To ensure CarSim parses the columns without formatting conflicts or decimal separator issues:

1. Open the generated folder in `output/<track_name>_<date_time>/`.
2. Open the **`rdedges.csv`** file using **Notepad** (or any plain text editor).
3. Press `Ctrl + A` to select all text and `Ctrl + C` to copy.
4. In CarSim, navigate to the road screen: **Road: 3D Surface (X-Y-Z Coordinates of Edges)** or **Road: Centerline & Edges (X-Y-Z Coordinates)**.
5. Click on the coordinate table and paste with `Ctrl + V`. CarSim will automatically populate the $X$, $Y$, $Z$, and $S$ columns matching the `0, 1, 2, 3` header.
6. Set the track width (*width*, typically 3 meters for FSAE) and friction coefficient ($\mu$).

> **Why use Notepad?** Spreadsheet software like Microsoft Excel frequently converts decimal dots (`.`) to commas (`,`) depending on the Windows system locale, corrupting the CarSim import. Notepad preserves the pure, clean ASCII formatting of the file.

---

## What the Software Computes

1. **Geodetic Conversion** — Converts (latitude, longitude, altitude) to local Cartesian coordinates ($X, Y, Z$) in meters using the flat-Earth approximation.

2. **Closed-Circuit Detection and Closure** — Detects closed tracks and joins end-points smoothly, applying periodic boundary conditions during smoothing.

3. **CarSim Alignment** — Translates the starting point to $(0, 0, 0)$ and rotates the track so it begins pointing towards $+X$ (East).

4. **Station $S$** — Cumulative distance along the track centerline (CarSim's fundamental independent variable).

5. **Track Edges (RdEdges $X, Y, Z, S$)** — Formatted precisely with header `0, 1, 2, 3` in `rdedges.csv` for immediate 3D surface generation in CarSim.

6. **Curvature $\kappa(S)$ and Heading Angle** — Computed analytically for diagnostic plotting and technical validation:

$$\kappa = \frac{X' \cdot Y'' - Y' \cdot X''}{(X'^2 + Y'^2)^{3/2}}$$

   - $\kappa > 0 \rightarrow$ left turn
   - $\kappa < 0 \rightarrow$ right turn

7. **Longitudinal Slope (*Grade*)** — Slope in %, obtained from the derivative of elevation with respect to Station.

8. **Smoothing Filter** — Moving average applied to spatial coordinates to attenuate characteristic GPS noise prior to computing derivatives.

---

## Project Structure

```
pistas/
├── gpx_to_carsim.m            % Main script — run this
├── parseGPX.m                 % XML parser for .gpx files
├── geo2local.m                % Geodetic → local Cartesian conversion
├── computeTrackGeometry.m     % Calculation engine (Station, closure, curvature, grade)
├── plotTrackDiagnostics.m     % Generation of the 6 diagnostic plots
├── guia_software_pistas.tex   % Complete documentation in LaTeX
├── Track_mapping___GUIDE.pdf  % Compiled PDF manual
└── output/                    % Generated automatically
    └── <track>_<timestamp>/   % Dedicated folder per execution
        ├── rdedges.csv        % 3D Table + Station for CarSim (0, 1, 2, 3)
        ├── carsim_xyz.csv     % 3D Coordinates (0, 1, 2)
        ├── elevation.csv      % Station vs Elevation
        ├── grade.csv          % Station vs Grade (%)
        ├── track_data.mat     % Complete MATLAB struct
        └── track_diagnostics.png % Diagnostic plots image
```

---

## Configuration

The only user-tunable parameter is located at the top of `gpx_to_carsim.m`:

```matlab
SMOOTH_WINDOW = 5;  % Moving average window size (in points)
```

| Value | Effect |
|---|---|
| 3 | Preserves very tight turns (*hairpins*), but is more sensitive to noise |
| **5** | **Recommended default balance** |
| 7+ | Very smooth curves, may round off sharp corners |

---

## Diagnostic Plots

The script automatically generates a figure with 6 subplots (saved as `track_diagnostics.png` in the track output folder):

| Panel | Description |
|---|---|
| **XY Map** | Top-down view showing raw vs smoothed trajectory and alignment with CarSim frame |
| **3D View** | Track in 3D space with color gradient by elevation |
| **Curvature vs Station** | Curvature profile $\kappa$ with corner radius $R$ on secondary axis |
| **Elevation vs Station** | Longitudinal elevation profile and altitude variation $\Delta Z$ |
| **Grade vs Station** | Longitudinal slope (%) along the course |
| **Heading vs Station** | Heading direction angle of the trajectory (in degrees, starting at $0^\circ$) |

---

## Requirements

- **MATLAB** R2020b or higher (no paid toolboxes required)
- **CarSim** (for vehicle simulation on the track)
- Web browser (to access [plotaroute.com](https://www.plotaroute.com/) or [gpx.studio](https://gpx.studio/))

---

## Full Documentation

The detailed manual with mathematical formulations, equations, reference frame alignment, and import guide is available in:

* Compiled PDF document: [`Track_mapping___GUIDE.pdf`](Track_mapping___GUIDE.pdf)

---

## Author

**Eduardo Yumoto Carvalheira** — Performance Manager

FSAE Team EESC-USP Tupã | São Carlos, SP, Brazil
