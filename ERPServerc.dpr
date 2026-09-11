program ERPServerc;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows, // Necessário para manipular os eventos do console no Windows
  Horse,
  uEntityService in 'src\Services\uEntityService.pas',
  uEntityRepository in 'src\Repositories\uEntityRepository.pas',
  uEntityController in 'src\Controllers\uEntityController.pas',
  uRoutes in 'src\Routes\uRoutes.pas';

begin
  try
    // Ignora o CTRL+C e outros sinais de interrupção do console no Windows
    SetConsoleCtrlHandler(nil, True);

    Writeln('Sistema de ERP - Server (64 Bit) (Release Beta 1 for Windows/64) ', FormatDateTime('dd-mm-yyyy hh:nn:ss', Now));
    Writeln('');

    RegisterRoutes;

    TThread.CreateAnonymousThread(
      procedure
      var
        Comando: string;
      begin
        while True do
        begin
          Readln(Comando);

          if LowerCase(Trim(Comando)) = 'quit' then
          begin
            Writeln('Encerrando o servidor...');
            THorse.StopListen;
            Break;
          end
          else
          begin
            Writeln('Comando não reconhecido. Digite "quit" para sair.');
          end;
        end;
      end).Start;

    THorse.Listen(9000,
    procedure
    begin
      Writeln('Servidor rodando na porta 9000.');
      Writeln('Digite "quit" e pressione ENTER para sair.');
    end);

  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Readln;
    end;
  end;
end.

