program ERPServerc;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  uRoutes in 'src\Services\uRoutes.pas',
  uEntityService in 'src\Services\uEntityService.pas',
  uEntityRepository in 'src\Repositories\uEntityRepository.pas',
  uEntityController in 'src\Controllers\uEntityController.pas';

begin
  try
    RegisterRoutes;

    THorse.Listen(9000);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Readln;
    end;
  end;
end.
