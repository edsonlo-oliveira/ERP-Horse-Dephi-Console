unit uTenantService;

interface

type
  TTenantService = class
  private
    class function HasGlobalAccess(
      const ASuperUser: Boolean;
      const AScope: string
    ): Boolean;

    class function IsValidUuid(
      const AValue: string
    ): Boolean;

    class function IsValidStatus(
      const AStatus: string
    ): Boolean;

  public
    class function List(
      const ASuperUser: Boolean;
      const AScope: string;
      const ASearch: string;
      const APage: Integer;
      const APageSize: Integer;
      const ASortField: string;
      const ASortDirection: string;
      out AErrorMessage: string;
      out AForbidden: Boolean
    ): string;

    class function GetByUuid(
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidUuid: Boolean
    ): string;

    class function Create(
      const AUserID: Int64;
      const AAuditTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ALegalName: string;
      const ATradeName: string;
      const ATaxId: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      const AWebsiteUrl: string;
      const ALogoUrl: string;
      const ATimezone: string;
      const ACurrencyCode: string;
      const ALocaleCode: string;
      const AStatus: string;
      out AErrorMessage: string;
      out AForbidden: Boolean
    ): string;

    class function Update(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const ALegalName: string;
      const ATradeName: string;
      const ATaxId: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      const AWebsiteUrl: string;
      const ALogoUrl: string;
      const ATimezone: string;
      const ACurrencyCode: string;
      const ALocaleCode: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidUuid: Boolean
    ): string;

    class function ChangeStatus(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const AStatus: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidUuid: Boolean
    ): Boolean;

    class function Delete(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidUuid: Boolean
    ): Boolean;

    class function HardDelete(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidUuid: Boolean;
      out AHasDependencies: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  uTenantRepository;


//***************************************
//* HAS GLOBAL ACCESS
//***************************************
class function TTenantService.HasGlobalAccess(
  const ASuperUser: Boolean;
  const AScope: string
): Boolean;
begin
  Result :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );
end;


//***************************************
//* IS VALID UUID
//***************************************
class function TTenantService.IsValidUuid(
  const AValue: string
): Boolean;
var
  LValue: string;
begin
  LValue :=
    Trim(AValue);

  LValue :=
    StringReplace(
      LValue,
      '{',
      '',
      [rfReplaceAll]
    );

  LValue :=
    StringReplace(
      LValue,
      '}',
      '',
      [rfReplaceAll]
    );

  Result :=
    TRegEx.IsMatch(
      LValue,
      '^[0-9a-fA-F]{8}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{12}$'
    );
end;


//***************************************
//* IS VALID STATUS
//***************************************
class function TTenantService.IsValidStatus(
  const AStatus: string
): Boolean;
var
  LStatus: string;
begin
  LStatus :=
    UpperCase(
      Trim(AStatus)
    );

  Result :=
    (LStatus = 'ACTIVE') or
    (LStatus = 'INACTIVE') or
    (LStatus = 'SUSPENDED');
end;


//***************************************
//* LIST
//***************************************
class function TTenantService.List(
  const ASuperUser: Boolean;
  const AScope: string;
  const ASearch: string;
  const APage: Integer;
  const APageSize: Integer;
  const ASortField: string;
  const ASortDirection: string;
  out AErrorMessage: string;
  out AForbidden: Boolean
): string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para acessar tenants.';

    Exit;
  end;

  Result :=
    TTenantRepository.List(
      Trim(ASearch),
      APage,
      APageSize,
      Trim(ASortField),
      Trim(ASortDirection)
    );
end;


//***************************************
//* GET BY UUID
//***************************************
class function TTenantService.GetByUuid(
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidUuid: Boolean
): string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  AValidUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para acessar tenants.';

    Exit;
  end;

  Result :=
    TTenantRepository.GetByUuid(
      ATenantUuid,
      False
    );

  if Result = '' then
    AErrorMessage :=
      'Tenant não encontrado.';
end;


//***************************************
//* CREATE
//***************************************
class function TTenantService.Create(
  const AUserID: Int64;
  const AAuditTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ALegalName: string;
  const ATradeName: string;
  const ATaxId: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  const AWebsiteUrl: string;
  const ALogoUrl: string;
  const ATimezone: string;
  const ACurrencyCode: string;
  const ALocaleCode: string;
  const AStatus: string;
  out AErrorMessage: string;
  out AForbidden: Boolean
): string;
var
  LLegalName: string;
  LTaxId: string;
  LTimezone: string;
  LCurrencyCode: string;
  LLocaleCode: string;
  LStatus: string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para criar tenants.';

    Exit;
  end;

  //***************************************
  //* NORMALIZAÇÃO
  //***************************************
  LLegalName :=
    Trim(ALegalName);

  LTaxId :=
    Trim(ATaxId);

  LTimezone :=
    Trim(ATimezone);

  LCurrencyCode :=
    UpperCase(
      Trim(ACurrencyCode)
    );

  LLocaleCode :=
    Trim(ALocaleCode);

  LStatus :=
    UpperCase(
      Trim(AStatus)
    );

  //***************************************
  //* VALIDAÇÕES
  //***************************************
  if LLegalName = '' then
  begin
    AErrorMessage :=
      'Razão social é obrigatória.';

    Exit;
  end;

  if LTaxId = '' then
  begin
    AErrorMessage :=
      'CNPJ/CPF é obrigatório.';

    Exit;
  end;

  if LTimezone = '' then
  begin
    AErrorMessage :=
      'Timezone é obrigatório.';

    Exit;
  end;

  if LCurrencyCode = '' then
  begin
    AErrorMessage :=
      'Código da moeda é obrigatório.';

    Exit;
  end;

  if Length(LCurrencyCode) <> 3 then
  begin
    AErrorMessage :=
      'Código da moeda deve possuir 3 caracteres.';

    Exit;
  end;

  if LLocaleCode = '' then
  begin
    AErrorMessage :=
      'Locale é obrigatório.';

    Exit;
  end;

  if not IsValidStatus(
    LStatus
  ) then
  begin
    AErrorMessage :=
      'Status do tenant inválido.';

    Exit;
  end;

  if TTenantRepository.TaxIdExists(
    LTaxId
  ) then
  begin
    AErrorMessage :=
      'Já existe um tenant cadastrado com este CNPJ/CPF.';

    Exit;
  end;

  Result :=
    TTenantRepository.Create(
      AUserID,
      AAuditTenantID,
      LLegalName,
      Trim(ATradeName),
      LTaxId,
      Trim(AStateRegistration),
      Trim(AMunicipalRegistration),
      Trim(AEmail),
      Trim(APhone),
      Trim(AMobilePhone),
      Trim(AWebsiteUrl),
      Trim(ALogoUrl),
      LTimezone,
      LCurrencyCode,
      LLocaleCode,
      LStatus
    );
end;


//***************************************
//* UPDATE
//***************************************
class function TTenantService.Update(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const ALegalName: string;
  const ATradeName: string;
  const ATaxId: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  const AWebsiteUrl: string;
  const ALogoUrl: string;
  const ATimezone: string;
  const ACurrencyCode: string;
  const ALocaleCode: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidUuid: Boolean
): string;
var
  LLegalName: string;
  LTaxId: string;
  LTimezone: string;
  LCurrencyCode: string;
  LLocaleCode: string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  AValidUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para alterar tenants.';

    Exit;
  end;

  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  // MASTER pode ter seus dados cadastrais
  // alterados. is_master e status não são
  // modificados por este método.

  LLegalName :=
    Trim(ALegalName);

  LTaxId :=
    Trim(ATaxId);

  LTimezone :=
    Trim(ATimezone);

  LCurrencyCode :=
    UpperCase(
      Trim(ACurrencyCode)
    );

  LLocaleCode :=
    Trim(ALocaleCode);

  if LLegalName = '' then
  begin
    AErrorMessage :=
      'Razão social é obrigatória.';

    Exit;
  end;

  if LTaxId = '' then
  begin
    AErrorMessage :=
      'CNPJ/CPF é obrigatório.';

    Exit;
  end;

  if LTimezone = '' then
  begin
    AErrorMessage :=
      'Timezone é obrigatório.';

    Exit;
  end;

  if LCurrencyCode = '' then
  begin
    AErrorMessage :=
      'Código da moeda é obrigatório.';

    Exit;
  end;

  if Length(LCurrencyCode) <> 3 then
  begin
    AErrorMessage :=
      'Código da moeda deve possuir 3 caracteres.';

    Exit;
  end;

  if LLocaleCode = '' then
  begin
    AErrorMessage :=
      'Locale é obrigatório.';

    Exit;
  end;

  if TTenantRepository.TaxIdExists(
    LTaxId,
    ATenantUuid
  ) then
  begin
    AErrorMessage :=
      'Já existe outro tenant cadastrado com este CNPJ/CPF.';

    Exit;
  end;

  Result :=
    TTenantRepository.Update(
      AUserID,
      ATenantUuid,
      LLegalName,
      Trim(ATradeName),
      LTaxId,
      Trim(AStateRegistration),
      Trim(AMunicipalRegistration),
      Trim(AEmail),
      Trim(APhone),
      Trim(AMobilePhone),
      Trim(AWebsiteUrl),
      Trim(ALogoUrl),
      LTimezone,
      LCurrencyCode,
      LLocaleCode
    );

  if Result = '' then
    AErrorMessage :=
      'Tenant não encontrado.';
end;


//***************************************
//* CHANGE STATUS
//***************************************
class function TTenantService.ChangeStatus(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const AStatus: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidUuid: Boolean
): Boolean;
var
  LStatus: string;
begin
  Result := False;
  AErrorMessage := '';
  AForbidden := False;

  AValidUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para alterar o status de tenants.';

    Exit;
  end;

  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* MASTER
  //***************************************
  if TTenantRepository.IsMaster(
    ATenantUuid
  ) then
  begin
    AErrorMessage :=
      'O tenant MASTER não pode ter seu status alterado.';

    Exit;
  end;

  LStatus :=
    UpperCase(
      Trim(AStatus)
    );

  if not IsValidStatus(
    LStatus
  ) then
  begin
    AErrorMessage :=
      'Status do tenant inválido.';

    Exit;
  end;

  Result :=
    TTenantRepository.ChangeStatus(
      AUserID,
      ATenantUuid,
      LStatus
    );

  if not Result then
    AErrorMessage :=
      'Não foi possível alterar o status do tenant.';
end;


//***************************************
//* DELETE
//***************************************
class function TTenantService.Delete(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidUuid: Boolean
): Boolean;
begin
  Result := False;
  AErrorMessage := '';
  AForbidden := False;

  AValidUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para excluir tenants.';

    Exit;
  end;

  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* MASTER
  //***************************************
  if TTenantRepository.IsMaster(
    ATenantUuid
  ) then
  begin
    AErrorMessage :=
      'O tenant MASTER não pode ser excluído.';

    Exit;
  end;

  Result :=
    TTenantRepository.Delete(
      AUserID,
      ATenantUuid
    );

  if not Result then
    AErrorMessage :=
      'Não foi possível excluir o tenant.';
end;


//***************************************
//* HARD DELETE
//***************************************
class function TTenantService.HardDelete(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidUuid: Boolean;
  out AHasDependencies: Boolean
): Boolean;
var
  LActiveExists: Boolean;
  LAnyExists: Boolean;
begin
  Result := False;
  AErrorMessage := '';
  AForbidden := False;
  AHasDependencies := False;

  AValidUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTORIZAÇÃO
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;
    AErrorMessage :=
      'Usuário não possui permissão para excluir definitivamente tenants.';

    Exit;
  end;

  LAnyExists :=
    TTenantRepository.Exists(
      ATenantUuid,
      True
    );

  if not LAnyExists then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* MASTER
  //***************************************
  if TTenantRepository.IsMaster(
    ATenantUuid
  ) then
  begin
    AErrorMessage :=
      'O tenant MASTER não pode ser excluído definitivamente.';

    Exit;
  end;

  //***************************************
  //* SOFT DELETE OBRIGATÓRIO
  //***************************************
  LActiveExists :=
    TTenantRepository.Exists(
      ATenantUuid,
      False
    );

  if LActiveExists then
  begin
    AErrorMessage :=
      'O tenant deve ser excluído logicamente antes da exclusão definitiva.';

    Exit;
  end;

  Result :=
    TTenantRepository.HardDelete(
      AUserID,
      ATenantUuid,
      AHasDependencies
    );

  if AHasDependencies then
  begin
    AErrorMessage :=
      'O tenant possui registros relacionados e não pode ser excluído definitivamente.';

    Exit;
  end;

  if not Result then
    AErrorMessage :=
      'Não foi possível excluir definitivamente o tenant.';
end;

end.
