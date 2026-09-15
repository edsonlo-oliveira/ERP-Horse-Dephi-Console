unit uUserService;

interface

type
  TUserService = class
  public
    class function List(
      const ATenantId: Int64
    ): string;

    class function GetByUuid(
      const AUserUuid: string;
      const ATenantId: Int64
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
      const ACurrentTenantIsMaster: Boolean
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
      const ACurrentTenantIsMaster: Boolean
    ): string;

    class function Delete(
      const ACurrentTenantId: Int64;
      const AUserUuid: string;
      const ACurrentTenantIsMaster: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uUserRepository,
  uPasswordUtils;

//***************************************
//* LIST
//***************************************
class function TUserService.List(
  const ATenantId: Int64
): string;
begin
  if ATenantId <= 0 then
    raise Exception.Create('Tenant inválido.');

  Result := TUserRepository.List(ATenantId);
end;

//***************************************
//* GETBYUUID
//***************************************
class function TUserService.GetByUuid(
  const AUserUuid: string;
  const ATenantId: Int64
): string;
begin
  if ATenantId <= 0 then
    raise Exception.Create('Tenant inválido.');

  if Trim(AUserUuid) = '' then
    raise Exception.Create('UUID do usuário é obrigatório.');

  Result := TUserRepository.GetByUuid(
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
  const ACurrentTenantIsMaster: Boolean
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
    Um usuário normal só pode ser criado dentro do próprio tenant.

    O tenant MASTER pode administrar usuários de outros tenants.
  }
  if (ACurrentTenantId <> ATargetTenantId) and
     (not ACurrentTenantIsMaster) then
    raise Exception.Create(
      'O usuário somente pode ser criado no próprio tenant.'
    );

  {
    SuperUser pertence exclusivamente ao tenant MASTER.
  }
  if ASuperUser and (not ACurrentTenantIsMaster) then
    raise Exception.Create(
      'Somente o tenant MASTER pode possuir usuários SuperUser.'
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
  const ACurrentTenantIsMaster: Boolean
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
    raise Exception.Create('Tenant atual inválido.');

  if Trim(AUserUuid) = '' then
    raise Exception.Create('UUID do usuário é obrigatório.');

  LLoginId := Trim(ALoginId);
  LEmail := LowerCase(Trim(AEmail));
  LStatus := UpperCase(Trim(AStatus));

  if LLoginId = '' then
    raise Exception.Create('Login é obrigatório.');

  if Length(LLoginId) > 50 then
    raise Exception.Create('Login deve possuir no máximo 50 caracteres.');

  if Trim(AFirstName) = '' then
    raise Exception.Create('Nome é obrigatório.');

  if Trim(ALastName) = '' then
    raise Exception.Create('Sobrenome é obrigatório.');

  if LEmail = '' then
    raise Exception.Create('E-mail é obrigatório.');

  if not (
    (LStatus = 'ACTIVE') or
    (LStatus = 'INACTIVE') or
    (LStatus = 'LOCKED')
  ) then
    raise Exception.Create(
      'Status inválido. Valores permitidos: ACTIVE, INACTIVE ou LOCKED.'
    );

  {
    Primeiro localizamos o usuário dentro do tenant atual.
  }
  LExistingUser := TUserRepository.GetByUuid(
    AUserUuid,
    ACurrentTenantId
  );

  if LExistingUser = '' then
  begin
    if not ACurrentTenantIsMaster then
      raise Exception.Create('Usuário não encontrado.');

    raise Exception.Create(
      'Usuário não encontrado no tenant informado.'
    );
  end;

  {
    Descobrimos o tenant do usuário através do JSON retornado.
  }
  LJson := TJSONObject.ParseJSONValue(LExistingUser);
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
        .GetValue<Int64>('tenant_id');

  finally
    LJson.Free;
  end;

  {
    O usuário de outro tenant somente pode ser alterado
    por uma operação realizada pelo MASTER.
  }
  if (LTargetTenantId <> ACurrentTenantId) and
     (not ACurrentTenantIsMaster) then
    raise Exception.Create(
      'O usuário pertence a outro tenant.'
    );

  {
    SuperUser somente pode existir no MASTER.
  }
  if ASuperUser and (not ACurrentTenantIsMaster) then
    raise Exception.Create(
      'Somente o tenant MASTER pode possuir usuários SuperUser.'
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
    A senha é opcional na atualização.
    String vazia significa manter o hash existente.
  }

  LPasswordHash := '';

  if Trim(APassword) <> '' then
    LPasswordHash := HashPassword(APassword);

  Result := TUserRepository.Update(
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
  const ACurrentTenantIsMaster: Boolean
): Boolean;
var
  LUserJson: string;
  LJson: TJSONValue;
  LUserTenantId: Int64;
  LIsSuperUser: Boolean;
begin
  if ACurrentTenantId <= 0 then
    raise Exception.Create('Tenant atual inválido.');

  if Trim(AUserUuid) = '' then
    raise Exception.Create('UUID do usuário é obrigatório.');

  LUserJson := TUserRepository.GetByUuid(
    AUserUuid,
    ACurrentTenantId
  );

  if LUserJson = '' then
  begin
    if not ACurrentTenantIsMaster then
      raise Exception.Create('Usuário não encontrado.');

    raise Exception.Create(
      'Usuário não encontrado no tenant informado.'
    );
  end;

  LJson := TJSONObject.ParseJSONValue(LUserJson);
  try
    if not Assigned(LJson) then
      raise Exception.Create(
        'Não foi possível obter os dados atuais do usuário.'
      );

    LUserTenantId :=
      TJSONObject(LJson)
        .GetValue<Int64>('tenant_id');

    LIsSuperUser :=
      TJSONObject(LJson)
        .GetValue<Boolean>('super_user');

  finally
    LJson.Free;
  end;

  if (LUserTenantId <> ACurrentTenantId) and
     (not ACurrentTenantIsMaster) then
    raise Exception.Create(
      'O usuário pertence a outro tenant.'
    );

  {
    O SuperUser é uma conta especial do MASTER.
    Não permitimos sua exclusão lógica através deste fluxo.
    A regra de manutenção do último SuperUser ficará vinculada
    ao fluxo administrativo específico.
  }
  if LIsSuperUser then
    raise Exception.Create(
      'Um usuário SuperUser não pode ser excluído através desta operação.'
    );

  Result := TUserRepository.Delete(
    AUserUuid,
    LUserTenantId
  );

  if not Result then
    raise Exception.Create(
      'Não foi possível excluir o usuário.'
    );
end;

end.
