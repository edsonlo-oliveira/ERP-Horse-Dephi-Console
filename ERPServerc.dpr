program ERPServerc;
{$APPTYPE CONSOLE}
{$R *.res} // Essa é a padrão do Delphi, mantenha
{$R 'Recursos.res' 'Recursos.rc'} // Adicione esta linha! Ela compila o seu .rc em .res e embute no EXE

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Comp.Client,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef,
  Horse,
  uEntityService in 'src\Services\uEntityService.pas',
  uEntityRepository in 'src\Repositories\uEntityRepository.pas',
  uEntityController in 'src\Controllers\uEntityController.pas',
  uRoutes in 'src\Routes\uRoutes.pas',
  uApiDatabase in 'src\Data\uApiDatabase.pas',
  uTenantRepository in 'src\Repositories\uTenantRepository.pas';

begin
  try
    //Título da aplicação da janela da console
    SetConsoleTitle('Sistema de ERP - Server');

    // Ignora o CTRL+C e outros sinais de interrupção do console
    // no Windows
    SetConsoleCtrlHandler(nil, True);
    Writeln('Sistema de ERP - Server (64 Bit) (Release Beta 1 for Windows/64) ' + FormatDateTime('dd-mm-yyyy hh:nn:ss', Now));
    Writeln('');

    // Inicializa a conexão com o PostgreSQL
    TApiDatabase.Initialize;
    TApiDatabase.Connection.Connected := True;
    Writeln('Conexao com Banco de Dados estabelecida com sucesso.');
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
            Writeln(
              'Comando nao reconhecido. ' +
              'Digite "quit" para sair.'
            );
          end;
        end;
      end
    ).Start;
    THorse.Listen(
      9000,
      procedure
      begin
        Writeln('Servidor rodando na porta 9000.');
        Writeln('Digite "quit" e pressione ENTER para sair.');
      end
    );
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Readln;
    end;
  end;
  // Libera os recursos da conexão com o banco
  TApiDatabase.Finalize;
end.
