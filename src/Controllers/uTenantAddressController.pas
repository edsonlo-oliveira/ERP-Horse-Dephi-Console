unit uTenantAddressController;

interface

uses
  Horse;

type
  TTenantAddressController = class
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

    class procedure Delete(
      Req: THorseRequest;
      Res: THorseResponse
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uTenantAddressService,
  uJwtService,
  uJwtRequestContext,
  uHttpResponseUtils;


//***************************************
//* LIST
//***************************************
class procedure TTenantAddressController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidTenantUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* TENANT UUID
  //***************************************
  LTenantUuid :=
    Trim(
      Req.Params['tenant_uuid']
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
      TTenantAddressService.List(
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LErrorMessage,
        LForbidden,
        LValidTenantUuid
      );

    //***************************************
    //* INVALID TENANT UUID
    //***************************************
    if not LValidTenantUuid then
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
    //* TENANT NOT FOUND
    //***************************************
    if LErrorMessage <> '' then
    begin
      THttpResponseUtils.SendError(
        Res,
        404,
        LErrorMessage
      );

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
//* GET BY UUID
//***************************************
class procedure TTenantAddressController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LAddressUuid: string;

  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidTenantUuid: Boolean;
  LValidAddressUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* TENANT UUID
  //***************************************
  LTenantUuid :=
    Trim(
      Req.Params['tenant_uuid']
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
  //* ADDRESS UUID
  //***************************************
  LAddressUuid :=
    Trim(
      Req.Params['address_uuid']
    );

  if LAddressUuid = '' then
  begin
    THttpResponseUtils.SendError(
      Res,
      400,
      'UUID do endereço não informado.'
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
      TTenantAddressService.GetByUuid(
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LAddressUuid,
        LErrorMessage,
        LForbidden,
        LValidTenantUuid,
        LValidAddressUuid
      );

    //***************************************
    //* INVALID TENANT UUID
    //***************************************
    if not LValidTenantUuid then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* INVALID ADDRESS UUID
    //***************************************
    if not LValidAddressUuid then
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
    //* NOT FOUND
    //***************************************
    if LResult = '' then
    begin
      THttpResponseUtils.SendError(
        Res,
        404,
        LErrorMessage
      );

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
//* CREATE
//***************************************
class procedure TTenantAddressController.Create(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;

  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LAddressType: string;
  LAddressLine: string;
  LAddressNumber: string;
  LAddressComplement: string;
  LNeighborhood: string;
  LCity: string;
  LStateCode: string;
  LPostalCode: string;
  LCountryCode: string;
  LIsPrimary: Boolean;

  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidTenantUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  try

    try
      //***************************************
      //* TENANT UUID
      //***************************************
      LTenantUuid :=
        Trim(
          Req.Params['tenant_uuid']
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
      LAddressType := '';
      LAddressLine := '';
      LAddressNumber := '';
      LAddressComplement := '';
      LNeighborhood := '';
      LCity := '';
      LStateCode := '';
      LPostalCode := '';
      LCountryCode := 'BR';
      LIsPrimary := False;

      //***************************************
      //* ADDRESS TYPE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_type'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LAddressType :=
          LJsonValue.Value;
      end;

      //***************************************
      //* ADDRESS LINE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_line'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LAddressLine :=
          LJsonValue.Value;
      end;

      //***************************************
      //* ADDRESS NUMBER
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_number'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LAddressNumber :=
          LJsonValue.Value;
      end;

      //***************************************
      //* ADDRESS COMPLEMENT
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_complement'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LAddressComplement :=
          LJsonValue.Value;
      end;

      //***************************************
      //* NEIGHBORHOOD
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'neighborhood'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LNeighborhood :=
          LJsonValue.Value;
      end;

      //***************************************
      //* CITY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'city'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LCity :=
          LJsonValue.Value;
      end;

      //***************************************
      //* STATE CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'state_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LStateCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* POSTAL CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'postal_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LPostalCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* COUNTRY CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'country_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LCountryCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* IS PRIMARY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'is_primary'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if LJsonValue is TJSONBool then
        begin
          LIsPrimary :=
            TJSONBool(
              LJsonValue
            ).AsBoolean;
        end
        else
        begin
          THttpResponseUtils.SendError(
            Res,
            400,
            'O campo is_primary deve ser booleano.'
          );

          Exit;
        end;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TTenantAddressService.Create(
          LJwtContext.UserID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LTenantUuid,
          LAddressType,
          LAddressLine,
          LAddressNumber,
          LAddressComplement,
          LNeighborhood,
          LCity,
          LStateCode,
          LPostalCode,
          LCountryCode,
          LIsPrimary,
          LErrorMessage,
          LForbidden,
          LValidTenantUuid
        );

      //***************************************
      //* INVALID TENANT UUID
      //***************************************
      if not LValidTenantUuid then
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
class procedure TTenantAddressController.Update(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LAddressUuid: string;

  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LAddressType: string;
  LAddressLine: string;
  LAddressNumber: string;
  LAddressComplement: string;
  LNeighborhood: string;
  LCity: string;
  LStateCode: string;
  LPostalCode: string;
  LCountryCode: string;
  LIsPrimary: Boolean;

  LResult: string;
  LErrorMessage: string;

  LForbidden: Boolean;
  LValidTenantUuid: Boolean;
  LValidAddressUuid: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  try

    try
      //***************************************
      //* TENANT UUID
      //***************************************
      LTenantUuid :=
        Trim(
          Req.Params['tenant_uuid']
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
      //* ADDRESS UUID
      //***************************************
      LAddressUuid :=
        Trim(
          Req.Params['address_uuid']
        );

      if LAddressUuid = '' then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          'UUID do endereço não informado.'
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
      LAddressType := '';
      LAddressLine := '';
      LAddressNumber := '';
      LAddressComplement := '';
      LNeighborhood := '';
      LCity := '';
      LStateCode := '';
      LPostalCode := '';
      LCountryCode := 'BR';
      LIsPrimary := False;

      //***************************************
      //* ADDRESS TYPE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_type'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LAddressType :=
          LJsonValue.Value;

      //***************************************
      //* ADDRESS LINE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_line'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LAddressLine :=
          LJsonValue.Value;

      //***************************************
      //* ADDRESS NUMBER
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_number'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LAddressNumber :=
          LJsonValue.Value;

      //***************************************
      //* ADDRESS COMPLEMENT
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'address_complement'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LAddressComplement :=
          LJsonValue.Value;

      //***************************************
      //* NEIGHBORHOOD
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'neighborhood'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LNeighborhood :=
          LJsonValue.Value;

      //***************************************
      //* CITY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'city'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LCity :=
          LJsonValue.Value;

      //***************************************
      //* STATE CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'state_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LStateCode :=
          LJsonValue.Value;

      //***************************************
      //* POSTAL CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'postal_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
        LPostalCode :=
          LJsonValue.Value;

      //***************************************
      //* COUNTRY CODE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'country_code'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) and
         (Trim(LJsonValue.Value) <> '') then
      begin
        LCountryCode :=
          LJsonValue.Value;
      end;

      //***************************************
      //* IS PRIMARY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'is_primary'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if LJsonValue is TJSONBool then
        begin
          LIsPrimary :=
            TJSONBool(
              LJsonValue
            ).AsBoolean;
        end
        else
        begin
          THttpResponseUtils.SendError(
            Res,
            400,
            'O campo is_primary deve ser booleano.'
          );

          Exit;
        end;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TTenantAddressService.Update(
          LJwtContext.UserID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LTenantUuid,
          LAddressUuid,
          LAddressType,
          LAddressLine,
          LAddressNumber,
          LAddressComplement,
          LNeighborhood,
          LCity,
          LStateCode,
          LPostalCode,
          LCountryCode,
          LIsPrimary,
          LErrorMessage,
          LForbidden,
          LValidTenantUuid,
          LValidAddressUuid
        );

      //***************************************
      //* INVALID TENANT UUID
      //***************************************
      if not LValidTenantUuid then
      begin
        THttpResponseUtils.SendError(
          Res,
          400,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* INVALID ADDRESS UUID
      //***************************************
      if not LValidAddressUuid then
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
        ) or
        SameText(
          LErrorMessage,
          'Endereço do tenant não encontrado.'
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
//* DELETE
//***************************************
class procedure TTenantAddressController.Delete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;

  LTenantUuid: string;
  LAddressUuid: string;

  LErrorMessage: string;

  LForbidden: Boolean;
  LValidTenantUuid: Boolean;
  LValidAddressUuid: Boolean;
  LSuccess: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* TENANT UUID
  //***************************************
  LTenantUuid :=
    Trim(
      Req.Params['tenant_uuid']
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
  //* ADDRESS UUID
  //***************************************
  LAddressUuid :=
    Trim(
      Req.Params['address_uuid']
    );

  if LAddressUuid = '' then
  begin
    THttpResponseUtils.SendError(
      Res,
      400,
      'UUID do endereço não informado.'
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
      TTenantAddressService.Delete(
        LJwtContext.UserID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LTenantUuid,
        LAddressUuid,
        LErrorMessage,
        LForbidden,
        LValidTenantUuid,
        LValidAddressUuid
      );

    //***************************************
    //* INVALID TENANT UUID
    //***************************************
    if not LValidTenantUuid then
    begin
      THttpResponseUtils.SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* INVALID ADDRESS UUID
    //***************************************
    if not LValidAddressUuid then
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
      ) or
      SameText(
        LErrorMessage,
        'Endereço do tenant não encontrado.'
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
      'Endereço do tenant excluído com sucesso.'
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
