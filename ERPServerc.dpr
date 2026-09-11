program ERPServerc;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  uEntityService in 'src\Services\uEntityService.pas',
  uEntityRepository in 'src\Repositories\uEntityRepository.pas',
  uEntityController in 'src\Controllers\uEntityController.pas',
  uRoutes in 'src\Routes\uRoutes.pas';

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
