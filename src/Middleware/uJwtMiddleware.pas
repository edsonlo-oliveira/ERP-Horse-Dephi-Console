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
  uJwtService;

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
  LAuthorization :=
    Trim(
      AReq.Headers['Authorization']
    );

  if LAuthorization = '' then
  begin
    ARes
      .Status(401)
      .Send(
        '{"success":false,"message":"Token de autenticação não informado."}'
      );
    Exit;
  end;

  if not SameText(
    Copy(
      LAuthorization,
      1,
      Length('Bearer ')
    ),
    'Bearer '
  ) then
  begin
    ARes
      .Status(401)
      .Send(
        '{"success":false,"message":"Formato do Authorization inválido."}'
      );
    Exit;
  end;

  LToken :=
    Trim(
      Copy(
        LAuthorization,
        Length('Bearer ') + 1,
        MaxInt
      )
    );

  if LToken = '' then
  begin
    ARes
      .Status(401)
      .Send(
        '{"success":false,"message":"Token de autenticação não informado."}'
      );
    Exit;
  end;

  if not TJwtService.ValidateToken(
    LToken,
    LJwtContext
  ) then
  begin
    ARes
      .Status(401)
      .Send(
        '{"success":false,"message":"Token de autenticação inválido ou expirado."}'
      );
    Exit;
  end;

  ANext;
end;

end.
