unit uJwtMiddleware;

interface

uses
  Horse;

procedure JwtMiddleware(
  AReq: THorseRequest;
  ARes: THorseResponse;
  ANext: TNextProc
);

implementation

uses
  System.SysUtils,
  uJwtService,
  uJwtRequestContext;

const
  PUBLIC_ROUTES: array[0..0] of string = (
    '/api/v1/auth/login'
  );

function IsPublicRoute(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(PUBLIC_ROUTES) to High(PUBLIC_ROUTES) do
    if SameText(APath, PUBLIC_ROUTES[I]) then
      Exit(True);
end;

procedure JwtMiddleware(
  AReq: THorseRequest;
  ARes: THorseResponse;
  ANext: TNextProc
);
var
  LAuthorization: string;
  LToken: string;
  LJwtContext: TJwtContext;
begin
  if IsPublicRoute(AReq.PathInfo) then
  begin
    ANext;
    Exit;
  end;

  LAuthorization := Trim(AReq.Headers['Authorization']);

  if LAuthorization = '' then
  begin
    ARes.Status(401).Send('{"success":false,"message":"Token de autenticação não informado."}');
    Exit;
  end;

  if not SameText(Copy(LAuthorization, 1, Length('Bearer ')), 'Bearer ') then
  begin
    ARes.Status(401).Send('{"success":false,"message":"Formato do Authorization inválido."}');
    Exit;
  end;

  LToken := Trim(Copy(LAuthorization, Length('Bearer ') + 1, MaxInt));

  if LToken = '' then
  begin
    ARes.Status(401).Send('{"success":false,"message":"Token de autenticação não informado."}');
    Exit;
  end;

  if not TJwtService.ValidateToken(LToken, LJwtContext) then
  begin
    ARes.Status(401).Send('{"success":false,"message":"Token de autenticação inválido ou expirado."}');
    Exit;
  end;

  SetJwtContext(AReq, LJwtContext);

  ANext;
end;

end.
