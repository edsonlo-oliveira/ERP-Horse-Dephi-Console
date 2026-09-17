unit uJwtService;

interface

type

  TJwtContext = record
    UserUuid: string;
    UserID: Int64;
    TenantID: Int64;
    LoginID: string;
    SuperUser: Boolean;
    Scope: string;
  end;

  TJwtService = class
  public
    class function GenerateToken(
    const AUserUuid: string;
    const AUserId: Int64;
    const ATenantId: Int64;
    const ALoginId: string;
    const ASuperUser: Boolean;
    const AScope: string
  ): string;

  class function ValidateToken(
    const AToken: string;
    out AContext: TJwtContext
  ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Rtti,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  JOSE.Types.JSON,
  JOSE.Types.Bytes,
  uJwtConfig;

type
  TJwtClaimsAccess = class(TJWTClaims);

//***************************************
//* GENERATETOKEN
//***************************************
class function TJwtService.GenerateToken(
  const AUserUuid: string;
  const AUserId: Int64;
  const ATenantId: Int64;
  const ALoginId: string;
  const ASuperUser: Boolean;
  const AScope: string
): string;
var
  LJWT: TJWT;
  LIssuedAt: TDateTime;
  LExpiration: TDateTime;
begin
  if Trim(AUserUuid) = '' then
    raise Exception.Create(
    'User UUID é obrigatório para gerar o token.'
  );

  if AUserId <= 0 then
    raise Exception.Create(
    'User ID inválido para gerar o token.'
  );

  if ATenantId <= 0 then
    raise Exception.Create(
    'Tenant ID inválido para gerar o token.'
  );

  if Trim(ALoginId) = '' then
    raise Exception.Create(
    'Login ID é obrigatório para gerar o token.'
  );

  if not SameText(AScope, 'GLOBAL') and
    not SameText(AScope, 'TENANT') then
    raise Exception.Create(
    'Scope inválido para gerar o token.'
  );

  LIssuedAt := Now;

  LExpiration :=
  IncSecond(
    LIssuedAt,
    JWT_EXPIRES_IN_SECONDS
  );

  LJWT := TJWT.Create;
  try
    LJWT.Claims.Subject := AUserUuid;

    LJWT.Claims.Issuer := JWT_ISSUER;

    LJWT.Claims.IssuedAt :=
      LIssuedAt;

    LJWT.Claims.Expiration :=
      LExpiration;

    LJWT.Claims.SetClaimOfType<Int64>(
      'user_id',
      AUserId
    );

    LJWT.Claims.SetClaimOfType<Int64>(
      'tenant_id',
      ATenantId
    );

    LJWT.Claims.SetClaimOfType<string>(
      'login_id',
      ALoginId
    );

    LJWT.Claims.SetClaimOfType<Boolean>(
      'super_user',
      ASuperUser
    );

    LJWT.Claims.SetClaimOfType<string>(
      'scope',
      UpperCase(Trim(AScope))
    );

    Result :=
      string(
        TJOSE.SHA256CompactToken(
          GetAuthSecret,
          LJWT
        )
      );

   finally
    LJWT.Free;
   end;
end;

//***************************************
//* VALIDATETOKEN
//***************************************
class function TJwtService.ValidateToken(
  const AToken: string;
  out AContext: TJwtContext
): Boolean;
var
  LJWT: TJWT;
  LToken: TJOSEBytes;
  LNow: TDateTime;
  LExp: TDateTime;
  LUserValue: TValue;
  LTenantValue: TValue;
  LSuperUserValue: TValue;
begin
  Result := False;

  AContext.UserUuid := '';
  AContext.UserID := 0;
  AContext.TenantID := 0;
  AContext.LoginID := '';
  AContext.SuperUser := False;
  AContext.Scope := '';

  if Trim(AToken) = '' then
    Exit;

  try
    LToken := TJOSEBytes(AToken);

LJWT :=
  TJOSE.VerifyOrRaise(
    GetAuthSecret,
    LToken
  );

if not Assigned(LJWT) then
  Exit;

try
  if not LJWT.Verified then
    Exit;

    {--------------------------------------------------------------------}
    { Header / algoritmo                                                 }
    {--------------------------------------------------------------------}

    if not SameText(
      LJWT.Header.Algorithm,
      JWT_ALGORITHM
    ) then
      Exit;

    {--------------------------------------------------------------------}
    { Issuer                                                             }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.HasIssuer then
      Exit;

    if not SameText(
      LJWT.Claims.Issuer,
      JWT_ISSUER
    ) then
      Exit;

    {--------------------------------------------------------------------}
    { Subject                                                            }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.HasSubject then
      Exit;

    if Trim(LJWT.Claims.Subject) = '' then
      Exit;

    {--------------------------------------------------------------------}
    { Expiração                                                          }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.HasExpiration then
      Exit;

    LExp := LJWT.Claims.Expiration;

    if LExp <= 0 then
      Exit;

    LNow := Now;

    if LExp <= LNow then
      Exit;

    {--------------------------------------------------------------------}
    { user_id                                                            }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.ClaimExists('user_id') then
      Exit;

    LUserValue :=
      TJSONUtils.GetJSONValueInt64(
        'user_id',
        TJwtClaimsAccess(LJWT.Claims).FJSON
      );

    if LUserValue.IsEmpty then
      Exit;

    AContext.UserID :=
      LUserValue.AsType<Int64>;

    if AContext.UserID <= 0 then
      Exit;

    {--------------------------------------------------------------------}
    { tenant_id                                                          }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.ClaimExists('tenant_id') then
      Exit;

    LTenantValue :=
      TJSONUtils.GetJSONValueInt64(
        'tenant_id',
        TJwtClaimsAccess(LJWT.Claims).FJSON
      );

    if LTenantValue.IsEmpty then
      Exit;

    AContext.TenantID :=
      LTenantValue.AsType<Int64>;

    if AContext.TenantID <= 0 then
      Exit;

    {--------------------------------------------------------------------}
    { login_id                                                           }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.ClaimExists('login_id') then
      Exit;

    AContext.LoginID :=
      TJSONUtils.GetJSONValueAsString(
        'login_id',
        TJwtClaimsAccess(LJWT.Claims).FJSON
      );

    if Trim(AContext.LoginID) = '' then
      Exit;

    {--------------------------------------------------------------------}
    { super_user                                                         }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.ClaimExists('super_user') then
      Exit;

    if not TJSONUtils.IsJSONBool(
      TJwtClaimsAccess(LJWT.Claims).FJSON.GetValue('super_user')
    ) then
      Exit;

    LSuperUserValue :=
      TJSONUtils.GetJSONValue(
        'super_user',
        TJwtClaimsAccess(LJWT.Claims).FJSON
      );

    AContext.SuperUser :=
      LSuperUserValue.AsType<Boolean>;

    {--------------------------------------------------------------------}
    { scope                                                              }
    {--------------------------------------------------------------------}

    if not LJWT.Claims.ClaimExists('scope') then
      Exit;

    AContext.Scope :=
      UpperCase(
        Trim(
          TJSONUtils.GetJSONValueAsString(
            'scope',
            TJwtClaimsAccess(LJWT.Claims).FJSON
          )
        )
      );

    if (AContext.Scope <> 'GLOBAL') and
       (AContext.Scope <> 'TENANT') then
      Exit;

    {--------------------------------------------------------------------}
    { Regras de segurança entre SuperUser e Scope                       }
    {--------------------------------------------------------------------}

    if AContext.SuperUser and
       (AContext.Scope <> 'GLOBAL') then
      Exit;

    if (not AContext.SuperUser) and
       (AContext.Scope <> 'TENANT') then
      Exit;

    {--------------------------------------------------------------------}
    { Contexto válido                                                     }
    {--------------------------------------------------------------------}

    AContext.UserUuid :=
      LJWT.Claims.Subject;

    Result := True;

  finally
    LJWT.Free;
  end;

  except
    on E: Exception do
    begin
      Result := False;
      AContext.UserUuid := '';
      AContext.UserID := 0;
      AContext.TenantID := 0;
      AContext.LoginID := '';
      AContext.SuperUser := False;
      AContext.Scope := '';
    end;
  end;
end;

end.
