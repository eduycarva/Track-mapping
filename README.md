# 🏎️ GPX → CarSim Track Builder

**MATLAB tool for converting GPS track files (.gpx) into CarSim-compatible road data.**

Developed by the **Performance Subsystem** of the FSAE team **EESC-USP Tupã**.

---

## 📋 About

This project solves a recurring problem in the team: the lack of a precise and reproducible method for mapping real tracks and importing them into the vehicle dynamics simulation software **CarSim**. Previously, curve geometry was estimated visually — now the process is fully automated from GPS coordinates.

The software takes a `.gpx` file (GPS Exchange Format standard), processes the geodetic coordinates (latitude, longitude, altitude), and creates a dedicated folder inside `output/` (named `<track_name>_<YYYY-MM-DD_HH-MM-SS>/`) containing:

| Output file | Contents | CarSim destination |
|---|---|---|
| `curvature.csv` | Station (m) × Curvature (1/m) | Road → Path (VS Reference Path) |
| `elevation.csv` | Station (m) × Elevation (m) | Road → Elevation |
| `grade.csv` | Station (m) × Grade (%) | Road → Elevation (alternative) |
| `track_data.mat` | Complete MATLAB struct | Offline analysis / scripts |
| `track_diagnostics.png` | 6-panel diagnostic plot | Visual inspection and record |

---

## 🚀 How to use

### 1. Obtain the GPX file

Draw the track layout by clicking points along the path and export as `.gpx`. 

> **Recommendation:** We recommend using **[plotaroute.com](https://www.plotaroute.com/)** (Plot a Route), which is much easier and more intuitive for racing tracks, parking lots, and skidpads than alternatives like [gpx.studio](https://gpx.studio/), allowing easy freehand drawing and point placement. Make sure to download/export the route in **.gpx** format (including elevation).

### 2. Run in MATLAB

```matlab
gpx_to_carsim
```

A file selection dialog will open. Select the `.gpx` file and the script will run the entire pipeline automatically.

### 3. Import into CarSim

Copy the data from the CSVs generated in the `output/` folder into the **Road → Path** (curvature) and **Road → Elevation** (elevation) screens in CarSim.

---

## 📐 What the software computes

1. **Geodetic conversion** — Converts (lat, lon, ele) to local Cartesian coordinates (X, Y, Z) in meters using a flat-Earth approximation.

2. **Station S** — Cumulative distance along the track centerline (CarSim's primary independent variable).

3. **Curvature κ(S)** — Computed using the parametric curvature formula:

$$\kappa = \frac{X' \cdot Y'' - Y' \cdot X''}{(X'^2 + Y'^2)^{3/2}}$$

   - κ > 0 → turning left
   - κ < 0 → turning right

4. **Grade (S)** — Longitudinal slope in %, computed from elevation changes.

5. **Smoothing** — Moving average filter to reduce inherent GPS noise before computing derivatives.

---

## 📁 Project structure

```
performance/
├── gpx_to_carsim.m            # Main script — run this
├── parseGPX.m                 # XML parser for .gpx files
├── geo2local.m                # Geodetic → local Cartesian conversion
├── computeTrackGeometry.m     # Station, curvature, and grade calculations
├── plotTrackDiagnostics.m     # Diagnostic plot generation (6 panels)
├── guia_software_pistas.tex   # Full documentation (LaTeX, in Portuguese)
└── output/                    # Generated automatically
    └── <track>_<timestamp>/   # Dedicated folder per run (e.g., endurance_2026-09-16_22-30-00)
        ├── curvature.csv
        ├── elevation.csv
        ├── grade.csv
        ├── track_data.mat
        └── track_diagnostics.png
```

---

## ⚙️ Configuration

The only user-adjustable parameter is at the top of `gpx_to_carsim.m`:

```matlab
SMOOTH_WINDOW = 5;  % Moving average window size (in points)
```

| Value | Effect |
|-------|--------|
| 3 | Preserves tight corners (hairpins), but noisier output |
| **5** | **Recommended balance** |
| 7+ | Very smooth curves, may flatten hairpins |

---

## 📊 Diagnostic plots

The script automatically generates a figure with 6 panels for visual validation:

| Panel | What it shows |
|-------|---------------|
| XY Track Map | Top-down view with raw vs smoothed trajectory |
| 3D View | Track in 3D, colored by elevation |
| Curvature vs Station | Curvature profile with turn radius on secondary axis |
| Elevation vs Station | Longitudinal elevation profile |
| Grade vs Station | Slope (%) along the track |
| Heading vs Station | Direction angle along the trajectory |

---

## 📝 Requirements

- **MATLAB** R2020b or later (no additional toolboxes required)
- **CarSim** (for importing the processed data)
- Web browser (to access [plotaroute.com](https://www.plotaroute.com/) or [gpx.studio](https://gpx.studio/))

---

## 📖 Documentation

Full documentation with theoretical background, equations, step-by-step instructions, and a troubleshooting guide is available in the LaTeX file (written in Portuguese):

📄 [`guia_software_pistas.tex`](guia_software_pistas.tex)

---

## 👤 Author

**Eduardo Yumoto Carvalheira** — Performance Manager

FSAE Team EESC-USP Tupã | São Carlos, SP, Brazil
