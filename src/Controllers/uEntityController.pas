unit uEntityController;

interface

uses
  Horse;

type
  TEntityController = class
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

    class procedure HardDelete(
      Req: THorseRequest;
      Res: THorseResponse
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uEntityService,
  uJwtService,
  uJwtRequestContext, uDatabaseErrorHandler, uServerLogger;


//***************************************
//* LIST
//***************************************
class procedure TEntityController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LSearch: string;
  LPage: Integer;
  LPageSize: Integer;
  LSortField: string;
  LSortAscending: Boolean;
  LDirection: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  //***************************************
  //* SEARCH
  //***************************************
  LSearch :=
    Trim(
      Req.Query.Field('search').AsString
    );

  //***************************************
  //* PAGE
  //***************************************
  LPage :=
    StrToIntDef(
      Req.Query.Field('page').AsString,
      1
    );

  //***************************************
  //* PAGE SIZE
  //***************************************
  LPageSize :=
    StrToIntDef(
      Req.Query.Field('page_size').AsString,
      100
    );

  //***************************************
  //* SORT FIELD
  //***************************************
  LSortField :=
    Trim(
      Req.Query.Field('sort').AsString
    );

  if LSortField = '' then
    LSortField := 'legal_name';

  //***************************************
  //* SORT DIRECTION
  //***************************************
  LDirection :=
    LowerCase(
      Trim(
        Req.Query.Field('direction').AsString
      )
    );

  LSortAscending :=
    not SameText(
      LDirection,
      'desc'
    );

  Res.Status(200);

  Res.Send(
    TEntityService.List(
      LJwtContext.TenantID,
      LJwtContext.SuperUser,
      LJwtContext.Scope,
      LSearch,
      LPage,
      LPageSize,
      LSortField,
      LSortAscending
    )
  );
end;

//***************************************
//* GET BY UUID
//***************************************
class procedure TEntityController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  EntityUuid: string;
  JsonResult: string;
  ValidUuid: Boolean;
  LJwtContext: TJwtContext;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  EntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if EntityUuid = '' then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );

    Exit;
  end;

  JsonResult :=
    TEntityService.GetByUuid(
      EntityUuid,
      LJwtContext.TenantID,
      LJwtContext.SuperUser,
      LJwtContext.Scope,
      ValidUuid
    );

  if not ValidUuid then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID da entidade inválido."}'
    );

    Exit;
  end;

  if JsonResult = '' then
  begin
    Res.Status(404);

    Res.Send(
      '{"success":false,"message":"Entidade não encontrada."}'
    );

    Exit;
  end;

  Res.Status(200);
  Res.Send(JsonResult);
end;


//***************************************
//* CREATE
//***************************************
class procedure TEntityController.Create(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  JsonBody: TJSONObject;

  TargetTenantID: Int64;

  EntityType: string;
  TaxId: string;
  LegalName: string;
  TradeName: string;
  StateRegistration: string;
  MunicipalRegistration: string;

  IsCustomer: Boolean;
  IsSupplier: Boolean;

  Email: string;
  Phone: string;
  MobilePhone: string;

  JsonResult: string;
  ErrorMessage: string;
  JsonValue: TJSONValue;

  LJwtContext: TJwtContext;

  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  JsonBody := nil;

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  try
    try
      // ---------------------------------------------------------
      // Converte o corpo da requisição para JSON
      // ---------------------------------------------------------
      JsonBody :=
        TJSONObject.ParseJSONValue(
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
      TargetTenantID := 0;

      EntityType := '';
      TaxId := '';
      LegalName := '';
      TradeName := '';
      StateRegistration := '';
      MunicipalRegistration := '';

      IsCustomer := False;
      IsSupplier := False;

      Email := '';
      Phone := '';
      MobilePhone := '';

      // ---------------------------------------------------------
      // tenant_id
      //
      // Só é considerado para SuperUser GLOBAL.
      // Usuário TENANT não pode escolher outro tenant.
      // ---------------------------------------------------------
      if LJwtContext.SuperUser and
         SameText(
           Trim(LJwtContext.Scope),
           'GLOBAL'
         ) then
      begin
        JsonValue :=
          JsonBody.GetValue(
            'tenant_id'
          );

        if Assigned(JsonValue) and
           not (JsonValue is TJSONNull) then
        begin
          if not TryStrToInt64(
            JsonValue.Value,
            TargetTenantID
          ) then
          begin
            Res.Status(400);

            Res.Send(
              '{"success":false,"message":"tenant_id inválido."}'
            );

            Exit;
          end;

          if TargetTenantID <= 0 then
          begin
            Res.Status(400);

            Res.Send(
              '{"success":false,"message":"tenant_id inválido."}'
            );

            Exit;
          end;
        end;
      end;

      // ---------------------------------------------------------
      // entity_type
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'entity_type'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        EntityType :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'tax_id'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // legal_name
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'legal_name'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        LegalName :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // trade_name
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'trade_name'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TradeName :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // state_registration
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'state_registration'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        StateRegistration :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // municipal_registration
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'municipal_registration'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MunicipalRegistration :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // is_customer
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'is_customer'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsCustomer :=
          SameText(
            JsonValue.Value,
            'true'
          );

      // ---------------------------------------------------------
      // is_supplier
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'is_supplier'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsSupplier :=
          SameText(
            JsonValue.Value,
            'true'
          );

      // ---------------------------------------------------------
      // email
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'email'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Email :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // phone
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'phone'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Phone :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // mobile_phone
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'mobile_phone'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MobilePhone :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult :=
        TEntityService.Create(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          TargetTenantID,
          EntityType,
          TaxId,
          LegalName,
          TradeName,
          StateRegistration,
          MunicipalRegistration,
          IsCustomer,
          IsSupplier,
          Email,
          Phone,
          MobilePhone,
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
        //***************************************
        //* DATABASE ERROR HANDLER
        //***************************************
        LErrorInfo :=
          TDatabaseErrorHandler.Handle(
            E
          );

        //***************************************
        //* TECHNICAL LOG
        //***************************************
        TServerLogger.Error(
          'Entity.Create' +
          sLineBreak +
          'UserID: ' +
          LJwtContext.UserID.ToString +
          sLineBreak +
          'TenantID: ' +
          LJwtContext.TenantID.ToString +
          sLineBreak +
          'TargetTenantID: ' +
          TargetTenantID.ToString +
          sLineBreak +
          LErrorInfo.Details
        );

        //***************************************
        //* CLIENT RESPONSE
        //***************************************
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              LErrorInfo.UserMessage
            )
            .ToJSON
        );
      end;
    end;

  finally
    JsonBody.Free;
  end;
end;

//***************************************
//* UPDATE
//***************************************
class procedure TEntityController.Update(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  EntityUuid: string;

  JsonBody: TJSONObject;

  EntityType: string;
  TaxId: string;
  LegalName: string;
  TradeName: string;
  StateRegistration: string;
  MunicipalRegistration: string;

  IsCustomer: Boolean;
  IsSupplier: Boolean;

  Email: string;
  Phone: string;
  MobilePhone: string;

  JsonResult: string;
  ErrorMessage: string;

  ValidUuid: Boolean;

  JsonValue: TJSONValue;

  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  EntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if EntityUuid = '' then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );

    Exit;
  end;

  JsonBody := nil;

  try
    try
      // ---------------------------------------------------------
      // Converte o corpo da requisição para JSON
      // ---------------------------------------------------------
      JsonBody :=
        TJSONObject.ParseJSONValue(
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
      EntityType := '';
      TaxId := '';
      LegalName := '';
      TradeName := '';
      StateRegistration := '';
      MunicipalRegistration := '';

      IsCustomer := False;
      IsSupplier := False;

      Email := '';
      Phone := '';
      MobilePhone := '';

      // ---------------------------------------------------------
      // entity_type
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'entity_type'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        EntityType :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'tax_id'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // legal_name
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'legal_name'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        LegalName :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // trade_name
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'trade_name'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TradeName :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // state_registration
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'state_registration'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        StateRegistration :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // municipal_registration
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'municipal_registration'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MunicipalRegistration :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // is_customer
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'is_customer'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsCustomer :=
          SameText(
            JsonValue.Value,
            'true'
          );

      // ---------------------------------------------------------
      // is_supplier
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'is_supplier'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsSupplier :=
          SameText(
            JsonValue.Value,
            'true'
          );

      // ---------------------------------------------------------
      // email
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'email'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Email :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // phone
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'phone'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Phone :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // mobile_phone
      // ---------------------------------------------------------
      JsonValue :=
        JsonBody.GetValue(
          'mobile_phone'
        );

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MobilePhone :=
          JsonValue.Value;

      // ---------------------------------------------------------
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult :=
        TEntityService.Update(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          EntityUuid,
          EntityType,
          TaxId,
          LegalName,
          TradeName,
          StateRegistration,
          MunicipalRegistration,
          IsCustomer,
          IsSupplier,
          Email,
          Phone,
          MobilePhone,
          ValidUuid,
          ErrorMessage
        );

      // ---------------------------------------------------------
      // UUID inválido
      // ---------------------------------------------------------
      if not ValidUuid then
      begin
        Res.Status(400);

        Res.Send(
          '{"success":false,"message":"UUID da entidade inválido."}'
        );

        Exit;
      end;

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
      // Entidade não encontrada
      // ---------------------------------------------------------
      if JsonResult = '' then
      begin
        Res.Status(404);

        Res.Send(
          '{"success":false,"message":"Entidade não encontrada."}'
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
        //***************************************
        //* DATABASE ERROR HANDLER
        //***************************************
        LErrorInfo :=
          TDatabaseErrorHandler.Handle(
            E
          );

        //***************************************
        //* TECHNICAL LOG
        //***************************************
        TServerLogger.Error(
          'Entity.Update' +
          sLineBreak +
          'UserID: ' +
          LJwtContext.UserID.ToString +
          sLineBreak +
          'TenantID: ' +
          LJwtContext.TenantID.ToString +
          sLineBreak +
          'EntityUUID: ' +
          EntityUuid +
          sLineBreak +
          LErrorInfo.Details
        );

        //***************************************
        //* CLIENT RESPONSE
        //***************************************
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              LErrorInfo.UserMessage
            )
            .ToJSON
        );
      end;
    end;

  finally
    JsonBody.Free;
  end;
end;

//***************************************
//* SOFT DELETE
//***************************************
class procedure TEntityController.Delete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  EntityUuid: string;
  ValidUuid: Boolean;
  Deleted: Boolean;
  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  EntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if EntityUuid = '' then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );

    Exit;
  end;

  try
    Deleted :=
      TEntityService.Delete(
        EntityUuid,
        LJwtContext.UserID,
        LJwtContext.TenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        ValidUuid
      );

    //***************************************
    //* INVALID UUID
    //***************************************
    if not ValidUuid then
    begin
      Res.Status(400);

      Res.Send(
        '{"success":false,"message":"UUID da entidade inválido."}'
      );

      Exit;
    end;

    //***************************************
    //* NOT FOUND
    //***************************************
    if not Deleted then
    begin
      Res.Status(404);

      Res.Send(
        '{"success":false,"message":"Entidade não encontrada."}'
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(204);
    Res.Send('');

  except
    on E: Exception do
    begin
      //***************************************
      //* DATABASE ERROR HANDLER
      //***************************************
      LErrorInfo :=
        TDatabaseErrorHandler.Handle(
          E
        );

      //***************************************
      //* TECHNICAL LOG
      //***************************************
      TServerLogger.Error(
        'Entity.Delete' +
        sLineBreak +
        'UserID: ' +
        LJwtContext.UserID.ToString +
        sLineBreak +
        'TenantID: ' +
        LJwtContext.TenantID.ToString +
        sLineBreak +
        'EntityUUID: ' +
        EntityUuid +
        sLineBreak +
        LErrorInfo.Details
      );

      //***************************************
      //* CLIENT RESPONSE
      //***************************************
      Res.Status(500);

      Res.Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONFalse.Create
          )
          .AddPair(
            'message',
            LErrorInfo.UserMessage
          )
          .ToJSON
      );
    end;
  end;
end;


//***************************************
//* HARD DELETE
//***************************************
class procedure TEntityController.HardDelete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  EntityUuid: string;
  ValidUuid: Boolean;
  HasDependencies: Boolean;
  Deleted: Boolean;
  LJwtContext: TJwtContext;
  LErrorInfo: TDatabaseErrorInfo;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    Res.Status(401);

    Res.Send(
      '{"success":false,"message":"Contexto de autenticação não encontrado."}'
    );

    Exit;
  end;

  EntityUuid :=
    Trim(
      Req.Params['uuid']
    );

  if EntityUuid = '' then
  begin
    Res.Status(400);

    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );

    Exit;
  end;

  try
    Deleted :=
      TEntityService.HardDelete(
        EntityUuid,
        LJwtContext.UserID,
        LJwtContext.TenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        ValidUuid,
        HasDependencies
      );

    //***************************************
    //* INVALID UUID
    //***************************************
    if not ValidUuid then
    begin
      Res.Status(400);

      Res.Send(
        '{"success":false,"message":"UUID da entidade inválido."}'
      );

      Exit;
    end;

    //***************************************
    //* HAS DEPENDENCIES
    //***************************************
    if HasDependencies then
    begin
      Res.Status(409);

      Res.Send(
        '{"success":false,"message":"A entidade não pode ser excluída definitivamente porque possui endereços cadastrados."}'
      );

      Exit;
    end;

    //***************************************
    //* NOT FOUND
    //***************************************
    if not Deleted then
    begin
      Res.Status(404);

      Res.Send(
        '{"success":false,"message":"Entidade não encontrada."}'
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(204);
    Res.Send('');

  except
    on E: Exception do
    begin
      //***************************************
      //* DATABASE ERROR HANDLER
      //***************************************
      LErrorInfo :=
        TDatabaseErrorHandler.Handle(
          E
        );

      //***************************************
      //* TECHNICAL LOG
      //***************************************
      TServerLogger.Error(
        'Entity.HardDelete' +
        sLineBreak +
        'UserID: ' +
        LJwtContext.UserID.ToString +
        sLineBreak +
        'TenantID: ' +
        LJwtContext.TenantID.ToString +
        sLineBreak +
        'EntityUUID: ' +
        EntityUuid +
        sLineBreak +
        LErrorInfo.Details
      );

      //***************************************
      //* CLIENT RESPONSE
      //***************************************
      Res.Status(500);

      Res.Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONFalse.Create
          )
          .AddPair(
            'message',
            LErrorInfo.UserMessage
          )
          .ToJSON
      );
    end;
  end;
end;

end.
