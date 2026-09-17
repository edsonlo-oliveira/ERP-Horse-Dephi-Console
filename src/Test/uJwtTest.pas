unit uJwtTest;

interface

procedure TestarJwt;

implementation

uses
  System.SysUtils,
  uJwtService;

procedure TestarJwt;
var
  LToken: string;
  LContext: TJwtContext;
begin
  { Cole aqui temporariamente o JWT retornado pelo login }
  LToken := 'COLE_AQUI_O_TOKEN';

  if TJwtService.ValidateToken(
    LToken,
    LContext
  ) then
  begin
    Writeln('');
    Writeln('======================================');
    Writeln('JWT VALIDADO COM SUCESSO');
    Writeln('======================================');
    Writeln('UserUuid : ', LContext.UserUuid);
    Writeln('UserID   : ', LContext.UserID);
    Writeln('TenantID : ', LContext.TenantID);
    Writeln('LoginID  : ', LContext.LoginID);
    Writeln('SuperUser: ', BoolToStr(LContext.SuperUser, True));
    Writeln('Scope    : ', LContext.Scope);
    Writeln('======================================');
  end
  else
  begin
    Writeln('');
    Writeln('======================================');
    Writeln('JWT INVALIDO');
    Writeln('======================================');
  end;
end;

end.
