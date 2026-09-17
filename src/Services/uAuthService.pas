unit uAuthService;

interface

type
  TAuthService = class
  public
    class function Login(
      const ALoginId: string;
      const APassword: string
    ): string;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uUserRepository,
  uPasswordUtils,
  uApiDatabase,
  uJwtService,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  Data.DB,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  uJwtConfig;

//***************************************
//* LOGIN
//***************************************
class function TAuthService.Login(
  const ALoginId: string;
  const APassword: string
): string;
var
  LUserJson: string;
  LJson: TJSONValue;
  LObject: TJSONObject;
  LUserId: Int64;
  LUserUuid: string;
  LTenantId: Int64;
  LLoginId: string;
  LPasswordHash: string;
  LStatus: string;
  LSuperUser: Boolean;
  LQuery: TFDQuery;
  LToken: string;
  LScope: string;
begin
  if Trim(ALoginId) = '' then
    raise Exception.Create('Login é obrigatório.');

  if APassword = '' then
    raise Exception.Create('Senha é obrigatória.');

  LUserJson := TUserRepository.FindByLogin(
    Trim(ALoginId)
  );

  if LUserJson = '' then
    raise Exception.Create(
      'Login ou senha inválidos.'
    );

  LJson := TJSONObject.ParseJSONValue(LUserJson);
  try
    if not Assigned(LJson) then
      raise Exception.Create(
        'Não foi possível processar os dados do usuário.'
      );

    if not (LJson is TJSONObject) then
      raise Exception.Create(
        'Resposta inválida ao consultar o usuário.'
      );

    LObject := TJSONObject(LJson);

    LUserId :=
      LObject.GetValue<Int64>('user_id');

    LUserUuid :=
      LObject.GetValue<string>('user_uuid');

    LTenantId :=
      LObject.GetValue<Int64>('tenant_id');

    LLoginId :=
      LObject.GetValue<string>('login_id');

    LPasswordHash :=
      LObject.GetValue<string>('password_hash');

    LStatus :=
      UpperCase(
        Trim(
          LObject.GetValue<string>('status')
        )
      );

    LSuperUser :=
      LObject.GetValue<Boolean>('super_user');

  finally
    LJson.Free;
  end;

  if LStatus <> 'ACTIVE' then
    raise Exception.Create(
      'Usuário não está ativo.'
    );

  if not VerifyPassword(
    APassword,
    LPasswordHash
  ) then
    raise Exception.Create(
      'Login ou senha inválidos.'
    );

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection :=
      TApiDatabase.Connection;

    LQuery.SQL.Text :=
      'UPDATE core.users ' +
      'SET last_login_at = CURRENT_TIMESTAMP, ' +
      '    updated_at = CURRENT_TIMESTAMP ' +
      'WHERE user_id = :user_id ' +
      '  AND deleted_at IS NULL';

    if LSuperUser then
      LScope := 'GLOBAL'
    else
      LScope := 'TENANT';

    LToken :=
      TJwtService.GenerateToken(
        LUserUuid,
        LUserId,
        LTenantId,
        LLoginId,
        LSuperUser,
        LScope
      );

    LQuery.ParamByName('user_id').DataType :=
      ftLargeint;

    LQuery.ParamByName('user_id').AsLargeInt :=
      LUserId;

    LQuery.ExecSQL;

  finally
    LQuery.Free;
  end;

  LObject := TJSONObject.Create;
  try
    LObject.AddPair(
      'user_uuid',
      LUserUuid
    );

    LObject.AddPair(
      'tenant_id',
      TJSONNumber.Create(LTenantId)
    );

    LObject.AddPair(
      'login_id',
      LLoginId
    );

    LObject.AddPair(
      'status',
      LStatus
    );

    LObject.AddPair(
      'super_user',
      TJSONBool.Create(LSuperUser)
    );

    LObject.AddPair(
      'token',
      LToken
    );
    Result := LObject.ToJSON;

  finally
    LObject.Free;
  end;
end;

end.

