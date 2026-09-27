unit uUserService;

interface

type
  TUserService = class
  public
    class function List(
      const ATenantId: Int64;
      const ASuperUser: Boolean
    ): string;

    class function GetByUuid(
      const AUserUuid: string;
      const ATenantId: Int64;
      const ASuperUser: Boolean
    ): string;

    class function Create(
      const ACurrentTenantId: Int64;
      const ATargetTenantId: Int64;
      const ALoginId: string;
      const AFirstName: string;
      const AMiddleName: string;
      const ALastName: string;
      const AEmail: string;
      const APassword: string;
      const AStatus: string;
      const ASuperUser: Boolean;
      const ACurrentSuperUser: Boolean
    ): string;

    class function Update(
      const ACurrentTenantId: Int64;
      const AUserUuid: string;
      const ALoginId: string;
      const AFirstName: string;
      const AMiddleName: string;
      const ALastName: string;
      const AEmail: string;
      const APassword: string;
      const AStatus: string;
      const ASuperUser: Boolean;
      const ACurrentSuperUser: Boolean
    ): string;

    class function Delete(
      const ACurrentTenantId: Int64;
      const AUserUuid: string;
      const ACurrentSuperUser: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uUserRepository,
  uPasswordUtils,
  uTenantRepository;

//***************************************
//* LIST
//***************************************
class function TUserService.List(
  const ATenantId: Int64;
  const ASuperUser: Boolean
): string;
begin
  if ATenantId <= 0 then
    raise Exception.Create(
      'Tenant inválido.'
    );

  if ASuperUser then
  begin
    Result :=
      TUserRepository.ListAll;

    Exit;
  end;

  Result :=
    TUserRepository.List(
      ATenantId
    );
end;

//***************************************
//* GETBYUUID
//***************************************
class function TUserService.GetByUuid(
  const AUserUuid: string;
  const ATenantId: Int64;
  const ASuperUser: Boolean
): string;
begin
  if Trim(AUserUuid) = '' then
    raise Exception.Create(
      'UUID do usuário é obrigatório.'
    );

  if ATenantId <= 0 then
    raise Exception.Create(
      'Tenant inválido.'
    );

  if ASuperUser then
  begin
    Result :=
      TUserRepository.GetByUuidGlobal(
        AUserUuid
      );

    Exit;
  end;

  Result :=
    TUserRepository.GetByUuid(
      AUserUuid,
      ATenantId
    );
end;

//***************************************
//* CREATE
//***************************************
class function TUserService.Create(
  const ACurrentTenantId: Int64;
  const ATargetTenantId: Int64;
  const ALoginId: string;
  const AFirstName: string;
  const AMiddleName: string;
  const ALastName: string;
  const AEmail: string;
  const APassword: string;
  const AStatus: string;
  const ASuperUser: Boolean;
  const ACurrentSuperUser: Boolean
): string;
var
  LStatus: string;
  LLoginId: string;
  LEmail: string;
  LPasswordHash: string;
begin
  if ACurrentTenantId <= 0 then
    raise Exception.Create('Tenant atual inválido.');

  if ATargetTenantId <= 0 then
    raise Exception.Create('Tenant do usuário é obrigatório.');

  LLoginId := Trim(ALoginId);
  LEmail := LowerCase(Trim(AEmail));
  LStatus := UpperCase(Trim(AStatus));

  if LLoginId = '' then
    raise Exception.Create('Login é obrigatório.');

  if Length(LLoginId) > 50 then
    raise Exception.Create('Login deve possuir no máximo 50 caracteres.');

  if Trim(AFirstName) = '' then
    raise Exception.Create('Nome é obrigatório.');

  if Length(Trim(AFirstName)) > 80 then
    raise Exception.Create('Nome deve possuir no máximo 80 caracteres.');

  if Trim(ALastName) = '' then
    raise Exception.Create('Sobrenome é obrigatório.');

  if Length(Trim(ALastName)) > 80 then
    raise Exception.Create(
      'Sobrenome deve possuir no máximo 80 caracteres.'
    );

  if LEmail = '' then
    raise Exception.Create('E-mail é obrigatório.');

  if Length(LEmail) > 150 then
    raise Exception.Create(
      'E-mail deve possuir no máximo 150 caracteres.'
    );

  if APassword = '' then
    raise Exception.Create('Senha é obrigatória.');

  LPasswordHash := HashPassword(APassword);

  if not (
    (LStatus = 'ACTIVE') or
    (LStatus = 'INACTIVE') or
    (LStatus = 'LOCKED')
  ) then
    raise Exception.Create(
      'Status inválido. Valores permitidos: ACTIVE, INACTIVE ou LOCKED.'
    );

    {
      Somente SuperUser possui alcance GLOBAL.

      Administradores e usuários de tenant ficam restritos
      ao próprio tenant.
    }
    if (ACurrentTenantId <> ATargetTenantId) and
       (not ACurrentSuperUser) then
      raise Exception.Create(
        'O usuário somente pode ser criado no próprio tenant.'
      );

    if ASuperUser and
       (not ACurrentSuperUser) then
      raise Exception.Create(
        'Somente um SuperUser pode criar outro usuário SuperUser.'
      );

    {
      SuperUser pertence exclusivamente ao tenant MASTER.

      A validação é feita sobre o tenant do usuário que está
      sendo criado, e não sobre o tenant do usuário autenticado.
    }
    if ASuperUser and
       (not TTenantRepository.IsMaster(ATargetTenantId)) then
      raise Exception.Create(
        'Usuários SuperUser somente podem pertencer ao tenant MASTER.'
      );

  {
    Login é globalmente único.
  }
  if TUserRepository.LoginExists(LLoginId, '') then
    raise Exception.Create(
      'O login informado já está sendo utilizado.'
    );

  {
    E-mail é único dentro do tenant.
  }
  if TUserRepository.EmailExists(
    ATargetTenantId,
    LEmail,
    ''
  ) then
    raise Exception.Create(
      'O e-mail informado já está sendo utilizado neste tenant.'
    );

  Result := TUserRepository.Create(
    ATargetTenantId,
    LLoginId,
    Trim(AFirstName),
    Trim(AMiddleName),
    Trim(ALastName),
    LEmail,
    LPasswordHash,
    LStatus,
    ASuperUser
  );
end;

//***************************************
//* UPDATE
//***************************************
class function TUserService.Update(
  const ACurrentTenantId: Int64;
  const AUserUuid: string;
  const ALoginId: string;
  const AFirstName: string;
  const AMiddleName: string;
  const ALastName: string;
  const AEmail: string;
  const APassword: string;
  const AStatus: string;
  const ASuperUser: Boolean;
  const ACurrentSuperUser: Boolean
): string;
var
  LExistingUser: string;
  LStatus: string;
  LLoginId: string;
  LEmail: string;
  LTargetTenantId: Int64;
  LJson: TJSONValue;
  LPasswordHash: string;
begin
  if ACurrentTenantId <= 0 then
    raise Exception.Create(
      'Tenant atual inválido.'
    );

  if Trim(AUserUuid) = '' then
    raise Exception.Create(
      'UUID do usuário é obrigatório.'
    );

  LLoginId :=
    Trim(ALoginId);

  LEmail :=
    LowerCase(
      Trim(AEmail)
    );

  LStatus :=
    UpperCase(
      Trim(AStatus)
    );

  if LLoginId = '' then
    raise Exception.Create(
      'Login é obrigatório.'
    );

  if Length(LLoginId) > 50 then
    raise Exception.Create(
      'Login deve possuir no máximo 50 caracteres.'
    );

  if Trim(AFirstName) = '' then
    raise Exception.Create(
      'Nome é obrigatório.'
    );

  if Trim(ALastName) = '' then
    raise Exception.Create(
      'Sobrenome é obrigatório.'
    );

  if LEmail = '' then
    raise Exception.Create(
      'E-mail é obrigatório.'
    );

  if not (
    (LStatus = 'ACTIVE') or
    (LStatus = 'INACTIVE') or
    (LStatus = 'LOCKED')
  ) then
    raise Exception.Create(
      'Status inválido. Valores permitidos: ACTIVE, INACTIVE ou LOCKED.'
    );

  {
    SuperUser pode localizar usuários globalmente.

    Administradores e usuários normais somente podem
    localizar usuários dentro do próprio tenant.
  }
  if ACurrentSuperUser then
  begin
    LExistingUser :=
      TUserRepository.GetByUuidGlobal(
        AUserUuid
      );
  end
  else
  begin
    LExistingUser :=
      TUserRepository.GetByUuid(
        AUserUuid,
        ACurrentTenantId
      );
  end;

  if LExistingUser = '' then
    raise Exception.Create(
      'Usuário não encontrado.'
    );

  {
    Descobrimos o tenant real do usuário alvo.
  }
  LJson :=
    TJSONObject.ParseJSONValue(
      LExistingUser
    );

  try
    if not Assigned(LJson) then
      raise Exception.Create(
        'Não foi possível obter os dados atuais do usuário.'
      );

    if not (LJson is TJSONObject) then
      raise Exception.Create(
        'Resposta inválida ao consultar o usuário.'
      );

    LTargetTenantId :=
      TJSONObject(LJson)
        .GetValue<Int64>(
          'tenant_id'
        );

  finally
    LJson.Free;
  end;

  {
    Proteção adicional.

    Mesmo tendo usado GetByUuid filtrado pelo tenant para
    usuários normais, mantemos a regra explícita no Service.
  }
  if (LTargetTenantId <> ACurrentTenantId) and
     (not ACurrentSuperUser) then
    raise Exception.Create(
      'O usuário pertence a outro tenant.'
    );

  {
    SuperUser somente pode existir no tenant MASTER.

    A validação deve considerar o tenant do usuário que
    está sendo alterado.
  }
  if ASuperUser and
     (not TTenantRepository.IsMaster(LTargetTenantId)) then
    raise Exception.Create(
      'Usuários SuperUser somente podem pertencer ao tenant MASTER.'
    );

  if TUserRepository.LoginExists(
    LLoginId,
    AUserUuid
  ) then
    raise Exception.Create(
      'O login informado já está sendo utilizado.'
    );

  if TUserRepository.EmailExists(
    LTargetTenantId,
    LEmail,
    AUserUuid
  ) then
    raise Exception.Create(
      'O e-mail informado já está sendo utilizado neste tenant.'
    );

  {
    Senha vazia significa manter o hash existente.
  }
  LPasswordHash := '';

  if Trim(APassword) <> '' then
    LPasswordHash :=
      HashPassword(
        APassword
      );

  Result :=
    TUserRepository.Update(
      AUserUuid,
      LTargetTenantId,
      LLoginId,
      Trim(AFirstName),
      Trim(AMiddleName),
      Trim(ALastName),
      LEmail,
      LPasswordHash,
      LStatus,
      ASuperUser
    );
end;

//***************************************
//* SOFT DELETE
//***************************************
class function TUserService.Delete(
  const ACurrentTenantId: Int64;
  const AUserUuid: string;
  const ACurrentSuperUser: Boolean
): Boolean;
var
  LUserJson: string;
  LJson: TJSONValue;
  LUserTenantId: Int64;
  LIsSuperUser: Boolean;
begin
  if ACurrentTenantId <= 0 then
    raise Exception.Create(
      'Tenant atual inválido.'
    );

  if Trim(AUserUuid) = '' then
    raise Exception.Create(
      'UUID do usuário é obrigatório.'
    );

  {
    SuperUser possui alcance GLOBAL.

    Administradores e usuários normais ficam
    restritos ao próprio tenant.
  }
  if ACurrentSuperUser then
  begin
    LUserJson :=
      TUserRepository.GetByUuidGlobal(
        AUserUuid
      );
  end
  else
  begin
    LUserJson :=
      TUserRepository.GetByUuid(
        AUserUuid,
        ACurrentTenantId
      );
  end;

  if LUserJson = '' then
    raise Exception.Create(
      'Usuário não encontrado.'
    );

  LJson :=
    TJSONObject.ParseJSONValue(
      LUserJson
    );

  try
    if not Assigned(LJson) then
      raise Exception.Create(
        'Não foi possível obter os dados atuais do usuário.'
      );

    if not (LJson is TJSONObject) then
      raise Exception.Create(
        'Resposta inválida ao consultar o usuário.'
      );

    LUserTenantId :=
      TJSONObject(LJson)
        .GetValue<Int64>(
          'tenant_id'
        );

    LIsSuperUser :=
      TJSONObject(LJson)
        .GetValue<Boolean>(
          'super_user'
        );

  finally
    LJson.Free;
  end;

  {
    Proteção adicional contra acesso entre tenants.
  }
  if (LUserTenantId <> ACurrentTenantId) and
     (not ACurrentSuperUser) then
    raise Exception.Create(
      'O usuário pertence a outro tenant.'
    );

  {
    O SuperUser é uma conta especial do MASTER.

    Sua exclusão lógica continua bloqueada
    neste fluxo.
  }
  if LIsSuperUser then
    raise Exception.Create(
      'Um usuário SuperUser não pode ser excluído através desta operação.'
    );

  Result :=
    TUserRepository.Delete(
      AUserUuid,
      LUserTenantId
    );

  if not Result then
    raise Exception.Create(
      'Não foi possível excluir o usuário.'
    );
end;

end.
