unit uEntityService;

interface

type
  TEntityService = class
  private
    class function IsGlobalScope(
      const ASuperUser: Boolean;
      const AScope: string
    ): Boolean; static;

  public
    class function List(
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string
    ): string;

    class function GetByUuid(
      const AEntityUuid: string;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      out AValidUuid: Boolean
    ): string;

    class function Create(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATargetTenantID: Int64;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      out AErrorMessage: string
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      out AValidUuid: Boolean;
      out AErrorMessage: string
    ): string;

    class function Delete(
      const AEntityUuid: string;
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      out AValidUuid: Boolean
    ): Boolean;

    class function HardDelete(
      const AEntityUuid: string;
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      out AValidUuid: Boolean;
      out AHasDependencies: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  uEntityRepository;


//***************************************
//* IS GLOBAL SCOPE
//***************************************
class function TEntityService.IsGlobalScope(
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
//* LIST
//***************************************
class function TEntityService.List(
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string
): string;
var
  GlobalScope: Boolean;
begin
  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  Result :=
    TEntityRepository.List(
      ATenantID,
      GlobalScope
    );
end;


//***************************************
//* GET BY UUID
//***************************************
class function TEntityService.GetByUuid(
  const AEntityUuid: string;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  out AValidUuid: Boolean
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;
  GlobalScope: Boolean;
begin
  AValidUuid := False;
  Result := '';

  NormalizedUuid :=
    Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid :=
      '{' + NormalizedUuid + '}';

  try
    UUID :=
      StringToGUID(
        NormalizedUuid
      );

    AValidUuid := True;

  except
    on E: EConvertError do
      Exit;
  end;

  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  Result :=
    TEntityRepository.GetByUuid(
      GUIDToString(UUID),
      ATenantID,
      GlobalScope
    );
end;


//***************************************
//* CREATE
//***************************************
class function TEntityService.Create(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATargetTenantID: Int64;
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  out AErrorMessage: string
): string;
var
  EntityType: string;
  LegalName: string;
  GlobalScope: Boolean;
  EffectiveTenantID: Int64;
begin
  Result := '';
  AErrorMessage := '';

  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  //***************************************
  //* DEFINE O TENANT DE DESTINO
  //***************************************
  if GlobalScope then
  begin
    if ATargetTenantID <= 0 then
    begin
      AErrorMessage :=
        'tenant_id é obrigatório para criação de entidade em escopo GLOBAL.';
      Exit;
    end;

    EffectiveTenantID :=
      ATargetTenantID;
  end
  else
  begin
    // Usuário normal sempre cria
    // dentro do próprio tenant.
    EffectiveTenantID :=
      ATenantID;
  end;

  //***************************************
  //* VALIDAÇÕES
  //***************************************
  EntityType :=
    UpperCase(
      Trim(AEntityType)
    );

  LegalName :=
    Trim(ALegalName);

  if (EntityType <> 'COMPANY') and
     (EntityType <> 'INDIVIDUAL') then
  begin
    AErrorMessage :=
      'entity_type deve ser COMPANY ou INDIVIDUAL.';
    Exit;
  end;

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TEntityRepository.Create(
      AUserID,
      EffectiveTenantID,
      Trim(AEntityType),
      Trim(ATaxId),
      Trim(ALegalName),
      Trim(ATradeName),
      Trim(AStateRegistration),
      Trim(AMunicipalRegistration),
      AIsCustomer,
      AIsSupplier,
      Trim(AEmail),
      Trim(APhone),
      Trim(AMobilePhone)
    );
end;


//***************************************
//* UPDATE
//***************************************
class function TEntityService.Update(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  out AValidUuid: Boolean;
  out AErrorMessage: string
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;
  EntityType: string;
  LegalName: string;
  GlobalScope: Boolean;
begin
  Result := '';
  AValidUuid := False;
  AErrorMessage := '';

  NormalizedUuid :=
    Trim(AEntityUuid);

  if NormalizedUuid = '' then
  begin
    AErrorMessage :=
      'UUID da entidade não informado.';
    Exit;
  end;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid :=
      '{' + NormalizedUuid + '}';

  try
    UUID :=
      StringToGUID(
        NormalizedUuid
      );

    AValidUuid := True;

  except
    on E: EConvertError do
    begin
      AErrorMessage :=
        'UUID da entidade inválido.';
      Exit;
    end;
  end;

  //***************************************
  //* VALIDAÇÕES
  //***************************************
  EntityType :=
    UpperCase(
      Trim(AEntityType)
    );

  LegalName :=
    Trim(ALegalName);

  if (EntityType <> 'COMPANY') and
     (EntityType <> 'INDIVIDUAL') then
  begin
    AErrorMessage :=
      'entity_type deve ser COMPANY ou INDIVIDUAL.';
    Exit;
  end;

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TEntityRepository.Update(
      AUserID,
      ATenantID,
      GlobalScope,
      GUIDToString(UUID),
      AEntityType,
      ATaxId,
      ALegalName,
      ATradeName,
      AStateRegistration,
      AMunicipalRegistration,
      AIsCustomer,
      AIsSupplier,
      AEmail,
      APhone,
      AMobilePhone
    );
end;


//***************************************
//* SOFT DELETE
//***************************************
class function TEntityService.Delete(
  const AEntityUuid: string;
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  out AValidUuid: Boolean
): Boolean;
var
  UUID: TGUID;
  NormalizedUuid: string;
  GlobalScope: Boolean;
begin
  Result := False;
  AValidUuid := False;

  NormalizedUuid :=
    Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid :=
      '{' + NormalizedUuid + '}';

  try
    UUID :=
      StringToGUID(
        NormalizedUuid
      );

    AValidUuid := True;

  except
    on E: EConvertError do
      Exit;
  end;

  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  Result :=
    TEntityRepository.Delete(
      AUserID,
      ATenantID,
      GlobalScope,
      GUIDToString(UUID)
    );
end;


//***************************************
//* HARD DELETE
//***************************************
class function TEntityService.HardDelete(
  const AEntityUuid: string;
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  out AValidUuid: Boolean;
  out AHasDependencies: Boolean
): Boolean;
var
  UUID: TGUID;
  NormalizedUuid: string;
  GlobalScope: Boolean;
begin
  Result := False;
  AValidUuid := False;
  AHasDependencies := False;

  NormalizedUuid :=
    Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid :=
      '{' + NormalizedUuid + '}';

  try
    UUID :=
      StringToGUID(
        NormalizedUuid
      );

    AValidUuid := True;

  except
    on E: EConvertError do
      Exit;
  end;

  GlobalScope :=
    IsGlobalScope(
      ASuperUser,
      AScope
    );

  Result :=
    TEntityRepository.HardDelete(
      AUserID,
      ATenantID,
      GlobalScope,
      GUIDToString(UUID),
      AHasDependencies
    );
end;

end.
