unit uDatabaseErrorHandler;

interface

uses
  System.SysUtils,
  System.StrUtils,
  FireDAC.Stan.Error;

type
  TDatabaseErrorInfo = record
    UserMessage: string;
    Details: string;
    HttpStatus: Integer;
  end;

  TDatabaseErrorHandler = class
  public
    class function Handle(
      const E: Exception
    ): TDatabaseErrorInfo; static;
  end;

implementation

//***********************************************
//* HANDLE
//***********************************************
class function TDatabaseErrorHandler.Handle(
  const E: Exception
): TDatabaseErrorInfo;
var
  Msg: string;
  MsgLower: string;
begin
  //***************************************
  //* DEFAULT HTTP STATUS
  //***************************************
  Result.HttpStatus :=
    500;

  Msg :=
    E.Message;

  MsgLower :=
    LowerCase(
      Msg
    );

  //***************************************
  //* DEFAULT MESSAGE
  //***************************************
  Result.UserMessage :=
    'Não foi possível concluir a operação.' +
    sLineBreak +
    'Tente novamente ou entre em contato com o suporte.';

  //***************************************
  //* TECHNICAL DETAILS
  //***************************************
  Result.Details :=
    E.ClassName +
    ': ' +
    Msg;

  //***************************************
  //* FIREDAC
  //***************************************
  if E is EFDDBEngineException then
  begin
    Result.Details :=
      EFDDBEngineException(E).Message;
  end;

  //***************************************
  //* DUPLICATE RECORD - 23505
  //***************************************
  if
    (Pos('23505', MsgLower) > 0) or
    (Pos('duplicate key value', MsgLower) > 0) or
    (Pos('unique constraint', MsgLower) > 0) or
    (Pos('violates unique constraint', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      409;

    Result.UserMessage :=
      'Não foi possível salvar o registro.' +
      sLineBreak +
      'Já existe outro registro com os mesmos dados.';

    Exit;
  end;

  //***************************************
  //* FOREIGN KEY - 23503
  //***************************************
  if
    (Pos('23503', MsgLower) > 0) or
    (Pos('foreign key constraint', MsgLower) > 0) or
    (Pos('violates foreign key', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      409;

    Result.UserMessage :=
      'Não foi possível realizar a operação.' +
      sLineBreak +
      'O registro está relacionado a outros dados do sistema.';

    Exit;
  end;

  //***************************************
  //* NOT NULL - 23502
  //***************************************
  if
    (Pos('23502', MsgLower) > 0) or
    (Pos('not-null constraint', MsgLower) > 0) or
    (Pos('null value in column', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      400;

    Result.UserMessage :=
      'Não foi possível salvar o registro.' +
      sLineBreak +
      'Existem campos obrigatórios que não foram preenchidos.';

    Exit;
  end;

  //***************************************
  //* CHECK CONSTRAINT - 23514
  //***************************************
  if
    (Pos('23514', MsgLower) > 0) or
    (Pos('check constraint', MsgLower) > 0) or
    (Pos('violates check constraint', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      400;

    Result.UserMessage :=
      'Não foi possível salvar o registro.' +
      sLineBreak +
      'Um dos valores informados não é válido.';

    Exit;
  end;

  //***************************************
  //* PERMISSION DENIED - 42501
  //***************************************
  if
    (Pos('42501', MsgLower) > 0) or
    (Pos('permission denied', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      403;

    Result.UserMessage :=
      'Você não possui permissão para realizar esta operação.';

    Exit;
  end;

  //***************************************
  //* POSTGRESQL SERVER UNAVAILABLE
  //***************************************
  if
    (Pos('could not connect to server', MsgLower) > 0) or
    (Pos('connection refused', MsgLower) > 0) or
    (Pos('server closed the connection unexpectedly', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      503;

    Result.UserMessage :=
      'Não foi possível conectar ao banco de dados.' +
      sLineBreak +
      'O servidor pode estar indisponível.';

    Exit;
  end;

  //***************************************
  //* CONNECTION ERROR
  //***************************************
  if
    (Pos('connection', MsgLower) > 0) and
    (
      (Pos('failed', MsgLower) > 0) or
      (Pos('error', MsgLower) > 0) or
      (Pos('lost', MsgLower) > 0)
    )
  then
  begin
    Result.HttpStatus :=
      503;

    Result.UserMessage :=
      'Não foi possível conectar ao banco de dados.' +
      sLineBreak +
      'Verifique a conexão com o servidor.';

    Exit;
  end;

  //***************************************
  //* SQL SYNTAX ERROR - 42601
  //***************************************
  if
    (Pos('syntax error', MsgLower) > 0) or
    (Pos('42601', MsgLower) > 0)
  then
  begin
    Result.HttpStatus :=
      500;

    Result.UserMessage :=
      'Ocorreu um erro interno na operação com o banco de dados.';

    Exit;
  end;
end;

end.
