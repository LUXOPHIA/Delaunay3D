program Delaunay3D;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {Form1},
  LUX in '_LIBRARY\LUXOPHIA\LUX\LUX.pas',
  LUX.D1 in '_LIBRARY\LUXOPHIA\LUX\LUX.D1.pas',
  LUX.D2 in '_LIBRARY\LUXOPHIA\LUX\LUX.D2.pas',
  LUX.D3 in '_LIBRARY\LUXOPHIA\LUX\LUX.D3.pas',
  LUX.D4 in '_LIBRARY\LUXOPHIA\LUX\LUX.D4.pas',
  LUX.Data.List.core in '_LIBRARY\LUXOPHIA\LUX\Data\List\LUX.Data.List.core.pas',
  LUX.Data.List in '_LIBRARY\LUXOPHIA\LUX\Data\List\LUX.Data.List.pas',
  LUX.Data.Model.Poins in '_LIBRARY\LUXOPHIA\LUX\Data\Model\LUX.Data.Model.Poins.pas',
  LUX.Data.Model.Cells in '_LIBRARY\LUXOPHIA\LUX\Data\Model\LUX.Data.Model.Cells.pas',
  LUX.Data.Model.TetraFlip.core in '_LIBRARY\LUXOPHIA\LUX\Data\Model\TetraFlip\LUX.Data.Model.TetraFlip.core.pas',
  LUX.Data.Model.TetraFlip in '_LIBRARY\LUXOPHIA\LUX\Data\Model\TetraFlip\LUX.Data.Model.TetraFlip.pas',
  LUX.Data.Model.TetraFlip.D3 in '_LIBRARY\LUXOPHIA\LUX\Data\Model\TetraFlip\LUX.Data.Model.TetraFlip.D3.pas',
  LUX.Delaunay.D3 in '_LIBRARY\LUXOPHIA\LUX.Delaunay\D3\LUX.Delaunay.D3.pas',
  LUX.Delaunay.D3.Viewer in '_LIBRARY\LUXOPHIA\LUX.Delaunay\D3\LUX.Delaunay.D3.Viewer.pas' {DelaunayViewer: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
