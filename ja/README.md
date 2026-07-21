# Delaunay3D

**Delphi（FireMonkey）による対話的な 3D ドロネー図 / ボロノイ図のデモ。**

[English](../README.md) | [日本語](README.md)

点を追加・削除すると、ドロネー四面体分割とボロノイ図が FMX 3D シーンの中でポリゴンの立体としてリアルタイムに更新されます。[LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) ライブラリの上に作られています。

- 逐次的な **追加**（Bowyer–Watson 法）と **削除**（星の除去と、リンクの小さなドロネー図による決定論的な埋め戻し）— どの操作の後も図は常にドロネーで、退化した入力には `AddPoin` が `nil` を、`DeletePoin` が `False` を返します。
- **無限遠頂点方式** — スーパーテトラもバウンディングボックスも不要で、凸包上の点も内部の点と同じように扱えます。
- **ポリゴン化された辺** — ドロネー辺は四面体の面の枠を張り合わせた多角形の管、ボロノイ辺は外心どうしを結ぶ三角柱（非有界の半直線は錐）。フラットシェーディングが構造を鋭い立体として見せます。
- 描画はライブラリの `TDelaunayViewer` フレームが担い、アプリケーション自体はシーン生成コードを持ちません。

## 操作

| 入力 | 動作 |
|---|---|
| 左ドラッグ | カメラを回転 |
| ホイール | ズーム |
| 点をクリック | その点を削除 |
| `Add x10` | ランダムな点を10個追加 |
| `Del x10` | ランダムに10個削除 |
| `Clear` | 全消去 |

## 構成

```
Delaunay3D.dpr / Main.pas / Main.fmx    … アプリケーション（薄いフォーム。シーン生成コードは持たない）
_LIBRARY\LUXOPHIA\
  LUX.Delaunay\                         … ドロネー図ライブラリ（git subtree）
    D3\LUX.Delaunay.D3.pas              …   3D ドロネー図（TDelaunay3D）
    D3\LUX.Delaunay.D3.Viewer.pas/.fmx  …   3D ビューアフレーム（TDelaunayViewer）
  LUX\                                  … 基盤ライブラリ（git subtree）
    Data\Model\TetraFlip\               …   フリップ型四面体メッシュ
```

## ビルド

RAD Studio で `Delaunay3D.dproj` を開いて実行します（Win32 / Win64）。ビューアは FMX 標準の `TViewport3D` を使うため、追加のパッケージは不要です。

## ライブラリのドキュメント

クラスの一覧と API の使い方はライブラリ側にあります:
[LUX.Delaunay/D3](https://github.com/LUXOPHIA/LUX.Delaunay/tree/main/D3)
