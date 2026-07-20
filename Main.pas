unit Main;

interface //#################################################################### ■

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,
  LUX, LUX.D3,
  LUX.Delaunay.D3,
  LUX.Delaunay.D3.Viewer;

type
  TForm1 = class(TForm)
    Viewer1: TDelaunayViewer;
    Panel1: TPanel;
      ButtonC: TButton;
      ButtonA: TButton;
      ButtonD: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Viewer1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Viewer1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Viewer1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Viewer1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure ButtonCClick(Sender: TObject);
    procedure ButtonAClick(Sender: TObject);
    procedure ButtonDClick(Sender: TObject);
  private
    { private 宣言 }
    _MouseP :TPointF;   // ドラッグの前回位置
    _MouseM :Single;    // ドラッグの累積移動量（クリック判定）
    _MouseB :Boolean;   // 左ボタンが押されているか
  public
    { public 宣言 }
    _Delaunay :TDelaunay3D;
  end;

var
  Form1: TForm1;

implementation //############################################################### ■

uses System.Math;

{$R *.fmx}

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

procedure TForm1.FormCreate(Sender: TObject);
begin
     _Delaunay := TDelaunay3D.Create;

     with Viewer1 do
     begin
          Delaunay := _Delaunay;

          Distance := 15;

          Poins.Radius := 0.08;
          Edges.Radius := 0.02;
          Cells.Shrink := 0.5;
     end;

     ButtonAClick( Sender );
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     Viewer1.Delaunay := nil;  // 購読を解除してから解放する

     _Delaunay.Free;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TForm1.Viewer1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
     if Button = TMouseButton.mbLeft then
     begin
          _MouseB := True;
          _MouseP := TPointF.Create( X, Y );
          _MouseM := 0;
     end;
end;

procedure TForm1.Viewer1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
   P :TPointF;
begin
     if _MouseB then
     begin
          P := TPointF.Create( X, Y );

          Viewer1.Orbit( P.X - _MouseP.X, -( P.Y - _MouseP.Y ) );  // ドラッグ = 回転

          _MouseM := _MouseM + Abs( P.X - _MouseP.X ) + Abs( P.Y - _MouseP.Y );

          _MouseP := P;
     end;
end;

procedure TForm1.Viewer1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
   V :TDelaPoin3D;
begin
     if Button = TMouseButton.mbLeft then
     begin
          _MouseB := False;

          if _MouseM < 4 then  // 動かさずに離した = クリック
          begin
               V := Viewer1.FindPoin( TPointF.Create( X, Y ), 16 );

               if Assigned( V ) then _Delaunay.DeletePoin( V );  // 近くの点 → 削除
          end;
     end;
end;

procedure TForm1.Viewer1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
     Viewer1.Dolly( - WheelDelta / 120 );  // ホイール = ズーム

     Handled := True;
end;

//------------------------------------------------------------------------------

procedure TForm1.ButtonCClick(Sender: TObject);
begin
     _Delaunay.Clear;
end;

procedure TForm1.ButtonAClick(Sender: TObject);
var
   N :Integer;
begin
     for N := 1 to 10 do _Delaunay.AddPoin( 2 * TSingle3D.RandG );
end;

procedure TForm1.ButtonDClick(Sender: TObject);
var
   N :Integer;
begin
     for N := 1 to Min( 10, _Delaunay.Poins.Count ) do
     begin
          _Delaunay.DeletePoin( _Delaunay.Poins[ Random( _Delaunay.Poins.Count ) ] );
     end;
end;

end. //######################################################################### ■
