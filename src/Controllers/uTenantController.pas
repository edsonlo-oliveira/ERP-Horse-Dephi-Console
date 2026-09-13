unit uTenantController;

interface

uses
  Horse;

type
  TTenantController = class
  public
    class procedure List(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetByUuid(Req: THorseRequest; Res: THorseResponse);
    class procedure Create(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Update(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uTenantService;

{***************************************}
{* LIST }
{***************************************}
class procedure TTenantController.List(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
begin
  try
    Res
      .Status(200)
      .ContentType('application/json')
      .Send(TTenantService.List);
  except
    on E: Exception do
      Res
        .Status(500)
        .ContentType('application/json')
        .Send(
          TJSONObject.Create
            .AddPair('success', TJSONBool.Create(False))
            .AddPair('message', E.Message)
            .ToString
        );
  end;
end;

//***************************************
//* GETBYUUID
//***************************************
class procedure TTenantController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  TenantUuid: string;
  JsonResult: string;
  ValidUuid: Boolean;
begin
  TenantUuid := Trim(
    Req.Params['uuid']
  );

  if TenantUuid = '' then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID do tenant não informado."}'
    );

    Exit;
  end;

  JsonResult := TTenantService.GetByUuid(
    TenantUuid,
    ValidUuid
  );

  if not ValidUuid then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID do tenant inválido."}'
    );

    Exit;
  end;

  if JsonResult = '' then
  begin
    Res.Status(404);

    Res.Send(
      '{"success":false,"message":"Tenant não encontrado."}'
    );

    Exit;
  end;

  Res.ContentType('application/json; charset=utf-8');
  Res.Status(200);
  Res.Send(JsonResult);
end;

//***************************************
//* CREATE
//***************************************
class procedure TTenantController.Create(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  JsonBody: TJSONObject;

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

  IsMaster: Boolean;

  JsonResult: string;
  ErrorMessage: string;
  JsonValue: TJSONValue;
begin
  Res.ContentType('application/json; charset=utf-8');

  JsonBody := nil;

  try
    try
      // ---------------------------------------------------------
      // Converte o corpo da requisição para JSON
      // ---------------------------------------------------------
      JsonBody := TJSONObject.ParseJSONValue(
        Req.Body
      ) as TJSONObject;

      if not Assigned(JsonBody) then
      begin
        Res.Status(400);
        Res.Send(
          '{"success":false,"message":"JSON inválido."}'
        );
        Exit;
      end;

      // ---------------------------------------------------------
      // Valores padrão
      // ---------------------------------------------------------
      LegalName := '';
      TradeName := '';
      TaxId := '';
      StateRegistration := '';
      MunicipalRegistration := '';

      Email := '';
      Phone := '';
      MobilePhone := '';
      WebsiteUrl := '';
      LogoUrl := '';

      Timezone := '';
      CurrencyCode := '';
      LocaleCode := '';
      Status := '';

      IsMaster := False;

      // ---------------------------------------------------------
      // legal_name
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('legal_name');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        LegalName := JsonValue.Value;

      // ---------------------------------------------------------
      // trade_name
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('trade_name');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TradeName := JsonValue.Value;

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('tax_id');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId := JsonValue.Value;

      // ---------------------------------------------------------
      // state_registration
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('state_registration');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        StateRegistration := JsonValue.Value;

      // ---------------------------------------------------------
      // municipal_registration
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('municipal_registration');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MunicipalRegistration := JsonValue.Value;

      // ---------------------------------------------------------
      // email
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('email');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Email := JsonValue.Value;

      // ---------------------------------------------------------
      // phone
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('phone');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Phone := JsonValue.Value;

      // ---------------------------------------------------------
      // mobile_phone
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('mobile_phone');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MobilePhone := JsonValue.Value;

      // ---------------------------------------------------------
      // website_url
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('website_url');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        WebsiteUrl := JsonValue.Value;

      // ---------------------------------------------------------
      // logo_url
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('logo_url');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        LogoUrl := JsonValue.Value;

      // ---------------------------------------------------------
      // timezone
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('timezone');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Timezone := JsonValue.Value;

      // ---------------------------------------------------------
      // currency_code
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('currency_code');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        CurrencyCode := JsonValue.Value;

      // ---------------------------------------------------------
      // locale_code
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('locale_code');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        LocaleCode := JsonValue.Value;

      // ---------------------------------------------------------
      // status
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('status');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Status := JsonValue.Value;

      // ---------------------------------------------------------
      // is_master
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('is_master');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsMaster := SameText(
          JsonValue.Value,
          'true'
        );

      // ---------------------------------------------------------
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult := TTenantService.Create(
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
        IsMaster,
        ErrorMessage
      );

      // ---------------------------------------------------------
      // Erro de validação/business rule
      // ---------------------------------------------------------
      if ErrorMessage <> '' then
      begin
        Res.Status(400);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              ErrorMessage
            )
            .ToJSON
        );

        Exit;
      end;

      // ---------------------------------------------------------
      // Sucesso
      // ---------------------------------------------------------
      Res.Status(201);
      Res.Send(JsonResult);

    except
      on E: Exception do
      begin
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              'Erro interno ao criar tenant: ' + E.Message
            )
            .ToJSON
        );
      end;
    end;

  finally
    JsonBody.Free;
  end;
end;


{***************************************}
{* UPDATE }
{***************************************}
class procedure TTenantController.Update(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  Json: TJSONObject;

  TenantUuid: string;
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

  IsMaster: Boolean;

  JsonResult: string;
  ErrorMessage: string;
begin
  Res.ContentType('application/json; charset=utf-8');

  Json := nil;

  try
    try
      // ---------------------------------------------------------
      // UUID do tenant
      // ---------------------------------------------------------
      TenantUuid := Trim(
        Req.Params['uuid']
      );

      if TenantUuid = '' then
      begin
        Res.Status(400);
        Res.Send(
          '{"success":false,"message":"UUID do tenant não informado."}'
        );
        Exit;
      end;

      // ---------------------------------------------------------
      // Converte o corpo da requisição para JSON
      // ---------------------------------------------------------
      Json := TJSONObject.ParseJSONValue(
        Req.Body
      ) as TJSONObject;

      if not Assigned(Json) then
      begin
        Res.Status(400);
        Res.Send(
          '{"success":false,"message":"JSON inválido."}'
        );
        Exit;
      end;

      // ---------------------------------------------------------
      // Valores padrão
      // ---------------------------------------------------------
      LegalName := '';
      TradeName := '';
      TaxId := '';
      StateRegistration := '';
      MunicipalRegistration := '';

      Email := '';
      Phone := '';
      MobilePhone := '';
      WebsiteUrl := '';
      LogoUrl := '';

      Timezone := '';
      CurrencyCode := '';
      LocaleCode := '';
      Status := '';

      // ---------------------------------------------------------
      // legal_name
      // ---------------------------------------------------------
      LegalName :=
        Json.GetValue<string>(
          'legal_name',
          ''
        );

      // ---------------------------------------------------------
      // trade_name
      // ---------------------------------------------------------
      TradeName :=
        Json.GetValue<string>(
          'trade_name',
          ''
        );

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      TaxId :=
        Json.GetValue<string>(
          'tax_id',
          ''
        );

      // ---------------------------------------------------------
      // state_registration
      // ---------------------------------------------------------
      StateRegistration :=
        Json.GetValue<string>(
          'state_registration',
          ''
        );

      // ---------------------------------------------------------
      // municipal_registration
      // ---------------------------------------------------------
      MunicipalRegistration :=
        Json.GetValue<string>(
          'municipal_registration',
          ''
        );

      // ---------------------------------------------------------
      // email
      // ---------------------------------------------------------
      Email :=
        Json.GetValue<string>(
          'email',
          ''
        );

      // ---------------------------------------------------------
      // phone
      // ---------------------------------------------------------
      Phone :=
        Json.GetValue<string>(
          'phone',
          ''
        );

      // ---------------------------------------------------------
      // mobile_phone
      // ---------------------------------------------------------
      MobilePhone :=
        Json.GetValue<string>(
          'mobile_phone',
          ''
        );

      // ---------------------------------------------------------
      // website_url
      // ---------------------------------------------------------
      WebsiteUrl :=
        Json.GetValue<string>(
          'website_url',
          ''
        );

      // ---------------------------------------------------------
      // logo_url
      // ---------------------------------------------------------
      LogoUrl :=
        Json.GetValue<string>(
          'logo_url',
          ''
        );

      // ---------------------------------------------------------
      // timezone
      // ---------------------------------------------------------
      Timezone :=
        Json.GetValue<string>(
          'timezone',
          ''
        );

      // ---------------------------------------------------------
      // currency_code
      // ---------------------------------------------------------
      CurrencyCode :=
        Json.GetValue<string>(
          'currency_code',
          ''
        );

      // ---------------------------------------------------------
      // locale_code
      // ---------------------------------------------------------
      LocaleCode :=
        Json.GetValue<string>(
          'locale_code',
          ''
        );

      // ---------------------------------------------------------
      // status
      // ---------------------------------------------------------
      Status :=
        Json.GetValue<string>(
          'status',
          ''
        );

      // ---------------------------------------------------------
      // is_master
      // ---------------------------------------------------------
      IsMaster :=
        Json.GetValue<Boolean>(
          'is_master',
          False
        );

      // ---------------------------------------------------------
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult := TTenantService.Update(
        TenantUuid,
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
        IsMaster,
        ErrorMessage
      );

      // ---------------------------------------------------------
      // Erro de validação/business rule
      // ---------------------------------------------------------
      if ErrorMessage <> '' then
      begin
        Res.Status(400);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              ErrorMessage
            )
            .ToJSON
        );

        Exit;
      end;

      // ---------------------------------------------------------
      // Tenant não encontrado
      // ---------------------------------------------------------
      if JsonResult = '' then
      begin
        Res.Status(404);

        Res.Send(
          '{"success":false,"message":"Tenant não encontrado."}'
        );

        Exit;
      end;

      // ---------------------------------------------------------
      // Sucesso
      // ---------------------------------------------------------
      Res.Status(200);
      Res.Send(JsonResult);

    except
      on E: Exception do
      begin
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              'Erro interno ao atualizar tenant: ' +
              E.Message
            )
            .ToJSON
        );
      end;
    end;

  finally
    Json.Free;
  end;
end;

{***************************************}
{* DELETE }
{***************************************}
class procedure TTenantController.Delete(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  TenantUuid: string;
  Deleted: Boolean;
  ValidUuid: Boolean;
begin
  Res.ContentType('application/json; charset=utf-8');

  try
    // ---------------------------------------------------------
    // UUID do tenant
    // ---------------------------------------------------------
    TenantUuid := Trim(
      Req.Params['uuid']
    );

    if TenantUuid = '' then
    begin
      Res.Status(400);

      Res.Send(
        '{"success":false,"message":"UUID do tenant não informado."}'
      );

      Exit;
    end;

    // ---------------------------------------------------------
    // Chama o Service
    // ---------------------------------------------------------
    Deleted := TTenantService.Delete(
      TenantUuid,
      ValidUuid
    );

    // ---------------------------------------------------------
    // UUID inválido
    // ---------------------------------------------------------
    if not ValidUuid then
    begin
      Res.Status(400);

      Res.Send(
        '{"success":false,"message":"UUID do tenant inválido."}'
      );

      Exit;
    end;

    // ---------------------------------------------------------
    // Tenant não encontrado ou não pode ser excluído
    // ---------------------------------------------------------
    if not Deleted then
    begin
      Res.Status(404);

      Res.Send(
        '{"success":false,"message":"Tenant não encontrado ou não pode ser excluído."}'
      );

      Exit;
    end;

    // ---------------------------------------------------------
    // Sucesso
    // ---------------------------------------------------------
    Res.Status(200);

    Res.Send(
      TJSONObject.Create
        .AddPair(
          'success',
          TJSONTrue.Create
        )
        .AddPair(
          'message',
          'Tenant excluído com sucesso.'
        )
        .ToJSON
    );

  except
    on E: Exception do
    begin
      Res.Status(500);

      Res.Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONFalse.Create
          )
          .AddPair(
            'message',
            'Erro interno ao excluir tenant: ' +
            E.Message
          )
          .ToJSON
      );
    end;
  end;
end;

end.
