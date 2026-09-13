unit uTenantService;

interface

type
  TTenantService = class
  public
    class function List: string;

    class function GetByUuid(
      const ATenantUuid: string;
      out AValidUuid: Boolean
    ): string;

    class function Create(
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
      const AIsMaster: Boolean;
      out AErrorMessage: string
    ): string;

    class function Update(
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
      const AStatus: string;
      const AIsMaster: Boolean;
      out AErrorMessage: string
    ): string;

    class function Delete(
      const ATenantUuid: string;
      out AValidUuid: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  uTenantRepository;

{***************************************}
{* LIST }
{***************************************}
class function TTenantService.List: string;
begin
  Result := TTenantRepository.List;
end;

{***************************************}
{* GETBYUUID }
{***************************************}
class function TTenantService.GetByUuid(
  const ATenantUuid: string;
  out AValidUuid: Boolean
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;
begin
  AValidUuid := False;
  Result := '';

  NormalizedUuid := Trim(ATenantUuid);

  if NormalizedUuid = '' then
    Exit;

  if (NormalizedUuid[1] <> '{') then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
      Exit;
  end;

  Result := TTenantRepository.GetByUuid(
    GUIDToString(UUID)
  );
end;

{***************************************}
{* CREATE }
{***************************************}
class function TTenantService.Create(
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
  const AIsMaster: Boolean;
  out AErrorMessage: string
): string;
var
  LegalName: string;
  TaxId: string;
  Timezone: string;
  CurrencyCode: string;
  LocaleCode: string;
  Status: string;
begin
  Result := '';
  AErrorMessage := '';

  LegalName := Trim(ALegalName);
  TaxId := Trim(ATaxId);
  Timezone := Trim(ATimezone);
  CurrencyCode := UpperCase(Trim(ACurrencyCode));
  LocaleCode := Trim(ALocaleCode);
  Status := UpperCase(Trim(AStatus));

  {---------------------------------------}
  {* Campos obrigatórios }
  {---------------------------------------}

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  if TaxId = '' then
  begin
    AErrorMessage :=
      'tax_id é obrigatório.';
    Exit;
  end;

  {---------------------------------------}
  {* Valores padrão }
  {---------------------------------------}

  if Timezone = '' then
    Timezone := 'America/Sao_Paulo';

  if CurrencyCode = '' then
    CurrencyCode := 'BRL';

  if LocaleCode = '' then
    LocaleCode := 'pt-BR';

  if Status = '' then
    Status := 'ACTIVE';

  {---------------------------------------}
  {* Validação de status }
  {---------------------------------------}

  if (Status <> 'ACTIVE') and
     (Status <> 'INACTIVE') and
     (Status <> 'SUSPENDED') then
  begin
    AErrorMessage :=
      'status deve ser ACTIVE, INACTIVE ou SUSPENDED.';
    Exit;
  end;

  {---------------------------------------}
  {* Validação de tax_id duplicado }
  {---------------------------------------}

  if TTenantRepository.TaxIdExists(
       TaxId,
       ''
     ) then
  begin
    AErrorMessage :=
      'O tax_id informado já está cadastrado em outro tenant.';
    Exit;
  end;

  {---------------------------------------}
  {* Validação de tenant MASTER }
  {---------------------------------------}

  if AIsMaster and
     TTenantRepository.MasterExists('') then
  begin
    AErrorMessage :=
      'Já existe um tenant MASTER. Não é possível criar outro tenant MASTER.';
    Exit;
  end;

  {---------------------------------------}
  {* Persistência }
  {---------------------------------------}

  Result := TTenantRepository.Create(
    LegalName,
    Trim(ATradeName),
    TaxId,
    Trim(AStateRegistration),
    Trim(AMunicipalRegistration),
    Trim(AEmail),
    Trim(APhone),
    Trim(AMobilePhone),
    Trim(AWebsiteUrl),
    Trim(ALogoUrl),
    Timezone,
    CurrencyCode,
    LocaleCode,
    Status,
    AIsMaster
  );
end;

{***************************************}
{* UPDATE }
{***************************************}
class function TTenantService.Update(
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
  const AStatus: string;
  const AIsMaster: Boolean;
  out AErrorMessage: string
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;

  LegalName: string;
  TradeName: string;
  TaxId: string;
  StateRegistration: string;
  MunicipalRegistration: string;
  Email: string;
  Phone: string;
  MobilePhone: string;
  WebsiteUrl: string;
  LogoUrl: string;
  Timezone: string;
  CurrencyCode: string;
  LocaleCode: string;
  Status: string;
begin
  Result := '';
  AErrorMessage := '';

  {---------------------------------------}
  {* Validação e normalização do UUID }
  {---------------------------------------}

  NormalizedUuid := Trim(ATenantUuid);

  if NormalizedUuid = '' then
  begin
    AErrorMessage :=
      'UUID do tenant é obrigatório.';
    Exit;
  end;

  if (NormalizedUuid[1] <> '{') then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
  except
    on E: EConvertError do
    begin
      AErrorMessage :=
        'UUID do tenant inválido.';
      Exit;
    end;
  end;

  NormalizedUuid := GUIDToString(UUID);

  {---------------------------------------}
  {* Normalização dos campos }
  {---------------------------------------}

  LegalName := Trim(ALegalName);
  TradeName := Trim(ATradeName);
  TaxId := Trim(ATaxId);
  StateRegistration := Trim(AStateRegistration);
  MunicipalRegistration := Trim(AMunicipalRegistration);
  Email := Trim(AEmail);
  Phone := Trim(APhone);
  MobilePhone := Trim(AMobilePhone);
  WebsiteUrl := Trim(AWebsiteUrl);
  LogoUrl := Trim(ALogoUrl);
  Timezone := Trim(ATimezone);
  CurrencyCode := UpperCase(Trim(ACurrencyCode));
  LocaleCode := Trim(ALocaleCode);
  Status := UpperCase(Trim(AStatus));

  {---------------------------------------}
  {* Campos obrigatórios }
  {---------------------------------------}

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  if TaxId = '' then
  begin
    AErrorMessage :=
      'tax_id é obrigatório.';
    Exit;
  end;

  {---------------------------------------}
  {* Valores padrão }
  {---------------------------------------}

  if Timezone = '' then
    Timezone := 'America/Sao_Paulo';

  if CurrencyCode = '' then
    CurrencyCode := 'BRL';

  if LocaleCode = '' then
    LocaleCode := 'pt-BR';

  if Status = '' then
    Status := 'ACTIVE';

  {---------------------------------------}
  {* Validação de status }
  {---------------------------------------}

  if (Status <> 'ACTIVE') and
     (Status <> 'INACTIVE') and
     (Status <> 'SUSPENDED') then
  begin
    AErrorMessage :=
      'status deve ser ACTIVE, INACTIVE ou SUSPENDED.';
    Exit;
  end;

  {---------------------------------------}
  {* Validação de tax_id duplicado }
  {---------------------------------------}

  if TTenantRepository.TaxIdExists(
       TaxId,
       NormalizedUuid
     ) then
  begin
    AErrorMessage :=
      'O tax_id informado já está cadastrado em outro tenant.';
    Exit;
  end;

  {---------------------------------------}
  {* Validação de tenant MASTER }
  {---------------------------------------}

  if AIsMaster and
     TTenantRepository.MasterExists(
       NormalizedUuid
     ) then
  begin
    AErrorMessage :=
      'Já existe outro tenant MASTER. Não é possível definir este tenant como MASTER.';
    Exit;
  end;

  {---------------------------------------}
  {* Persistência }
  {---------------------------------------}

  Result := TTenantRepository.Update(
    NormalizedUuid,
    LegalName,
    TradeName,
    TaxId,
    StateRegistration,
    MunicipalRegistration,
    Email,
    Phone,
    MobilePhone,
    WebsiteUrl,
    LogoUrl,
    Timezone,
    CurrencyCode,
    LocaleCode,
    Status,
    AIsMaster
  );
end;

{***************************************}
{* DELETE }
{***************************************}
class function TTenantService.Delete(
  const ATenantUuid: string;
  out AValidUuid: Boolean
): Boolean;
var
  UUID: TGUID;
  NormalizedUuid: string;
begin
  Result := False;
  AValidUuid := False;

  NormalizedUuid := Trim(ATenantUuid);

  if NormalizedUuid = '' then
    Exit;

  if (NormalizedUuid[1] <> '{') then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
      Exit;
  end;

  NormalizedUuid := GUIDToString(UUID);

  Result := TTenantRepository.Delete(
    NormalizedUuid
  );
end;

end.
