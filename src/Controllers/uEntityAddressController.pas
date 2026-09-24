unit uEntityAddressController;

interface

uses
  Horse;

type
  TEntityAddressController = class
  public
    class procedure List(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure GetById(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure Create(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );

    class procedure Update(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
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
  uEntityAddressService,
  uJwtService,
  uJwtRequestContext,
  uDatabaseErrorHandler;

//***********************************************
//* SEND JSON MESSAGE
//***********************************************
procedure SendJsonMessage(
  const ARes: THorseResponse;
  const AStatus: Integer;
  const ASuccess: Boolean;
  const AMessage: string
);
var
  LJson: TJSONObject;
begin
  LJson :=
    TJSONObject.Create;

  try
    LJson.AddPair(
      'success',
      TJSONBool.Create(
        ASuccess
      )
    );

    LJson.AddPair(
      'message',
      AMessage
    );

    ARes.Status(
      AStatus
    );

    ARes.Send(
      LJson.ToJSON
    );

  finally
    LJson.Free;
  end;
end;

//***********************************************
//* LIST
//***********************************************
class procedure TEntityAddressController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LEntityUuid: string;
  LJsonResult: string;
  LValidUuid: Boolean;
  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* AUTH CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendJsonMessage(
      Res,
      401,
      False,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* ENTITY UUID
  //***************************************
  LEntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LEntityUuid = '' then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'UUID da entidade não informado.'
    );

    Exit;
  end;

  try
    LJsonResult :=
      TEntityAddressService.List(
        LJwtContext.TenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LEntityUuid,
        LValidUuid
      );

    if not LValidUuid then
    begin
      SendJsonMessage(
        Res,
        400,
        False,
        'UUID da entidade inválido.'
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
      LJsonResult
    );

  except
    on E: Exception do
    begin
      LErrorInfo :=
        TDatabaseErrorHandler.Handle(
          E
        );

      SendJsonMessage(
        Res,
        LErrorInfo.HttpStatus,
        False,
        LErrorInfo.UserMessage
      );
    end;
  end;
end;

//***********************************************
//* GET BY ID
//***********************************************
class procedure TEntityAddressController.GetById(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LEntityUuid: string;
  LAddressIDText: string;
  LEntityAddressID: Int64;
  LJsonResult: string;
  LValidUuid: Boolean;
  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* AUTH CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendJsonMessage(
      Res,
      401,
      False,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* ENTITY UUID
  //***************************************
  LEntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LEntityUuid = '' then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'UUID da entidade não informado.'
    );

    Exit;
  end;

  //***************************************
  //* ADDRESS ID
  //***************************************
  LAddressIDText :=
    Trim(
      Req.Params['address_id']
    );

  if not TryStrToInt64(
    LAddressIDText,
    LEntityAddressID
  ) or
     (LEntityAddressID <= 0) then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'Identificador do endereço inválido.'
    );

    Exit;
  end;

  try
    LJsonResult :=
      TEntityAddressService.GetById(
        LJwtContext.TenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LEntityUuid,
        LEntityAddressID,
        LValidUuid
      );

    if not LValidUuid then
    begin
      SendJsonMessage(
        Res,
        400,
        False,
        'UUID da entidade inválido.'
      );

      Exit;
    end;

    if LJsonResult = '' then
    begin
      SendJsonMessage(
        Res,
        404,
        False,
        'Endereço não encontrado.'
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
      LJsonResult
    );

  except
    on E: Exception do
    begin
      LErrorInfo :=
        TDatabaseErrorHandler.Handle(
          E
        );

      SendJsonMessage(
        Res,
        LErrorInfo.HttpStatus,
        False,
        LErrorInfo.UserMessage
      );
    end;
  end;
end;

//***********************************************
//* CREATE
//***********************************************
class procedure TEntityAddressController.Create(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LEntityUuid: string;

  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LAddressType: string;
  LPostalCode: string;
  LAddressLine: string;
  LAddressNumber: string;
  LAddressComplement: string;
  LNeighborhood: string;
  LCity: string;
  LStateCode: string;
  LIsPrimary: Boolean;

  LJsonResult: string;
  LErrorMessage: string;
  LValidUuid: Boolean;

  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  //***************************************
  //* AUTH CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendJsonMessage(
      Res,
      401,
      False,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* ENTITY UUID
  //***************************************
  LEntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LEntityUuid = '' then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'UUID da entidade não informado.'
    );

    Exit;
  end;

  try
    try
      //***************************************
      //* JSON BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(
        LJsonBody
      ) then
      begin
        SendJsonMessage(
          Res,
          400,
          False,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* DEFAULT VALUES
      //***************************************
      LAddressType := '';
      LPostalCode := '';
      LAddressLine := '';
      LAddressNumber := '';
      LAddressComplement := '';
      LNeighborhood := '';
      LCity := '';
      LStateCode := '';
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
      //* COMPLEMENT
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
      //* PRIMARY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'is_primary'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LIsPrimary :=
          SameText(
            LJsonValue.Value,
            'true'
          );
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LJsonResult :=
        TEntityAddressService.Create(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LEntityUuid,
          LAddressType,
          LPostalCode,
          LAddressLine,
          LAddressNumber,
          LAddressComplement,
          LNeighborhood,
          LCity,
          LStateCode,
          LIsPrimary,
          LValidUuid,
          LErrorMessage
        );

      //***************************************
      //* INVALID UUID
      //***************************************
      if not LValidUuid then
      begin
        SendJsonMessage(
          Res,
          400,
          False,
          'UUID da entidade inválido.'
        );

        Exit;
      end;

      //***************************************
      //* BUSINESS VALIDATION
      //***************************************
      if LErrorMessage <> '' then
      begin
        if SameText(
          LErrorMessage,
          'Entidade não encontrada.'
        ) then
        begin
          SendJsonMessage(
            Res,
            404,
            False,
            LErrorMessage
          );
        end
        else
        begin
          SendJsonMessage(
            Res,
            400,
            False,
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
        LJsonResult
      );

    except
      on E: Exception do
      begin
        LErrorInfo :=
          TDatabaseErrorHandler.Handle(
            E
          );

        //***************************************
        //* DUPLICATE ADDRESS TYPE
        //***************************************
        if Pos(
          'uq_entity_addresses_entity_type',
          LowerCase(E.Message)
        ) > 0 then
        begin
          LErrorInfo.HttpStatus := 409;

          LErrorInfo.UserMessage :=
            'Esta entidade já possui um endereço deste tipo.';
        end;

        SendJsonMessage(
          Res,
          LErrorInfo.HttpStatus,
          False,
          LErrorInfo.UserMessage
        );
      end;
    end;

  finally
    LJsonBody.Free;
  end;
end;

//***********************************************
//* UPDATE
//***********************************************
class procedure TEntityAddressController.Update(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LEntityUuid: string;
  LAddressIDText: string;
  LEntityAddressID: Int64;

  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LAddressType: string;
  LPostalCode: string;
  LAddressLine: string;
  LAddressNumber: string;
  LAddressComplement: string;
  LNeighborhood: string;
  LCity: string;
  LStateCode: string;
  LIsPrimary: Boolean;

  LJsonResult: string;
  LErrorMessage: string;
  LValidUuid: Boolean;

  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  LJsonBody := nil;

  //***************************************
  //* AUTH CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendJsonMessage(
      Res,
      401,
      False,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* ENTITY UUID
  //***************************************
  LEntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LEntityUuid = '' then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'UUID da entidade não informado.'
    );

    Exit;
  end;

  //***************************************
  //* ADDRESS ID
  //***************************************
  LAddressIDText :=
    Trim(
      Req.Params['address_id']
    );

  if not TryStrToInt64(
    LAddressIDText,
    LEntityAddressID
  ) or
     (LEntityAddressID <= 0) then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'Identificador do endereço inválido.'
    );

    Exit;
  end;

  try
    try
      //***************************************
      //* JSON BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(
        LJsonBody
      ) then
      begin
        SendJsonMessage(
          Res,
          400,
          False,
          'JSON inválido.'
        );

        Exit;
      end;

      LAddressType := '';
      LPostalCode := '';
      LAddressLine := '';
      LAddressNumber := '';
      LAddressComplement := '';
      LNeighborhood := '';
      LCity := '';
      LStateCode := '';
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
      //* COMPLEMENT
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
      //* STATE
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
      //* PRIMARY
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'is_primary'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        LIsPrimary :=
          SameText(
            LJsonValue.Value,
            'true'
          );
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LJsonResult :=
        TEntityAddressService.Update(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LEntityUuid,
          LEntityAddressID,
          LAddressType,
          LPostalCode,
          LAddressLine,
          LAddressNumber,
          LAddressComplement,
          LNeighborhood,
          LCity,
          LStateCode,
          LIsPrimary,
          LValidUuid,
          LErrorMessage
        );

      if not LValidUuid then
      begin
        SendJsonMessage(
          Res,
          400,
          False,
          'UUID da entidade inválido.'
        );

        Exit;
      end;

      if LErrorMessage <> '' then
      begin
        if SameText(
          LErrorMessage,
          'Endereço não encontrado.'
        ) then
        begin
          SendJsonMessage(
            Res,
            404,
            False,
            LErrorMessage
          );
        end
        else
        begin
          SendJsonMessage(
            Res,
            400,
            False,
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
        LJsonResult
      );

    except
      on E: Exception do
      begin
        LErrorInfo :=
          TDatabaseErrorHandler.Handle(
            E
          );

        if Pos(
          'uq_entity_addresses_entity_type',
          LowerCase(E.Message)
        ) > 0 then
        begin
          LErrorInfo.HttpStatus := 409;

          LErrorInfo.UserMessage :=
            'Esta entidade já possui um endereço deste tipo.';
        end;

        SendJsonMessage(
          Res,
          LErrorInfo.HttpStatus,
          False,
          LErrorInfo.UserMessage
        );
      end;
    end;

  finally
    LJsonBody.Free;
  end;
end;

//***********************************************
//* DELETE
//***********************************************
class procedure TEntityAddressController.Delete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LEntityUuid: string;
  LAddressIDText: string;
  LEntityAddressID: Int64;

  LDeleted: Boolean;
  LValidUuid: Boolean;
  LErrorMessage: string;

  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* AUTH CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendJsonMessage(
      Res,
      401,
      False,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  LEntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if LEntityUuid = '' then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'UUID da entidade não informado.'
    );

    Exit;
  end;

  //***************************************
  //* ADDRESS ID
  //***************************************
  LAddressIDText :=
    Trim(
      Req.Params['address_id']
    );

  if not TryStrToInt64(
    LAddressIDText,
    LEntityAddressID
  ) or
     (LEntityAddressID <= 0) then
  begin
    SendJsonMessage(
      Res,
      400,
      False,
      'Identificador do endereço inválido.'
    );

    Exit;
  end;

  try
    LDeleted :=
      TEntityAddressService.Delete(
        LJwtContext.UserID,
        LJwtContext.TenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LEntityUuid,
        LEntityAddressID,
        LValidUuid,
        LErrorMessage
      );

    if not LValidUuid then
    begin
      SendJsonMessage(
        Res,
        400,
        False,
        'UUID da entidade inválido.'
      );

      Exit;
    end;

    if not LDeleted then
    begin
      SendJsonMessage(
        Res,
        404,
        False,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(
      204
    );

    Res.Send(
      ''
    );

  except
    on E: Exception do
    begin
      LErrorInfo :=
        TDatabaseErrorHandler.Handle(
          E
        );

      SendJsonMessage(
        Res,
        LErrorInfo.HttpStatus,
        False,
        LErrorInfo.UserMessage
      );
    end;
  end;
end;

end.
