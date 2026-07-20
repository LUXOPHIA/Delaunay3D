# Delaunay3D

**Interactive 3D Delaunay / Voronoi diagram demo for Delphi (FireMonkey).**

[English](README.md) | [日本語](ja/README.md)

Add and remove points and watch the Delaunay tetrahedralization and the Voronoi diagram update live, rendered as polygonal solids in an FMX 3D scene. Built on the [LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) library:

- Incremental **insertion** (Bowyer–Watson) and **deletion** (flip-based) — the diagram stays Delaunay after every operation.
- **Infinite-vertex method** — no super-tetrahedron, no bounding box; hull points behave like interior points.
- **Polygonized edges** — Delaunay edges are polygonal tubes assembled from the frames of the tetrahedra faces, Voronoi edges are triangular prisms between circumcenters with cones on the unbounded rays. Flat shading shows the structure as crisp solids.
- Rendering by the library's `TDelaunayViewer` frame; the application itself contains no scene code.

## Controls

| Input | Action |
|---|---|
| Left drag | Orbit the camera |
| Mouse wheel | Zoom |
| Click on a point | Delete it |
| `Add x10` | Add 10 random points |
| `Del x10` | Delete 10 random points |
| `Clear` | Remove all points |

## Structure

```
Delaunay3D.dpr / Main.pas / Main.fmx    … the application (a thin form; no scene code)
_LIBRARY\LUXOPHIA\
  LUX.Delaunay\                         … Delaunay library (git subtree)
    D3\LUX.Delaunay.D3.pas              …   3D diagram (TDelaunay3D)
    D3\LUX.Delaunay.D3.Viewer.pas/.fmx  …   3D viewer frame (TDelaunayViewer)
  LUX\                                  … base library (git subtree)
    Data\Model\TetraFlip\               …   flip-based tetrahedral mesh
```

## Building

Open `Delaunay3D.dproj` in RAD Studio and run (Win32 / Win64). The viewer uses the standard FMX `TViewport3D` — no additional packages are required.

## Library documentation

The class reference and API usage are documented in the library:
[LUX.Delaunay/D3](https://github.com/LUXOPHIA/LUX.Delaunay/tree/main/D3)
