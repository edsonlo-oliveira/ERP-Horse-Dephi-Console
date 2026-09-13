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

    class function Delete(const ATenantUuid: string): Boolean;
  end;


implementation

uses
  System.SysUtils,
  System.JSON,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uApiDatabase;

class function TTenantRepository.List: string;
var
  Query: TFDQuery;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
begin
  Result := ‘’;

  Query := TFDQuery.Create(nil);
  JsonArray := TJSONArray.Create;
  try
    Query.Connection := TApiDatabase.Connection;

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
  end;
end;
end.
