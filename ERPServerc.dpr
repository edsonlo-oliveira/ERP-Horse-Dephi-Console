program ERPServerc;

{$APPTYPE CONSOLE}

{$R *.res} // Essa é a padrão do Delphi, mantenha
{$R 'Recursos.res' 'Recursos.rc'} // Adicione esta linha! Ela compila o seu .rc em .res e embute no EXE

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Winapi.Windows,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Comp.Client,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef,
  FireDAC.Stan.Pool,
  Horse,
  uEntityService in 'src\Services\uEntityService.pas',
  uEntityRepository in 'src\Repositories\uEntityRepository.pas',
  uEntityController in 'src\Controllers\uEntityController.pas',
  uRoutes in 'src\Routes\uRoutes.pas',
  uApiDatabase in 'src\Data\uApiDatabase.pas',
  uTenantRepository in 'src\Repositories\uTenantRepository.pas',
  uTenantService in 'src\Services\uTenantService.pas',
  uTenantController in 'src\Controllers\uTenantController.pas',
  uUserRepository in 'src\Repositories\uUserRepository.pas',
  uUserService in 'src\Services\uUserService.pas',
  uUserController in 'src\Controllers\uUserController.pas',
  uPasswordUtils in 'src\Utils\uPasswordUtils.pas',
  uAuthService in 'src\Services\uAuthService.pas',
  uAuthController in 'src\Controllers\uAuthController.pas',
  uJwtConfig in 'src\Utils\uJwtConfig.pas',
  uJwtService in 'src\Services\uJwtService.pas',
  uJwtTest in 'src\Test\uJwtTest.pas',
  uJwtMiddleware in 'src\Middleware\uJwtMiddleware.pas',
  uHttpAuthUtils in 'src\Utils\uHttpAuthUtils.pas',
  uJwtRequestContext in 'src\Utils\uJwtRequestContext.pas';

var
  GEncerrarLock: TCriticalSection;
  GJaEncerrado: Boolean = False;

// Rotina única de encerramento.
// É chamada pelo comando "quit", pelo fechamento da janela (X / menu),
// por logoff/shutdown e ao final normal do programa.
// Só executa uma vez; quem chegar depois espera a primeira chamada terminar.
procedure Encerrar;
begin
  GEncerrarLock.Enter;
  try
    if GJaEncerrado then
      Exit;
    GJaEncerrado := True;

    Writeln('Encerrando o servidor...');
    try
      THorse.StopListen;
    except
      // Horse já parado ou não iniciado: ignora
    end;

    try
      // Libera os recursos da conexão com o banco
      TApiDatabase.Finalize;
      Writeln('Conexao com o Banco de Dados encerrada.');
    except
      on E: Exception do
        Writeln('Erro ao encerrar o banco: ' + E.Message);
    end;

    Sleep(1000); // tempo para você ver as mensagens
  finally
    GEncerrarLock.Leave;
  end;
end;

// Handler de eventos do console (roda em uma thread separada do Windows)
function ConsoleCtrlHandler(CtrlType: DWORD): BOOL; stdcall;
begin
  case CtrlType of

    CTRL_CLOSE_EVENT,
    CTRL_LOGOFF_EVENT,
    CTRL_SHUTDOWN_EVENT:
      begin
        Encerrar;
        Result := True;
      end;

    CTRL_C_EVENT,
    CTRL_BREAK_EVENT:
      begin
        // Ignora Ctrl+C e Ctrl+Break
        Result := True;
      end;

  else
    Result := False;
  end;
end;

begin
  GEncerrarLock := TCriticalSection.Create;
  try
    // Título da aplicação da janela da console
    SetConsoleTitle('Sistema de ERP - Server');

    // Continua ignorando o Ctrl+C
    //SetConsoleCtrlHandler(nil, True);
    // Intercepta X da janela, menu, logoff e shutdown
    //SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
    if not SetConsoleCtrlHandler(@ConsoleCtrlHandler, True) then
      RaiseLastOSError;

    Writeln('Sistema de ERP - Server (64 Bit) (Release Beta 1 for Windows/64) ' +
      FormatDateTime('dd-mm-yyyy hh:nn:ss', Now));
    Writeln('');

    // Inicializa a infraestrutura FireDAC
    // e o pool de conexões PostgreSQL
    TApiDatabase.Initialize;
    Writeln('Pool de conexoes com Banco de Dados inicializado com sucesso.');
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
            Encerrar;
            Break;
          end
          else
            Writeln('Comando nao reconhecido. Digite "quit" para sair.');
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

  // Fim normal (ou erro na subida): garante o fechamento.
  // Se o quit ou a janela já estiverem encerrando, aqui ele só espera terminar.
  Encerrar;
end.

