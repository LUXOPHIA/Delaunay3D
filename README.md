# Delaunay3D

[English](README.md) | [日本語](ja/README.md)

An interactive 3D Delaunay tetrahedralization / Voronoi diagram demo for Delphi (FireMonkey). Points can be added and deleted at run time, and the Delaunay diagram and its dual Voronoi diagram are re-rendered live as polygonal solids in an FMX 3D scene.

![Delaunay3D](--------/_SCREENSHOT/Delaunay3D.png)

## 利用ライブラリ

* [**LUX**](https://github.com/LUXOPHIA/LUX) ：Base library of vectors, matrices and other core mathematics.
* [**LUX.Delaunay**](https://github.com/LUXOPHIA/LUX.Delaunay) ：Delaunay diagram library supporting dynamic point insertion and deletion.

## 1. Overview

The application itself is a thin FireMonkey form (`TForm1` in `Main.pas`): it owns one `TDelaunay3D` model and one `TDelaunayViewer` frame, and merely forwards mouse and button events. All geometry lives in the [LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) library and all scene construction lives in its viewer frame; the form contains no scene code.

### 1.1 Features

- **Incremental insertion and deletion** — insertion by the Bowyer–Watson method, deletion by star removal with a deterministic refill built from a small Delaunay diagram of the link. The diagram is Delaunay after every operation; on degenerate input `AddPoin` returns `nil` and `DeletePoin` returns `False`, leaving the diagram untouched.
- **Infinite-vertex method** — no super-tetrahedron and no bounding box. The outside of the convex hull is covered by cells sharing a single vertex at infinity, so hull points behave exactly like interior points and every predicate is a single formula with no case analysis.
- **Homogeneous circumcenters** — each tetrahedron exposes its circumcenter as homogeneous coordinates $(X,Y,Z,W)$; hull cells degenerate naturally to $W=0$, yielding the direction of the unbounded Voronoi ray without any branching.
- **Polygonized rendering** — Delaunay edges are drawn as closed polygonal tubes assembled from strips cut out of the tetrahedra faces, Voronoi edges as triangular prisms between circumcenters with cones on the unbounded rays. Flat shading shows the structure as crisp solids.

## 2. Mathematical Background

### 2.1 Delaunay tetrahedralization

Given a finite point set $P \subset \mathbb{R}^3$ in general position, a tetrahedralization of $P$ is *Delaunay* when every tetrahedron satisfies the **empty-circumsphere property**: the open ball bounded by the sphere through its four vertices contains no point of $P$. The dual of the Delaunay diagram is the **Voronoi diagram**, the partition of space into the cells

```math
V(p) \;=\; \{\, x \in \mathbb{R}^3 \;:\; \lVert x-p \rVert \le \lVert x-q \rVert \ \ \forall q \in P \,\},
\qquad \text{(2.1)}
```

whose vertices are the circumcenters of the Delaunay tetrahedra and whose edges connect circumcenters of face-adjacent tetrahedra [1][4].

### 2.2 The lifted in-sphere predicate

All predicates in `TDelaunay3D` reduce to one determinant, evaluated through the classical paraboloid lift [5]. Relative to a query point $q$, every finite vertex $p$ is lifted to

```math
\ell_q(p) \;=\; \bigl(\, p-q,\ \lVert p-q \rVert^2 \,\bigr) \in \mathbb{R}^4 .
\qquad \text{(2.2)}
```

The point $q$ lies inside the circumsphere of a positively oriented tetrahedron $(p_0,p_1,p_2,p_3)$ if and only if

```math
\operatorname{InSphere}(p_0,p_1,p_2,p_3;\,q) \;=\;
\det\begin{pmatrix}
x_0-q_x & y_0-q_y & z_0-q_z & \lVert p_0-q \rVert^2 \\
x_1-q_x & y_1-q_y & z_1-q_z & \lVert p_1-q \rVert^2 \\
x_2-q_x & y_2-q_y & z_2-q_z & \lVert p_2-q \rVert^2 \\
x_3-q_x & y_3-q_y & z_3-q_z & \lVert p_3-q \rVert^2
\end{pmatrix} \;>\; 0 .
\qquad \text{(2.3)}
```

This is `TDelaCell3D.InSphere`; the routine `LiftDet` expands (2.3) by cofactors of the last column. Positions are stored in single precision, but the determinant is always evaluated **in double precision after translating to a nearby base point** — the difference form (2.2) is exactly this translation, so no predicate ever evaluates absolute coordinates (cancellation control in the spirit of robust-predicate practice [6]).

### 2.3 The infinite vertex

Instead of a super-tetrahedron, the model owns a single **vertex at infinity** (`TDelaPoin3DInf`, the `PoinInf` property). Its lift is constant:

```math
\ell_q(\infty) \;=\; (\,0,\ 0,\ 0,\ 1\,).
\qquad \text{(2.4)}
```

Substituting row (2.4) into (2.3) cancels every term containing the spatial part of that row, and the predicate degenerates to the orientation test of the remaining face:

```math
\operatorname{InSphere}(p_0,p_1,p_2,\infty;\,q) \;=\;
-\det\begin{pmatrix} p_0-q \\ p_1-q \\ p_2-q \end{pmatrix},
\qquad \text{(2.5)}
```

i.e. a half-space test against the plane through $p_0,p_1,p_2$. Geometrically this is the statement that a plane is a sphere of infinite radius: in lift space both are hyperplanes, so the same predicate handles finite spheres and planes with **no flag-testing branch** — the infinite vertex merely overrides `Lift` and `InSphered` polymorphically. Each hull face is closed off by an *infinite cell* $(\infty, p_i, p_j, p_k)$, so `Poin[]` never contains `nil`. The first three non-collinear points seed two mirror-image infinite cells covering all of space doubly; from the fourth point on the ordinary insertion procedure applies unchanged.

### 2.4 Homogeneous circumcenters and Voronoi duality

A sphere with center $c$ and radius $r$ lifts to the hyperplane

```math
w \;=\; 2\,c \cdot x \;-\; \bigl(\lVert c \rVert^2 - r^2\bigr)
\qquad \text{(2.6)}
```

in $\mathbb{R}^4$. `TDelaCell3D.Circum` therefore computes the coefficients of the hyperplane through the four lifted vertices — four $4\times 4$ minors — and returns them as the **homogeneous circumcenter** $(C_X, C_Y, C_Z, C_W)$:

- a finite cell yields the circumcenter $(C_X/C_W,\ C_Y/C_W,\ C_Z/C_W)$, a Voronoi vertex;
- an infinite cell degenerates naturally to $C_W = 0$, and $(C_X, C_Y, C_Z)$ is the outward direction of the unbounded Voronoi ray dual to the hull face.

The computation contains neither a branch nor a division, and never forces the lossy center-plus-radius representation. Voronoi edges are dual to Delaunay faces: the viewer connects circumcenters of face-adjacent cells, using (2.6)'s degeneration for the rays.

### 2.5 Incremental insertion (Bowyer–Watson)

`AddPoin` inserts a point $q$ by the two-phase Bowyer–Watson method [2][3] (implemented by the private `InsertPoin`):

1. **Mark** — starting from a cell whose circumsphere contains $q$, flood outward across faces, collecting the *cavity*: all cells with $\operatorname{InSphere} > 0$. Marking with a flag is idempotent, so even in 3D — where the cavity's dual graph need not be a tree — reaching a cell along several paths causes no double processing.
2. **Cave** — for every boundary face of the cavity, create a new cell joining the face to $q$, weld it to the outer cell (the rotation code of `Weld` is derived from vertex identity), weld the new cells to each other around $q$, and only then free the cavity cells — re-entry into freed cells is structurally impossible.

The cell containing $q$ in its circumsphere is located by **jump-and-walk** [7]: sample $\lceil n^{1/4} \rceil$ random points, start from the anchor cell of the nearest sample, and repeatedly step across any face that has $q$ on its outer side — the face test being exactly the degenerate predicate (2.5), $\operatorname{InSphere}(A,B,C,\infty;\,q)$. The expected cost is $O(n^{1/4})$; outside the hull the walk enters an infinite cell and stops. Degenerate inputs (duplicates, first three points collinear, points on the extension of an existing edge) make `AddPoin` return `nil` without modifying the diagram.

### 2.6 Deletion by star removal and refill

`DeletePoin` removes a vertex $v$ by **star removal with refill** (implemented by the private `RemovePoin`):

1. Collect the *star* of $v$ (all cells containing $v$) via `CollectStar`; removing it opens a star-shaped hole whose boundary is the *link* of $v$.
2. Build a small Delaunay diagram of the link vertices only — by the same incremental insertion, as an independent component inside the same cell set (no nested `TDelaunay3D` is created).
3. Cut out of it the cells that fill the hole: for each boundary face, the cell that can be welded onto the outer side with mirror orientation (`CanWeld`), then the cells reachable from those without crossing a seam (`FloodFills` verifies the closure's boundary coincides exactly with the hole's boundary).
4. Weld the filler onto the hole rim, free the star and the unused filler cells.

Both the cut-out and the stitching are settled by purely combinatorial checks — no flip search is involved. A star of two mirror cells is handled directly by welding the two outer hooks together. In any degenerate configuration that fails a check, `DeletePoin` returns `False` and the original diagram is left completely intact (this is the classical deletion problem studied in [8]).

### 2.7 Nearest-neighbor search

`FindNearPoin` starts from the jump-and-walk landing cell: the vertices of the cell whose circumsphere contains $q$ are close to $q$, so from the nearest of them the search descends along Delaunay edges to strictly closer neighbors. Since the distance decreases strictly at every step, the descent necessarily terminates at the point whose Voronoi cell (2.1) contains $q$ — the nearest neighbor — in expected $O(n^{1/4})$ location plus $O(1)$ descent steps. The demo uses the viewer's screen-space variant `FindPoin` to pick the point to delete under the mouse.

## 3. Architecture

### 3.1 Class diagram

```
[Ownership]
・TForm1 (Main.pas)                      ･･･ application: event forwarding only
  ┣・TDelaunay3D                        ･･･ diagram model (LUX.Delaunay.D3)
  ┃  ┣・PoinInf :TDelaPoin3DInf        ･･･ single vertex at infinity
  ┃  ┣・Poins :TDelaPoinSet3D
  ┃  ┃  ┗・TDelaPoin3D                ･･･ finite vertex (Lift, InSphered)
  ┃  ┗・Cells :TDelaCellSet3D
  ┃     ┗・TDelaCell3D                 ･･･ tetrahedron (InSphere, Circum)
  ┗・Viewer1 :TDelaunayViewer (frame)   ･･･ rendering (LUX.Delaunay.D3.Viewer)
     ┣・TDelaunayViewport (TViewport3D) ･･･ orbit rig Yaw→Pitch→TCamera
     ┣・TDelaunayEdges (TControl3D)     ･･･ Delaunay edges → polygonal tubes
     ┗・TDelaunayVoros (TControl3D)     ･･･ Voronoi edges → prisms and cones

[Inheritance: TetraFlip mesh layer (LUX) → Delaunay classes]
・TTetraPoin3D
  ┗・TDelaPoin3D

・TTetraCell3D                           ･･･ connectivity (Weld, VertTable, …)
  ┗・TDelaCell3D

・TTetraCellSet3D
  ┗・TDelaCellSet3D
```

The model notifies the viewer through the multicast `OnChange`; the viewer rebuilds its two vertex-buffer layers at most once per frame, at the start of the viewport's `Paint`.

### 3.2 File layout

```
・Delaunay3D.dpr / Main.pas / Main.fmx       ･･･ thin form; no scene code
・_LIBRARY\LUXOPHIA\                         ･･･ git-subtree library copies
  ┣・LUX.Delaunay\                          ･･･ LUX.Delaunay repository
  ┃  ┣・D3\LUX.Delaunay.D3.pas             ･･･ 3D diagram (TDelaunay3D)
  ┃  ┗・D3\LUX.Delaunay.D3.Viewer.pas/.fmx ･･･ TDelaunayViewer frame
  ┗・LUX\                                   ･･･ base library repository
     ┣・Data\Model\TetraFlip\               ･･･ tetrahedral mesh layer
     ┗・LUX.pas / LUX.D3.pas / LUX.D4.pas   ･･･ vectors, delegates, utilities
```

## 4. Usage

### 4.1 Controls

| Input | Action |
|---|---|
| Left drag | Orbit the camera |
| Mouse wheel | Zoom (dolly) |
| Click on a point | Delete that point |
| `Add x10` | Add 10 normally distributed random points |
| `Del x10` | Delete up to 10 randomly chosen points |
| `Clear` | Remove all points |

### 4.2 API sketch

The entire application logic is a few calls into the library:

```pascal
_Delaunay := TDelaunay3D.Create;
Viewer1.Delaunay := _Delaunay;              // subscribe the viewer

_Delaunay.AddPoin( 2 * TSingle3D.RandG );   // insert (nil on degenerate input)
_Delaunay.DeletePoin( V );                  // delete (False on degenerate input)
_Delaunay.Clear;

Viewer1.Orbit( DYaw, DPitch );              // camera
Viewer1.Dolly( DDistance );
V := Viewer1.FindPoin( ScreenPos, 16 );     // point within 16 px of the cursor
```

## 5. Building

1. Open `Delaunay3D.dproj` in RAD Studio (Delphi, FireMonkey).
2. Select the `Win32` or `Win64` target and run.

The viewer uses the standard FMX `TViewport3D`; no additional packages, DLLs, or third-party components are required. All library code is vendored under `_LIBRARY\` as git subtrees, so the project builds as checked out.

## 6. References

1. B. Delaunay, *Sur la sphère vide*, Bulletin de l'Académie des Sciences de l'URSS, Classe des sciences mathématiques et naturelles, 1934.
2. A. Bowyer, [*Computing Dirichlet tessellations*](https://doi.org/10.1093/comjnl/24.2.162), The Computer Journal, 24(2), 1981.
3. D. F. Watson, [*Computing the n-dimensional Delaunay tessellation with application to Voronoi polytopes*](https://doi.org/10.1093/comjnl/24.2.167), The Computer Journal, 24(2), 1981.
4. F. Aurenhammer, *Voronoi diagrams — a survey of a fundamental geometric data structure*, ACM Computing Surveys, 23(3), 1991.
5. K. Q. Brown, *Voronoi diagrams from convex hulls*, Information Processing Letters, 9(5), 1979.
6. J. R. Shewchuk, [*Adaptive Precision Floating-Point Arithmetic and Fast Robust Geometric Predicates*](https://www.cs.cmu.edu/~quake/robust.html), Discrete & Computational Geometry, 18, 1997.
7. E. P. Mücke, I. Saias, B. Zhu, *Fast randomized point location without preprocessing in two- and three-dimensional Delaunay triangulations*, Computational Geometry: Theory and Applications, 12, 1999.
8. O. Devillers, *On deletion in Delaunay triangulations*, International Journal of Computational Geometry & Applications, 12(3), 2002.

## 💖 [Embarcadero](https://www.embarcadero.com/) [**Delphi**](https://www.embarcadero.com/products/delphi)
Integrated Development Environment (IDE) for Creating Native Cross-Platform Apps.
### Free Download: [**Delphi** Community Edition](https://www.embarcadero.com/products/delphi/starter)
