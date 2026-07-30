# Delaunay3D

[English](../README.md) | [日本語](README.md)

Delphi（FireMonkey）による対話的な 3D ドロネー四面体分割／ボロノイ図のデモです。実行中に点を追加・削除でき、ドロネー図とその双対であるボロノイ図が FMX 3D シーンの中でポリゴンの立体としてリアルタイムに再描画されます。

![Delaunay3D](../--------/_SCREENSHOT/Delaunay3D.png)

## 利用ライブラリ

* [**LUX**](https://github.com/LUXOPHIA/LUX) ：ベクトル・行列などの基盤数学ライブラリ。
* [**LUX.Delaunay**](https://github.com/LUXOPHIA/LUX.Delaunay) ：動的な点の追加・削除に対応するドロネー図ライブラリ。

## 1. 概要

アプリケーション本体は薄い FireMonkey フォーム（`Main.pas` の `TForm1`）で、1つの `TDelaunay3D` モデルと1つの `TDelaunayViewer` フレームを保持し、マウスとボタンのイベントを転送するだけです。幾何はすべて [LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) ライブラリに、シーン構築はすべてそのビューアフレームに閉じており、フォームはシーン生成コードを持ちません。

### 1.1 特徴

- **逐次的な追加と削除** — 追加は Bowyer–Watson 法、削除は「星の除去」と、リンクの小さなドロネー図から作る決定論的な埋め戻し。どの操作の後も図は常にドロネーであり、退化した入力には `AddPoin` が `nil` を、`DeletePoin` が `False` を返して図を一切変えません。
- **無限遠頂点方式** — スーパーテトラもバウンディングボックスも不要。凸包の外側は、唯一の無限遠頂点を共有する胞で覆われるため、凸包上の点も内部の点とまったく同じに扱え、すべての述語が場合分けのない単一の式になります。
- **同次外心** — 各四面体は外心を同次座標 $(X,Y,Z,W)$ として公開します。無限遠胞は自然に $W=0$ へ退化し、分岐なしに非有界なボロノイ半直線の方向を与えます。
- **ポリゴン化された描画** — ドロネー辺は四面体の面から切り出した帯を張り合わせた閉じた多角形の管として、ボロノイ辺は外心どうしを結ぶ三角柱（非有界な半直線は錐）として描かれます。フラットシェーディングが構造を鋭い立体として見せます。

## 2. 数学的背景

### 2.1 ドロネー四面体分割

一般の位置にある有限点集合 $P \subset \mathbb{R}^3$ に対し、$P$ の四面体分割が**ドロネー**であるとは、すべての四面体が**空球条件**を満たすことをいいます。すなわち、4頂点を通る球が囲む開球の内部に $P$ の点が存在しないことです。ドロネー図の双対が**ボロノイ図**、つまり空間の胞

```math
V(p) \;=\; \{\, x \in \mathbb{R}^3 \;:\; \lVert x-p \rVert \le \lVert x-q \rVert \ \ \forall q \in P \,\}
\qquad \text{(2.1)}
```

への分割であり、その頂点はドロネー四面体の外心、辺は面で隣接する四面体の外心どうしを結びます [1][4]。

### 2.2 リフトによる空球判定

`TDelaunay3D` のすべての述語は、古典的な放物面リフト [5] を通じて1つの行列式に帰着します。判定点 $q$ を基準に、各有限頂点 $p$ を

```math
\ell_q(p) \;=\; \bigl(\, p-q,\ \lVert p-q \rVert^2 \,\bigr) \in \mathbb{R}^4
\qquad \text{(2.2)}
```

へリフトします。点 $q$ が正の向きの四面体 $(p_0,p_1,p_2,p_3)$ の外接球の内側にあることは、次と同値です。

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

これが `TDelaCell3D.InSphere` であり、`LiftDet` は (2.3) を最終列の余因子展開で評価します。座標は単精度で保持されますが、行列式は必ず**近傍の基準点へ平行移動してから倍精度で**評価されます — 差分形 (2.2) がまさにこの平行移動であり、絶対座標のまま評価する述語は存在しません（頑健な述語の実践 [6] に通じる桁落ち対策です）。

### 2.3 無限遠頂点

スーパーテトラの代わりに、モデルは唯一の**無限遠頂点**（`TDelaPoin3DInf`、プロパティ `PoinInf`）を持ちます。そのリフトは定数です。

```math
\ell_q(\infty) \;=\; (\,0,\ 0,\ 0,\ 1\,).
\qquad \text{(2.4)}
```

行 (2.4) を (2.3) に代入すると、その行の空間成分を含む項がすべて消え、述語は残る面の向き判定へ退化します。

```math
\operatorname{InSphere}(p_0,p_1,p_2,\infty;\,q) \;=\;
-\det\begin{pmatrix} p_0-q \\ p_1-q \\ p_2-q \end{pmatrix},
\qquad \text{(2.5)}
```

すなわち $p_0,p_1,p_2$ を通る平面に対する半空間判定です。幾何学的には「平面とは半径無限大の球である」ことの帰結で、リフト空間ではどちらも超平面になるため、有限半径の球と平面が**フラグの分岐なしに**同じ述語で扱えます — 無限遠頂点は `Lift` と `InSphered` を多態で差し替えるだけです。凸包の各面は*無限遠胞* $(\infty, p_i, p_j, p_k)$ で閉じられるため、`Poin[]` に `nil` は現れません。最初の共線でない3点は全空間を二重に覆う鏡像の無限遠胞2つの種となり、4点目からは通常の追加処理がそのまま働きます。

### 2.4 同次外心とボロノイ双対性

中心 $c$、半径 $r$ の球は、$\mathbb{R}^4$ の超平面

```math
w \;=\; 2\,c \cdot x \;-\; \bigl(\lVert c \rVert^2 - r^2\bigr)
\qquad \text{(2.6)}
```

にリフトされます。そこで `TDelaCell3D.Circum` は、リフトされた4頂点を通る超平面の係数 — 4つの $4\times 4$ 小行列式 — を計算し、**同次外心** $(C_X, C_Y, C_Z, C_W)$ として返します。

- 有限胞では $(C_X/C_W,\ C_Y/C_W,\ C_Z/C_W)$ が外心、すなわちボロノイ頂点になります。
- 無限遠胞では自然に $C_W = 0$ へ退化し、$(C_X, C_Y, C_Z)$ が凸包面に双対な非有界ボロノイ半直線の外向きの方向になります。

計算には分岐も除算もなく、「中心＋半径」という損失のある表現を強制されることもありません。ボロノイ辺はドロネー面の双対であり、ビューアは面で隣接する胞の外心どうしを結び、半直線には (2.6) の退化を用います。

### 2.5 逐次添加（Bowyer–Watson 法）

`AddPoin` は点 $q$ を2相方式の Bowyer–Watson 法 [2][3] で挿入します（実処理は非公開の `InsertPoin`）。

1. **マーク** — $q$ を外接球に含む胞から出発して面越しに塗り広げ、$\operatorname{InSphere} > 0$ の胞の集合 = *キャビティ*を集めます。フラグによるマークは冪等なので、キャビティの双対グラフが木にならない 3D でも、同じ胞に複数の経路で到達して二重処理が起きることはありません。
2. **カーブ** — キャビティの境界面ごとに、その面と $q$ を結ぶ新しい胞を張って外側の胞と縫い（`Weld` の回転コードは頂点の同一性から導出）、新しい胞どうしを $q$ の周りで縫い、最後にキャビティの胞をまとめて解放します — 解放済みの胞への再突入は構造的に起こりません。

$q$ を外接球に含む胞は**ジャンプ＆ウォーク** [7] で検索します。$\lceil n^{1/4} \rceil$ 個の無作為標本を引き、最も近い標本のアンカー胞から、$q$ が外側にある面を越えて渡り続けます — 面の判定はまさに退化形 (2.5)、$\operatorname{InSphere}(A,B,C,\infty;\,q)$ です。期待コストは $O(n^{1/4})$ で、凸包の外では歩行が無限遠胞に入って止まります。退化した入力（重複、最初の3点の共線、既存の稜線の延長上の点など）では `AddPoin` は図を変えずに `nil` を返します。

### 2.6 星の除去と埋め戻しによる削除

`DeletePoin` は頂点 $v$ を**星の除去と埋め戻し**で削除します（実処理は非公開の `RemovePoin`）。

1. `CollectStar` で $v$ の*星*（$v$ を含む全胞）を集めます。取り除くと星型の穴が開き、その境界が $v$ の*リンク*です。
2. リンクの頂点だけから成る小さなドロネー図を、同じ逐次添加法で、同じ胞集合の中の独立した成分として作ります（入れ子の `TDelaunay3D` は作りません）。
3. その中から穴を埋める胞を切り出します。境界面ごとに、外側へ鏡像の向きで貼り合わせられる胞（`CanWeld`）を選び、そこから縫い目を越えずに届く胞を集めます（`FloodFills` が閉包の境界が穴の境界とちょうど一致することを検証します）。
4. 埋め草を穴の縁に縫い付け、星と使わなかった埋め草を解放します。

切り出しも縫い付けも純粋に組合せ的な検査だけで確定し、フリップの探索は含みません。星が鏡像対の2胞のときは、外側のフック2つを直接貼り合わせて処理します。検査に通らない退化配置では `DeletePoin` は `False` を返し、元の図は完全に無傷のまま残ります（[8] で研究された古典的な削除問題です）。

### 2.7 最近傍検索

`FindNearPoin` はジャンプ＆ウォークの着地胞から始めます。$q$ を外接球に含む胞の頂点は $q$ の近くにいるので、その中の最も近い頂点から、ドロネー辺を伝ってより近い隣接頂点へ降下します。移るたびに距離が厳密に縮むため、降下は $q$ をボロノイ胞 (2.1) に含む点 = 最近傍点で必ず停止します — 期待 $O(n^{1/4})$ の検索 ＋ $O(1)$ 段の降下です。デモでは、ビューアのスクリーン座標版 `FindPoin` を使ってマウス直下の削除対象の点を選びます。

## 3. アーキテクチャ

### 3.1 クラス図

```
[Ownership]
・TForm1 (Main.pas)    ：application: event forwarding only
  ┣・TDelaunay3D    ：diagram model (LUX.Delaunay.D3)
  ┃  ┣・PoinInf :TDelaPoin3DInf    ：single vertex at infinity
  ┃  ┣・Poins :TDelaPoinSet3D
  ┃  ┃  ┗・TDelaPoin3D    ：finite vertex (Lift, InSphered)
  ┃  ┗・Cells :TDelaCellSet3D
  ┃     ┗・TDelaCell3D    ：tetrahedron (InSphere, Circum)
  ┗・Viewer1 :TDelaunayViewer (frame)    ：rendering (LUX.Delaunay.D3.Viewer)
     ┣・TDelaunayViewport (TViewport3D)    ：orbit rig Yaw→Pitch→TCamera
     ┣・TDelaunayEdges (TControl3D)    ：Delaunay edges → polygonal tubes
     ┗・TDelaunayVoros (TControl3D)    ：Voronoi edges → prisms and cones

[Inheritance: TetraFlip mesh layer (LUX) → Delaunay classes]
・TTetraPoin3D
  ┗・TDelaPoin3D

・TTetraCell3D    ：connectivity: Weld / CanWeld / VertTable / BondTable
  ┗・TDelaCell3D

・TTetraCellSet3D
  ┗・TDelaCellSet3D
```

モデルは多播の `OnChange` でビューアに通知し、ビューアは2枚の頂点バッファレイヤの再構築をビューポートの `Paint` の先頭まで遅延して、1フレームに最大1回だけ行います。

### 3.2 ファイル構成

```
・Delaunay3D.dpr / Main.pas / Main.fmx    ：薄いフォーム。シーン生成コードなし
・_LIBRARY\LUXOPHIA\    ：ライブラリリポジトリの git subtree コピー
  ┣・LUX.Delaunay\    ：https://github.com/LUXOPHIA/LUX.Delaunay
  ┃  ┣・D3\LUX.Delaunay.D3.pas    ：3D ドロネー図（TDelaunay3D ほか）
  ┃  ┗・D3\LUX.Delaunay.D3.Viewer.pas/.fmx    ：TDelaunayViewer フレーム
  ┗・LUX\    ：https://github.com/LUXOPHIA/LUX（基盤ライブラリ）
     ┣・Data\Model\TetraFlip\    ：四面体メッシュ層（TTetraCell3D …）
     ┗・LUX.pas / LUX.D3.pas / LUX.D4.pas    ：ベクトル・デリゲートなど
```

## 4. 使い方

### 4.1 操作

| 入力 | 動作 |
|---|---|
| 左ドラッグ | カメラを回転 |
| ホイール | ズーム（ドリー） |
| 点をクリック | その点を削除 |
| `Add x10` | 正規分布の乱数点を10個追加 |
| `Del x10` | 無作為に選んだ点を最大10個削除 |
| `Clear` | 全消去 |

### 4.2 API の概略

アプリケーションのロジック全体は、ライブラリへの数個の呼び出しにすぎません。

```pascal
_Delaunay := TDelaunay3D.Create;
Viewer1.Delaunay := _Delaunay;              // ビューアを購読させる

_Delaunay.AddPoin( 2 * TSingle3D.RandG );   // 追加（退化した入力では nil）
_Delaunay.DeletePoin( V );                  // 削除（退化した入力では False）
_Delaunay.Clear;

Viewer1.Orbit( DYaw, DPitch );              // カメラ
Viewer1.Dolly( DDistance );
V := Viewer1.FindPoin( ScreenPos, 16 );     // カーソルから 16 px 以内の点
```

## 5. ビルド

1. RAD Studio（Delphi、FireMonkey）で `Delaunay3D.dproj` を開きます。
2. ターゲット `Win32` または `Win64` を選んで実行します。

ビューアは FMX 標準の `TViewport3D` を使うため、追加のパッケージ・DLL・サードパーティ製コンポーネントは不要です。ライブラリのコードはすべて git subtree として `_LIBRARY\` 以下に同梱されており、チェックアウトしたままビルドできます。

## 6. 参考文献

1. B. Delaunay, *Sur la sphère vide*, Bulletin de l'Académie des Sciences de l'URSS, Classe des sciences mathématiques et naturelles, 1934.
2. A. Bowyer, [*Computing Dirichlet tessellations*](https://doi.org/10.1093/comjnl/24.2.162), The Computer Journal, 24(2), 1981.
3. D. F. Watson, [*Computing the n-dimensional Delaunay tessellation with application to Voronoi polytopes*](https://doi.org/10.1093/comjnl/24.2.167), The Computer Journal, 24(2), 1981.
4. F. Aurenhammer, *Voronoi diagrams — a survey of a fundamental geometric data structure*, ACM Computing Surveys, 23(3), 1991.
5. K. Q. Brown, *Voronoi diagrams from convex hulls*, Information Processing Letters, 9(5), 1979.
6. J. R. Shewchuk, [*Adaptive Precision Floating-Point Arithmetic and Fast Robust Geometric Predicates*](https://www.cs.cmu.edu/~quake/robust.html), Discrete & Computational Geometry, 18, 1997.
7. E. P. Mücke, I. Saias, B. Zhu, *Fast randomized point location without preprocessing in two- and three-dimensional Delaunay triangulations*, Computational Geometry: Theory and Applications, 12, 1999.
8. O. Devillers, *On deletion in Delaunay triangulations*, International Journal of Computational Geometry & Applications, 12(3), 2002.

## 💖 [Embarcadero](https://www.embarcadero.com/jp/) [**Delphi**](https://www.embarcadero.com/jp/products/delphi)
ネイティブなクロスプラットフォームアプリを開発するための統合開発環境（ＩＤＥ）。
### Free Download: [**Delphi** Community Edition](https://www.embarcadero.com/jp/products/delphi/starter)
