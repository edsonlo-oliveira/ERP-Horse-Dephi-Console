unit uEntityController;

interface

uses
  Horse;

type
  TEntityController = class
  public
    class procedure List(Req: THorseRequest; Res: THorseResponse);
    class procedure GetByUuid(Req: THorseRequest; Res: THorseResponse);
    class procedure Create(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Update(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse);
    class procedure HardDelete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uEntityService;

//***************************************
//* LIST
//***************************************
class procedure TEntityController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
begin
  Res.ContentType('application/json; charset=utf-8');

  Res.Send(
    TEntityService.List
  );
end;

//***************************************
//* GETBYUUID
//***************************************
class procedure TEntityController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  EntityUuid: string;
  JsonResult: string;
  ValidUuid: Boolean;
begin
  EntityUuid := Trim(
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

  JsonResult := TEntityService.GetByUuid(
    EntityUuid,
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

  Res.ContentType('application/json; charset=utf-8');
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
      JsonValue := JsonBody.GetValue('entity_type');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        EntityType := JsonValue.Value;

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('tax_id');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId := JsonValue.Value;

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
      // is_customer
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('is_customer');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsCustomer := SameText(
          JsonValue.Value,
          'true'
        );

      // ---------------------------------------------------------
      // is_supplier
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('is_supplier');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsSupplier := SameText(
          JsonValue.Value,
          'true'
        );

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
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult := TEntityService.Create(
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
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              'Erro interno ao criar entidade: ' + E.Message
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
begin
  Res.ContentType('application/json; charset=utf-8');

  EntityUuid := Req.Params['uuid'];

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
      JsonValue := JsonBody.GetValue('entity_type');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        EntityType := JsonValue.Value;

      // ---------------------------------------------------------
      // tax_id
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('tax_id');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId := JsonValue.Value;

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
      // is_customer
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('is_customer');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsCustomer := SameText(
          JsonValue.Value,
          'true'
        );

      // ---------------------------------------------------------
      // is_supplier
      // ---------------------------------------------------------
      JsonValue := JsonBody.GetValue('is_supplier');

      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        IsSupplier := SameText(
          JsonValue.Value,
          'true'
        );

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
      // Chama o Service
      // ---------------------------------------------------------
      JsonResult := TEntityService.Update(
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
        Res.Status(500);

        Res.Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONFalse.Create
            )
            .AddPair(
              'message',
              'Erro interno ao atualizar entidade: ' + E.Message
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
begin
  Res.ContentType('application/json; charset=utf-8');

  EntityUuid := Trim(Req.Params['uuid']);

  if EntityUuid = '' then
  begin
    Res.Status(400);
    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );
    Exit;
  end;

  Deleted := TEntityService.Delete(
    EntityUuid,
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

  if not Deleted then
  begin
    Res.Status(404);
    Res.Send(
      '{"success":false,"message":"Entidade não encontrada."}'
    );
    Exit;
  end;

  Res.Status(204);
  Res.Send('');
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
begin
  Res.ContentType('application/json; charset=utf-8');

  EntityUuid := Trim(Req.Params['uuid']);

  if EntityUuid = '' then
  begin
    Res.Status(400);
    Res.Send(
      '{"success":false,"message":"UUID da entidade não informado."}'
    );
    Exit;
  end;

  Deleted := TEntityService.HardDelete(
    EntityUuid,
    ValidUuid,
    HasDependencies
  );

  if not ValidUuid then
  begin
    Res.Status(400);
    Res.Send(
      '{"success":false,"message":"UUID da entidade inválido."}'
    );
    Exit;
  end;

  if HasDependencies then
  begin
    Res.Status(409);
    Res.Send(
      '{"success":false,"message":"A entidade não pode ser excluída definitivamente porque possui endereços cadastrados."}'
    );
    Exit;
  end;

  if not Deleted then
  begin
    Res.Status(404);
    Res.Send(
      '{"success":false,"message":"Entidade não encontrada."}'
    );
    Exit;
  end;

  Res.Status(204);
  Res.Send('');
end;

end.
