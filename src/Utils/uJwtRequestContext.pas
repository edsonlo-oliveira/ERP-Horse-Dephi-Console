unit uJwtRequestContext;

interface

uses
  Horse,
  uJwtService;

const
  JWT_CONTEXT_KEY = 'JWT_CONTEXT';

procedure SetJwtContext(
  const AReq: THorseRequest;
  const AContext: TJwtContext
);

function TryGetJwtContext(
  const AReq: THorseRequest;
  out AContext: TJwtContext
): Boolean;

implementation

type
  TJwtContextHolder = class
  public
    Context: TJwtContext;
  end;

procedure SetJwtContext(
  const AReq: THorseRequest;
  const AContext: TJwtContext
);
var
  LHolder: TJwtContextHolder;
begin
  LHolder := TJwtContextHolder.Create;
  try
    LHolder.Context := AContext;
    AReq.State.AddOrSetValue(JWT_CONTEXT_KEY, LHolder);
    LHolder := nil;
  finally
    LHolder.Free;
  end;
end;

function TryGetJwtContext(
  const AReq: THorseRequest;
  out AContext: TJwtContext
): Boolean;
var
  LObject: TObject;
begin
  AContext.UserUuid := '';
  AContext.UserID := 0;
  AContext.TenantID := 0;
  AContext.LoginID := '';
  AContext.SuperUser := False;
  AContext.Scope := '';

  Result := False;

  if not Assigned(AReq) then
    Exit;

  if not AReq.State.TryGetValue(JWT_CONTEXT_KEY, LObject) then
    Exit;

  if not (LObject is TJwtContextHolder) then
    Exit;

  AContext := TJwtContextHolder(LObject).Context;
  Result := True;
end;

end.
