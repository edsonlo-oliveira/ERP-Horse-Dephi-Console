unit uTenantRepository;

interface

type
  TTenantRepository = class
  public
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
      const AIsMaster: Boolean
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
      const AIsMaster: Boolean
    ): string;

    class function List: string;
    class function GetByUuid(const ATenantUuid: string): string;
    class function Delete(const ATenantUuid: string): Boolean;
    class function MasterExists(const ATenantUuid: string): Boolean;
    class function TaxIdExists(const ATaxId: string; const ATenantUuid: string): Boolean;
  end;


implementation

uses
  System.SysUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uApiDatabase;

//***************************************
//* LIST
//***************************************
class function TTenantRepository.List: string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
begin
  Result := '';

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  JsonArray := TJSONArray.Create;
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'SELECT ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at, ' +
      '  is_master ' +
      'FROM core.tenants ' +
      'WHERE deleted_at IS NULL ' +
      'ORDER BY legal_name';

      Query.Open;

      while not Query.Eof do
      begin
        JsonObject := TJSONObject.Create;

        JsonObject.AddPair(
          'tenant_id',
          TJSONNumber.Create(Query.FieldByName('tenant_id').AsLargeInt)
        );

        JsonObject.AddPair(
          'tenant_uuid',
          Query.FieldByName('tenant_uuid').AsString
        );

        JsonObject.AddPair(
          'legal_name',
          Query.FieldByName('legal_name').AsString
        );

        if Query.FieldByName('trade_name').IsNull then
          JsonObject.AddPair('trade_name', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'trade_name',
            Query.FieldByName('trade_name').AsString
          );

        JsonObject.AddPair(
          'tax_id',
          Query.FieldByName('tax_id').AsString
        );

        if Query.FieldByName('state_registration').IsNull then
          JsonObject.AddPair('state_registration', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'state_registration',
            Query.FieldByName('state_registration').AsString
          );

        if Query.FieldByName('municipal_registration').IsNull then
          JsonObject.AddPair('municipal_registration', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'municipal_registration',
            Query.FieldByName('municipal_registration').AsString
          );

        if Query.FieldByName('email').IsNull then
          JsonObject.AddPair('email', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'email',
            Query.FieldByName('email').AsString
          );

        if Query.FieldByName('phone').IsNull then
          JsonObject.AddPair('phone', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'phone',
            Query.FieldByName('phone').AsString
          );

        if Query.FieldByName('mobile_phone').IsNull then
          JsonObject.AddPair('mobile_phone', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'mobile_phone',
            Query.FieldByName('mobile_phone').AsString
          );

        if Query.FieldByName('website_url').IsNull then
          JsonObject.AddPair('website_url', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'website_url',
            Query.FieldByName('website_url').AsString
          );

        if Query.FieldByName('logo_url').IsNull then
          JsonObject.AddPair('logo_url', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'logo_url',
            Query.FieldByName('logo_url').AsString
          );

        JsonObject.AddPair(
          'timezone',
          Query.FieldByName('timezone').AsString
        );

        JsonObject.AddPair(
          'currency_code',
          Query.FieldByName('currency_code').AsString
        );

        JsonObject.AddPair(
          'locale_code',
          Query.FieldByName('locale_code').AsString
        );

        JsonObject.AddPair(
          'status',
          Query.FieldByName('status').AsString
        );

        JsonObject.AddPair(
          'created_at',
          Query.FieldByName('created_at').AsString
        );

        JsonObject.AddPair(
          'updated_at',
          Query.FieldByName('updated_at').AsString
        );

        if Query.FieldByName('deleted_at').IsNull then
          JsonObject.AddPair('deleted_at', TJSONNull.Create)
        else
          JsonObject.AddPair(
            'deleted_at',
            Query.FieldByName('deleted_at').AsString
          );

        JsonObject.AddPair(
          'is_master',
          TJSONBool.Create(
            Query.FieldByName('is_master').AsBoolean
          )
        );

        JsonArray.AddElement(JsonObject);

        Query.Next;
      end;

      Result := JsonArray.ToJSON;
  finally
    JsonArray.Free;
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* GETBYUUID
//***************************************
class function TTenantRepository.GetByUuid(const ATenantUuid: string): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  NormalizedUuid: string;
begin
  Result := '';

  NormalizedUuid := Trim(ATenantUuid);
  NormalizedUuid := StringReplace(NormalizedUuid, '{', '', [rfReplaceAll]);
  NormalizedUuid := StringReplace(NormalizedUuid, '}', '', [rfReplaceAll]);

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'SELECT ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at, ' +
      '  is_master ' +
      'FROM core.tenants ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
      '  AND deleted_at IS NULL';

    Query.ParamByName('tenant_uuid').AsString := NormalizedUuid;

    Query.Open;

    if Query.Eof then
      Exit;

    JsonObject := TJSONObject.Create;
    try
      JsonObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(Query.FieldByName('tenant_id').AsLargeInt)
      );

      JsonObject.AddPair(
        'tenant_uuid',
        Query.FieldByName('tenant_uuid').AsString
      );

      JsonObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JsonObject.AddPair('trade_name', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      JsonObject.AddPair(
        'tax_id',
        Query.FieldByName('tax_id').AsString
      );

      if Query.FieldByName('state_registration').IsNull then
        JsonObject.AddPair('state_registration', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JsonObject.AddPair('municipal_registration', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      if Query.FieldByName('email').IsNull then
        JsonObject.AddPair('email', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JsonObject.AddPair('phone', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JsonObject.AddPair('mobile_phone', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      if Query.FieldByName('website_url').IsNull then
        JsonObject.AddPair('website_url', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'website_url',
          Query.FieldByName('website_url').AsString
        );

      if Query.FieldByName('logo_url').IsNull then
        JsonObject.AddPair('logo_url', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'logo_url',
          Query.FieldByName('logo_url').AsString
        );

      JsonObject.AddPair(
        'timezone',
        Query.FieldByName('timezone').AsString
      );

      JsonObject.AddPair(
        'currency_code',
        Query.FieldByName('currency_code').AsString
      );

      JsonObject.AddPair(
        'locale_code',
        Query.FieldByName('locale_code').AsString
      );

      JsonObject.AddPair(
        'status',
        Query.FieldByName('status').AsString
      );

      JsonObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JsonObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JsonObject.AddPair('deleted_at', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      JsonObject.AddPair(
        'is_master',
        TJSONBool.Create(
          Query.FieldByName('is_master').AsBoolean
        )
      );

      Result := JsonObject.ToJSON;

    finally
      JsonObject.Free;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* CREATE
//***************************************
class function TTenantRepository.Create(
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
const AIsMaster: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
begin
  Result := '';

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;
    Query.SQL.Text :=
      'INSERT INTO core.tenants (' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  is_master' +
      ') VALUES (' +
      '  :legal_name, ' +
      '  :trade_name, ' +
      '  :tax_id, ' +
      '  :state_registration, ' +
      '  :municipal_registration, ' +
      '  :email, ' +
      '  :phone, ' +
      '  :mobile_phone, ' +
      '  :website_url, ' +
      '  :logo_url, ' +
      '  :timezone, ' +
      '  :currency_code, ' +
      '  :locale_code, ' +
      '  :status, ' +
      '  :is_master' +
      ') RETURNING ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at, ' +
      '  is_master';

     // ---------------------------------------------------------
    // Define explicitamente os tipos dos parâmetros
    // ---------------------------------------------------------
    Query.ParamByName('legal_name').DataType := ftString;
    Query.ParamByName('trade_name').DataType := ftString;
    Query.ParamByName('tax_id').DataType := ftString;
    Query.ParamByName('state_registration').DataType := ftString;
    Query.ParamByName('municipal_registration').DataType := ftString;
    Query.ParamByName('email').DataType := ftString;
    Query.ParamByName('phone').DataType := ftString;
    Query.ParamByName('mobile_phone').DataType := ftString;
    Query.ParamByName('website_url').DataType := ftString;
    Query.ParamByName('logo_url').DataType := ftString;
    Query.ParamByName('timezone').DataType := ftString;
    Query.ParamByName('currency_code').DataType := ftString;
    Query.ParamByName('locale_code').DataType := ftString;
    Query.ParamByName('status').DataType := ftString;
    Query.ParamByName('is_master').DataType := ftBoolean;

    // ---------------------------------------------------------
    // Valores dos parâmetros
    // ---------------------------------------------------------
    Query.ParamByName('legal_name').AsString :=
      Trim(ALegalName);

    Query.ParamByName('tax_id').AsString :=
      Trim(ATaxId);

    if Trim(ATradeName) = '' then
      Query.ParamByName('trade_name').Clear
    else
      Query.ParamByName('trade_name').AsString :=
        Trim(ATradeName);

    if Trim(AStateRegistration) = '' then
      Query.ParamByName('state_registration').Clear
    else
      Query.ParamByName('state_registration').AsString :=
        Trim(AStateRegistration);

    if Trim(AMunicipalRegistration) = '' then
      Query.ParamByName('municipal_registration').Clear
    else
      Query.ParamByName('municipal_registration').AsString :=
        Trim(AMunicipalRegistration);

    if Trim(AEmail) = '' then
      Query.ParamByName('email').Clear
    else
      Query.ParamByName('email').AsString :=
        Trim(AEmail);

    if Trim(APhone) = '' then
      Query.ParamByName('phone').Clear
    else
      Query.ParamByName('phone').AsString :=
        Trim(APhone);

    if Trim(AMobilePhone) = '' then
      Query.ParamByName('mobile_phone').Clear
    else
      Query.ParamByName('mobile_phone').AsString :=
        Trim(AMobilePhone);

    if Trim(AWebsiteUrl) = '' then
      Query.ParamByName('website_url').Clear
    else
      Query.ParamByName('website_url').AsString :=
        Trim(AWebsiteUrl);

    if Trim(ALogoUrl) = '' then
      Query.ParamByName('logo_url').Clear
    else
      Query.ParamByName('logo_url').AsString :=
        Trim(ALogoUrl);

    Query.ParamByName('timezone').AsString :=
      Trim(ATimezone);

    Query.ParamByName('currency_code').AsString :=
      UpperCase(Trim(ACurrencyCode));

    Query.ParamByName('locale_code').AsString :=
      Trim(ALocaleCode);

    Query.ParamByName('status').AsString :=
      UpperCase(Trim(AStatus));

    Query.ParamByName('is_master').AsBoolean :=
      AIsMaster;

    Query.Open;

    JsonObject := TJSONObject.Create;
    try
      JsonObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(Query.FieldByName('tenant_id').AsLargeInt)
      );

      JsonObject.AddPair(
        'tenant_uuid',
        Query.FieldByName('tenant_uuid').AsString
      );

      JsonObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JsonObject.AddPair('trade_name', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      JsonObject.AddPair(
        'tax_id',
        Query.FieldByName('tax_id').AsString
      );

      if Query.FieldByName('state_registration').IsNull then
        JsonObject.AddPair('state_registration', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JsonObject.AddPair('municipal_registration', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      if Query.FieldByName('email').IsNull then
        JsonObject.AddPair('email', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JsonObject.AddPair('phone', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JsonObject.AddPair('mobile_phone', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      if Query.FieldByName('website_url').IsNull then
        JsonObject.AddPair('website_url', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'website_url',
          Query.FieldByName('website_url').AsString
        );

      if Query.FieldByName('logo_url').IsNull then
        JsonObject.AddPair('logo_url', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'logo_url',
          Query.FieldByName('logo_url').AsString
        );

      JsonObject.AddPair(
        'timezone',
        Query.FieldByName('timezone').AsString
      );

      JsonObject.AddPair(
        'currency_code',
        Query.FieldByName('currency_code').AsString
      );

      JsonObject.AddPair(
        'locale_code',
        Query.FieldByName('locale_code').AsString
      );

      JsonObject.AddPair(
        'status',
        Query.FieldByName('status').AsString
      );

      JsonObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JsonObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JsonObject.AddPair('deleted_at', TJSONNull.Create)
      else
        JsonObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      JsonObject.AddPair(
        'is_master',
        TJSONBool.Create(
          Query.FieldByName('is_master').AsBoolean
        )
      );

      Result := JsonObject.ToJSON;

    finally
      JsonObject.Free;
    end;
  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* UPDATE
//***************************************
class function TTenantRepository.Update(
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
  const AIsMaster: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  NormalizedUuid: string;
begin
  Result := '';

  NormalizedUuid := Trim(ATenantUuid);

  NormalizedUuid := StringReplace(
    NormalizedUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  NormalizedUuid := StringReplace(
    NormalizedUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'UPDATE core.tenants ' +
      'SET ' +
      '  legal_name = :legal_name, ' +
      '  trade_name = :trade_name, ' +
      '  tax_id = :tax_id, ' +
      '  state_registration = :state_registration, ' +
      '  municipal_registration = :municipal_registration, ' +
      '  email = :email, ' +
      '  phone = :phone, ' +
      '  mobile_phone = :mobile_phone, ' +
      '  website_url = :website_url, ' +
      '  logo_url = :logo_url, ' +
      '  timezone = :timezone, ' +
      '  currency_code = :currency_code, ' +
      '  locale_code = :locale_code, ' +
      '  status = :status, ' +
      '  is_master = :is_master, ' +
      '  updated_at = CURRENT_TIMESTAMP ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
      '  AND deleted_at IS NULL ' +
      'RETURNING ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at, ' +
      '  is_master';

    // ---------------------------------------------------------
    // Define explicitamente os tipos dos parâmetros
    // ---------------------------------------------------------
    Query.ParamByName('tenant_uuid').DataType := ftString;
    Query.ParamByName('legal_name').DataType := ftString;
    Query.ParamByName('trade_name').DataType := ftString;
    Query.ParamByName('tax_id').DataType := ftString;
    Query.ParamByName('state_registration').DataType := ftString;
    Query.ParamByName('municipal_registration').DataType := ftString;
    Query.ParamByName('email').DataType := ftString;
    Query.ParamByName('phone').DataType := ftString;
    Query.ParamByName('mobile_phone').DataType := ftString;
    Query.ParamByName('website_url').DataType := ftString;
    Query.ParamByName('logo_url').DataType := ftString;
    Query.ParamByName('timezone').DataType := ftString;
    Query.ParamByName('currency_code').DataType := ftString;
    Query.ParamByName('locale_code').DataType := ftString;
    Query.ParamByName('status').DataType := ftString;
    Query.ParamByName('is_master').DataType := ftBoolean;

    // ---------------------------------------------------------
    // Valores dos parâmetros
    // ---------------------------------------------------------
    Query.ParamByName('tenant_uuid').AsString :=
      NormalizedUuid;

    Query.ParamByName('legal_name').AsString :=
      Trim(ALegalName);

    Query.ParamByName('tax_id').AsString :=
      Trim(ATaxId);

    if Trim(ATradeName) = '' then
      Query.ParamByName('trade_name').Clear
    else
      Query.ParamByName('trade_name').AsString :=
        Trim(ATradeName);

    if Trim(AStateRegistration) = '' then
      Query.ParamByName('state_registration').Clear
    else
      Query.ParamByName('state_registration').AsString :=
        Trim(AStateRegistration);

    if Trim(AMunicipalRegistration) = '' then
      Query.ParamByName('municipal_registration').Clear
    else
      Query.ParamByName('municipal_registration').AsString :=
        Trim(AMunicipalRegistration);

    if Trim(AEmail) = '' then
      Query.ParamByName('email').Clear
    else
      Query.ParamByName('email').AsString :=
        Trim(AEmail);

    if Trim(APhone) = '' then
      Query.ParamByName('phone').Clear
    else
      Query.ParamByName('phone').AsString :=
        Trim(APhone);

    if Trim(AMobilePhone) = '' then
      Query.ParamByName('mobile_phone').Clear
    else
      Query.ParamByName('mobile_phone').AsString :=
        Trim(AMobilePhone);

    if Trim(AWebsiteUrl) = '' then
      Query.ParamByName('website_url').Clear
    else
      Query.ParamByName('website_url').AsString :=
        Trim(AWebsiteUrl);

    if Trim(ALogoUrl) = '' then
      Query.ParamByName('logo_url').Clear
    else
      Query.ParamByName('logo_url').AsString :=
        Trim(ALogoUrl);

    Query.ParamByName('timezone').AsString :=
      Trim(ATimezone);

    Query.ParamByName('currency_code').AsString :=
      UpperCase(Trim(ACurrencyCode));

    Query.ParamByName('locale_code').AsString :=
      Trim(ALocaleCode);

    Query.ParamByName('status').AsString :=
      UpperCase(Trim(AStatus));

    Query.ParamByName('is_master').AsBoolean :=
      AIsMaster;

    // ---------------------------------------------------------
    // Executa o UPDATE
    // ---------------------------------------------------------
    Query.Open;

    if Query.Eof then
      Exit;

    // ---------------------------------------------------------
    // Monta JSON de retorno
    // ---------------------------------------------------------
    JsonObject := TJSONObject.Create;
    try
      JsonObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(
          Query.FieldByName('tenant_id').AsLargeInt
        )
      );

      JsonObject.AddPair(
        'tenant_uuid',
        Query.FieldByName('tenant_uuid').AsString
      );

      JsonObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JsonObject.AddPair(
          'trade_name',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      JsonObject.AddPair(
        'tax_id',
        Query.FieldByName('tax_id').AsString
      );

      if Query.FieldByName('state_registration').IsNull then
        JsonObject.AddPair(
          'state_registration',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JsonObject.AddPair(
          'municipal_registration',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      if Query.FieldByName('email').IsNull then
        JsonObject.AddPair(
          'email',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JsonObject.AddPair(
          'phone',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JsonObject.AddPair(
          'mobile_phone',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      if Query.FieldByName('website_url').IsNull then
        JsonObject.AddPair(
          'website_url',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'website_url',
          Query.FieldByName('website_url').AsString
        );

      if Query.FieldByName('logo_url').IsNull then
        JsonObject.AddPair(
          'logo_url',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'logo_url',
          Query.FieldByName('logo_url').AsString
        );

      JsonObject.AddPair(
        'timezone',
        Query.FieldByName('timezone').AsString
      );

      JsonObject.AddPair(
        'currency_code',
        Query.FieldByName('currency_code').AsString
      );

      JsonObject.AddPair(
        'locale_code',
        Query.FieldByName('locale_code').AsString
      );

      JsonObject.AddPair(
        'status',
        Query.FieldByName('status').AsString
      );

      JsonObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JsonObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JsonObject.AddPair(
          'deleted_at',
          TJSONNull.Create
        )
      else
        JsonObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      JsonObject.AddPair(
        'is_master',
        TJSONBool.Create(
          Query.FieldByName('is_master').AsBoolean
        )
      );

      Result := JsonObject.ToJSON;

    finally
      JsonObject.Free;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* DELETE
//***************************************
class function TTenantRepository.Delete(
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  NormalizedUuid: string;
begin
  NormalizedUuid := Trim(ATenantUuid);
  NormalizedUuid := StringReplace(
    NormalizedUuid,
    '{',
    '',
    [rfReplaceAll]
  );
  NormalizedUuid := StringReplace(
    NormalizedUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'UPDATE core.tenants ' +
      'SET ' +
      '  status = ''INACTIVE'', ' +
      '  deleted_at = CURRENT_TIMESTAMP, ' +
      '  updated_at = CURRENT_TIMESTAMP ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
      '  AND deleted_at IS NULL ' +
      '  AND is_master = FALSE';

    Query.ParamByName('tenant_uuid').AsString := NormalizedUuid;

    Query.ExecSQL;

    Result := Query.RowsAffected > 0;
  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* MASTER EXISTS
//***************************************
class function TTenantRepository.MasterExists(
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
begin
  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.tenants ' +
      '  WHERE is_master = TRUE ' +
      '    AND deleted_at IS NULL ' +
      '    AND (' +
      '      :exclude_uuid = '''' ' +
      '      OR tenant_uuid <> CAST(:exclude_uuid AS uuid)' +
      '    )' +
      ') AS master_exists';

    Query.ParamByName('exclude_uuid').DataType := ftString;
    Query.ParamByName('exclude_uuid').AsString := Trim(ATenantUuid);

    Query.Open;

    Result := Query.FieldByName('master_exists').AsBoolean;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* TAX ID EXISTS
//***************************************
class function TTenantRepository.TaxIdExists(
  const ATaxId: string;
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
begin
  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := Connection;

    Query.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.tenants ' +
      '  WHERE tax_id = :tax_id ' +
      '    AND deleted_at IS NULL ' +
      '    AND (' +
      '      :exclude_uuid = '''' ' +
      '      OR tenant_uuid <> CAST(:exclude_uuid AS uuid)' +
      '    )' +
      ') AS tax_id_exists';

    Query.ParamByName('tax_id').DataType := ftString;
    Query.ParamByName('tax_id').AsString := Trim(ATaxId);

    Query.ParamByName('exclude_uuid').DataType := ftString;
    Query.ParamByName('exclude_uuid').AsString := Trim(ATenantUuid);

    Query.Open;

    Result := Query.FieldByName('tax_id_exists').AsBoolean;

  finally
    Query.Free;
    Connection.Free;
  end;
end;
end.
