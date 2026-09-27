unit uTenantController;

interface

uses
  Horse;

type
  TTenantController = class
  public
    class procedure List(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure GetByUuid(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure Create(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure Update(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure ChangeStatus(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure Delete(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure HardDelete(
      Req: THorseRequest;
      Res: THorseResponse
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uTenantService,
  uJwtService,
  uJwtRequestContext,
  uHttpResponseUtils;


//***************************************
//* LIST
//***************************************
class procedure TTenantController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LSearch: string;
  LSortField: string;
  LSortDirection: string;

  LPage: Integer;
  LPageSize: Integer;

  LErrorMessage: string;
  LForbidden: Boolean;
  LResult: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    THttpResponseUtils.SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* QUERY PARAMS
  //***************************************
  LSearch :=
    Trim(
      Req.Query['search']
    );

  LSortField :=
    Trim(
      Req.Query['sort_field']
    );

  LSortDirection :=
    Trim(
      Req.Query['sort_direction']
    );

  if not TryStrToInt(
    Trim(
      Req.Query['page']
    ),
    LPage
  ) then
    LPage := 1;

  if not TryStrToInt(
    Trim(
      Req.Query['page_size']
    ),
    LPageSize
  ) then
    LPageSize := 100;

  if LSortField = '' then
    LSortField :=
      'legal_name';

  if LSortDirection = '' then
    LSortDirection :=
      'ASC';

  //***************************************
  //* SERVICE
  //***************************************
  try
    LResult :=
      TTenantService.List(
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LSearch,
        LPage,
        LPageSize,
        LSortField,
        LSortDirection,
        LErrorMessage,
        LForbidden
      );

    if LForbidden then
    begin
      THttpResponseUtils.SendError(
        Res,
        403,
        LErrorMessage
      );

      Exit;
    end;

    if LErrorMessage <> '' then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    Res.Status(200);
    Res.Send(LResult);

  except
    on E: Exception do
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
  end;
end;


//***************************************
//* GET BY UUID
//***************************************
class procedure TTenantController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LTenantUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LTenantUuid = '' then
  begin
    THttpResponseUtils.SendError(
      Res,
      400,
      'UUID do tenant não informado.'
    );

    Exit;
  end;

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    THttpResponseUtils.SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* SERVICE
  //***************************************
  try
    LResult :=
      TTenantService.GetByUuid(
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LErrorMessage,
        LForbidden,
        LValidUuid
      );

    if not LValidUuid then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    if LForbidden then
    begin
      THttpResponseUtils.SendError(
        Res,
        403,
        LErrorMessage
      );

      Exit;
    end;

    if LResult = '' then
    begin
      THttpResponseUtils.SendError(
        Res,
        404,
        LErrorMessage
      );

      Exit;
    end;

    Res.Status(200);
    Res.Send(LResult);

  except
    on E: Exception do
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
  end;
end;

//***************************************
//* CREATE
//***************************************
class procedure TTenantController.Create(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LLegalName: string;
  LTradeName: string;
  LTaxId: string;
  LStateRegistration: string;
  LMunicipalRegistration: string;

  LEmail: string;
  LPhone: string;
  LMobilePhone: string;

  LWebsiteUrl: string;
  LLogoUrl: string;

  LTimezone: string;
  LCurrencyCode: string;
  LLocaleCode: string;
  LStatus: string;

  LResult: string;
  LErrorMessage: string;
  LForbidden: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  try

    try
      //***************************************
      //* JWT CONTEXT
      //***************************************
      if not TryGetJwtContext(
        Req,
        LJwtContext
      ) then
      begin
        THttpResponseUtils.SendError(
          Res,
          401,
          'Contexto de autenticação não encontrado.'
        );

        Exit;
      end;

      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* DEFAULT VALUES
      //***************************************
      LLegalName := '';
      LTradeName := '';
      LTaxId := '';
      LStateRegistration := '';
      LMunicipalRegistration := '';

      LEmail := '';
      LPhone := '';
      LMobilePhone := '';

      LWebsiteUrl := '';
      LLogoUrl := '';

      LTimezone :=
        'America/Sao_Paulo';

      LCurrencyCode :=
        'BRL';

      LLocaleCode :=
        'pt-BR';

      LStatus :=
        'ACTIVE';

      //***************************************
      //* LEGAL NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'legal_name'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LLegalName :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TRADE NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'trade_name'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LTradeName :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TAX ID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'tax_id'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LTaxId :=
          LJsonValue.Value;
      end;

      //***************************************
      //* STATE REGISTRATION
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'state_registration'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LStateRegistration :=
          LJsonValue.Value;
      end;

      //***************************************
      //* MUNICIPAL REGISTRATION
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'municipal_registration'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LMunicipalRegistration :=
          LJsonValue.Value;
      end;

      //***************************************
      //* EMAIL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'email'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LEmail :=
          LJsonValue.Value;
      end;

      //***************************************
      //* PHONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'phone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LPhone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* MOBILE PHONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'mobile_phone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LMobilePhone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* WEBSITE URL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'website_url'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LWebsiteUrl :=
          LJsonValue.Value;
      end;

      //***************************************
      //* LOGO URL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'logo_url'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LLogoUrl :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TIMEZONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'timezone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LTimezone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* CURRENCY CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'currency_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LCurrencyCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* LOCALE CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'locale_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LLocaleCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* STATUS
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'status'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LStatus :=
          LJsonValue.Value;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TTenantService.Create(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LLegalName,
          LTradeName,
          LTaxId,
          LStateRegistration,
          LMunicipalRegistration,
          LEmail,
          LPhone,
          LMobilePhone,
          LWebsiteUrl,
          LLogoUrl,
          LTimezone,
          LCurrencyCode,
          LLocaleCode,
          LStatus,
          LErrorMessage,
          LForbidden
        );

      //***************************************
      //* FORBIDDEN
      //***************************************
      if LForbidden then
      begin
        THttpResponseUtils.SendError(
          Res,
          403,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* ERROR
      //***************************************
      if LResult = '' then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      Res.Status(
        201
      );

      Res.Send(
        LResult
      );

    finally
      LJsonBody.Free;
    end;

  except
    on E: Exception do
    begin
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
    end;
  end;
end;

//***************************************
//* UPDATE
//***************************************
class procedure TTenantController.Update(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LTenantUuid: string;

  LLegalName: string;
  LTradeName: string;
  LTaxId: string;
  LStateRegistration: string;
  LMunicipalRegistration: string;

  LEmail: string;
  LPhone: string;
  LMobilePhone: string;

  LWebsiteUrl: string;
  LLogoUrl: string;

  LTimezone: string;
  LCurrencyCode: string;
  LLocaleCode: string;

  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  try

    try
      //***************************************
      //* UUID
      //***************************************
      LTenantUuid :=
        Trim(
          Req.Params['uuid']
        );

      if LTenantUuid = '' then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'UUID do tenant não informado.'
        );

        Exit;
      end;

      //***************************************
      //* JWT CONTEXT
      //***************************************
      if not TryGetJwtContext(
        Req,
        LJwtContext
      ) then
      begin
        THttpResponseUtils.SendError(
          Res,
          401,
          'Contexto de autenticação não encontrado.'
        );

        Exit;
      end;

      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* DEFAULT VALUES
      //***************************************
      LLegalName := '';
      LTradeName := '';
      LTaxId := '';
      LStateRegistration := '';
      LMunicipalRegistration := '';

      LEmail := '';
      LPhone := '';
      LMobilePhone := '';

      LWebsiteUrl := '';
      LLogoUrl := '';

      LTimezone := '';
      LCurrencyCode := '';
      LLocaleCode := '';

      //***************************************
      //* LEGAL NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'legal_name'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LLegalName :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TRADE NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'trade_name'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LTradeName :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TAX ID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'tax_id'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LTaxId :=
          LJsonValue.Value;
      end;

      //***************************************
      //* STATE REGISTRATION
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'state_registration'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LStateRegistration :=
          LJsonValue.Value;
      end;

      //***************************************
      //* MUNICIPAL REGISTRATION
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'municipal_registration'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LMunicipalRegistration :=
          LJsonValue.Value;
      end;

      //***************************************
      //* EMAIL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'email'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LEmail :=
          LJsonValue.Value;
      end;

      //***************************************
      //* PHONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'phone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LPhone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* MOBILE PHONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'mobile_phone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LMobilePhone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* WEBSITE URL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'website_url'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LWebsiteUrl :=
          LJsonValue.Value;
      end;

      //***************************************
      //* LOGO URL
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'logo_url'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LLogoUrl :=
          LJsonValue.Value;
      end;

      //***************************************
      //* TIMEZONE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'timezone'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LTimezone :=
          LJsonValue.Value;
      end;

      //***************************************
      //* CURRENCY CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'currency_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LCurrencyCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* LOCALE CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'locale_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LLocaleCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TTenantService.Update(
          LJwtContext.UserID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LTenantUuid,
          LLegalName,
          LTradeName,
          LTaxId,
          LStateRegistration,
          LMunicipalRegistration,
          LEmail,
          LPhone,
          LMobilePhone,
          LWebsiteUrl,
          LLogoUrl,
          LTimezone,
          LCurrencyCode,
          LLocaleCode,
          LErrorMessage,
          LForbidden,
          LValidUuid
        );

      //***************************************
      //* INVALID UUID
      //***************************************
      if not LValidUuid then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* FORBIDDEN
      //***************************************
      if LForbidden then
      begin
        THttpResponseUtils.SendError(
          Res,
          403,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* ERROR / NOT FOUND
      //***************************************
      if LResult = '' then
      begin
        if SameText(
          LErrorMessage,
          'Tenant não encontrado.'
        ) then
        begin
          THttpResponseUtils.SendError(
            Res,
            404,
            LErrorMessage
          );
        end
        else
        begin
          THttpResponseUtils.SendError(
            Res,
            400,
            LErrorMessage
          );
        end;

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      Res.Status(
        200
      );

      Res.Send(
        LResult
      );

    finally
      LJsonBody.Free;
    end;

  except
    on E: Exception do
    begin
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
    end;
  end;
end;

//***************************************
//* CHANGE STATUS
//***************************************
class procedure TTenantController.ChangeStatus(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LTenantUuid: string;
  LStatus: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidUuid: Boolean;
  LSuccess: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  try

    try
      //***************************************
      //* UUID
      //***************************************
      LTenantUuid :=
        Trim(
          Req.Params['uuid']
        );

      if LTenantUuid = '' then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'UUID do tenant não informado.'
        );

        Exit;
      end;

      //***************************************
      //* JWT CONTEXT
      //***************************************
      if not TryGetJwtContext(
        Req,
        LJwtContext
      ) then
      begin
        THttpResponseUtils.SendError(
          Res,
          401,
          'Contexto de autenticação não encontrado.'
        );

        Exit;
      end;

      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* STATUS
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'status'
        );

      if not Assigned(LJsonValue) or
         (LJsonValue is TJSONNull) then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'Status do tenant não informado.'
        );

        Exit;
      end;

      LStatus :=
        Trim(
          LJsonValue.Value
        );

      if LStatus = '' then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'Status do tenant não informado.'
        );

        Exit;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LSuccess :=
        TTenantService.ChangeStatus(
          LJwtContext.UserID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LTenantUuid,
          LStatus,
          LErrorMessage,
          LForbidden,
          LValidUuid
        );

      //***************************************
      //* INVALID UUID
      //***************************************
      if not LValidUuid then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* FORBIDDEN
      //***************************************
      if LForbidden then
      begin
        THttpResponseUtils.SendError(
          Res,
          403,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* ERROR / NOT FOUND
      //***************************************
      if not LSuccess then
      begin
        if SameText(
          LErrorMessage,
          'Tenant não encontrado.'
        ) then
        begin
          THttpResponseUtils.SendError(
            Res,
            404,
            LErrorMessage
          );
        end
        else
        begin
          THttpResponseUtils.SendError(
            Res,
            400,
            LErrorMessage
          );
        end;

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      THttpResponseUtils.SendSuccess(
        Res,
        200,
        'Status do tenant alterado com sucesso.'
      );

    finally
      LJsonBody.Free;
    end;

  except
    on E: Exception do
    begin
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
    end;
  end;
end;

//***************************************
//* DELETE
//***************************************
class procedure TTenantController.Delete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidUuid: Boolean;
  LSuccess: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LTenantUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LTenantUuid = '' then
  begin
    THttpResponseUtils.SendError(
      Res,
      400,
      'UUID do tenant não informado.'
    );

    Exit;
  end;

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    THttpResponseUtils.SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* SERVICE
  //***************************************
  try
    LSuccess :=
      TTenantService.Delete(
        LJwtContext.UserID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LErrorMessage,
        LForbidden,
        LValidUuid
      );

    if not LValidUuid then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    if LForbidden then
    begin
      THttpResponseUtils.SendError(
        Res,
        403,
        LErrorMessage
      );

      Exit;
    end;

    if not LSuccess then
    begin
      if SameText(
        LErrorMessage,
        'Tenant não encontrado.'
      ) then
        THttpResponseUtils.SendError(
          Res,
          404,
          LErrorMessage
        )
      else
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );

      Exit;
    end;

    THttpResponseUtils.SendSuccess(
      Res,
      200,
      'Tenant excluído com sucesso.'
    );

  except
    on E: Exception do
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
  end;
end;

//***************************************
//* HARD DELETE
//***************************************
class procedure TTenantController.HardDelete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidUuid: Boolean;
  LHasDependencies: Boolean;
  LSuccess: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LTenantUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LTenantUuid = '' then
  begin
    THttpResponseUtils.SendError(
      Res,
      400,
      'UUID do tenant não informado.'
    );

    Exit;
  end;

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    THttpResponseUtils.SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* SERVICE
  //***************************************
  try
    LSuccess :=
      TTenantService.HardDelete(
        LJwtContext.UserID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LErrorMessage,
        LForbidden,
        LValidUuid,
        LHasDependencies
      );

    //***************************************
    //* INVALID UUID
    //***************************************
    if not LValidUuid then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* FORBIDDEN
    //***************************************
    if LForbidden then
    begin
      THttpResponseUtils.SendError(
        Res,
        403,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* ERROR
    //***************************************
    if not LSuccess then
    begin
      if SameText(
        LErrorMessage,
        'Tenant não encontrado.'
      ) then
      begin
        THttpResponseUtils.SendError(
          Res,
          404,
          LErrorMessage
        );
      end
      else if LHasDependencies then
      begin
        THttpResponseUtils.SendError(
          Res,
          409,
          LErrorMessage
        );
      end
      else
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );
      end;

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    THttpResponseUtils.SendSuccess(
      Res,
      200,
      'Tenant excluído definitivamente com sucesso.'
    );

  except
    on E: Exception do
    begin
      THttpResponseUtils.HandleDatabaseError(
        Res,
        E
      );
    end;
  end;
end;


end.
