unit uEntityController;

interface

uses
  Horse;

type
  TEntityController = class
  public
    class procedure List(Req: THorseRequest; Res: THorseResponse);
    class procedure GetByUuid(Req: THorseRequest; Res: THorseResponse);
    class procedure Create(Req: THorseRequest; Res: THorseResponse);
    class procedure Update(Req: THorseRequest; Res: THorseResponse);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse);
    class procedure HardDelete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uEntityService;

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

class procedure TEntityController.Create(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  JsonBody: TJSONObject;
  EntityType: string;
  TaxId: string;
  LegalName: string;
  TradeName: string;
  Email: string;
  Phone: string;
  MobilePhone: string;
  IsCustomer: Boolean;
  IsSupplier: Boolean;
  JsonResult: string;
  ErrorMessage: string;
  JsonValue: TJSONValue;
begin
  Res.ContentType('application/json; charset=utf-8');

  JsonBody := nil;

  try
    try
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

      EntityType := '';
      TaxId := '';
      LegalName := '';
      TradeName := '';
      Email := '';
      Phone := '';
      MobilePhone := '';

      IsCustomer := True;
      IsSupplier := False;

      JsonValue := JsonBody.GetValue('entity_type');
      if Assigned(JsonValue) then
        EntityType := JsonValue.Value;

      JsonValue := JsonBody.GetValue('tax_id');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId := JsonValue.Value;

      JsonValue := JsonBody.GetValue('legal_name');
      if Assigned(JsonValue) then
        LegalName := JsonValue.Value;

      JsonValue := JsonBody.GetValue('trade_name');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TradeName := JsonValue.Value;

      JsonValue := JsonBody.GetValue('is_customer');
      if Assigned(JsonValue) then
        IsCustomer := JsonValue.Value.ToBoolean;

      JsonValue := JsonBody.GetValue('is_supplier');
      if Assigned(JsonValue) then
        IsSupplier := JsonValue.Value.ToBoolean;

      JsonValue := JsonBody.GetValue('email');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Email := JsonValue.Value;

      JsonValue := JsonBody.GetValue('phone');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Phone := JsonValue.Value;

      JsonValue := JsonBody.GetValue('mobile_phone');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MobilePhone := JsonValue.Value;

    except
      on E: Exception do
      begin
        Res.Status(400);
        Res.Send(
          '{"success":false,"message":"Erro ao processar o JSON enviado."}'
        );
        Exit;
      end;
    end;

    JsonResult := TEntityService.Create(
      EntityType,
      TaxId,
      LegalName,
      TradeName,
      IsCustomer,
      IsSupplier,
      Email,
      Phone,
      MobilePhone,
      ErrorMessage
    );

    if ErrorMessage <> '' then
    begin
      Res.Status(400);
      Res.Send(
        '{"success":false,"message":"' +
        StringReplace(
          ErrorMessage,
          '"',
          '\"',
          [rfReplaceAll]
        ) +
        '"}'
      );
      Exit;
    end;

    Res.Status(201);
    Res.Send(JsonResult);

  finally
    JsonBody.Free;
  end;
end;

class procedure TEntityController.Update(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  JsonBody: TJSONObject;
  EntityUuid: string;
  EntityType: string;
  TaxId: string;
  LegalName: string;
  TradeName: string;
  Email: string;
  Phone: string;
  MobilePhone: string;
  IsCustomer: Boolean;
  IsSupplier: Boolean;
  JsonResult: string;
  ErrorMessage: string;
  JsonValue: TJSONValue;
  ValidUuid: Boolean;
begin
  Res.ContentType('application/json; charset=utf-8');

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

  JsonBody := nil;

  try
    try
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

      EntityType := '';
      TaxId := '';
      LegalName := '';
      TradeName := '';
      Email := '';
      Phone := '';
      MobilePhone := '';

      IsCustomer := True;
      IsSupplier := False;

      JsonValue := JsonBody.GetValue('entity_type');
      if Assigned(JsonValue) then
        EntityType := JsonValue.Value;

      JsonValue := JsonBody.GetValue('tax_id');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TaxId := JsonValue.Value;

      JsonValue := JsonBody.GetValue('legal_name');
      if Assigned(JsonValue) then
        LegalName := JsonValue.Value;

      JsonValue := JsonBody.GetValue('trade_name');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        TradeName := JsonValue.Value;

      JsonValue := JsonBody.GetValue('is_customer');
      if Assigned(JsonValue) then
        IsCustomer := JsonValue.Value.ToBoolean;

      JsonValue := JsonBody.GetValue('is_supplier');
      if Assigned(JsonValue) then
        IsSupplier := JsonValue.Value.ToBoolean;

      JsonValue := JsonBody.GetValue('email');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Email := JsonValue.Value;

      JsonValue := JsonBody.GetValue('phone');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        Phone := JsonValue.Value;

      JsonValue := JsonBody.GetValue('mobile_phone');
      if Assigned(JsonValue) and
         not (JsonValue is TJSONNull) then
        MobilePhone := JsonValue.Value;

    except
      on E: Exception do
      begin
        Res.Status(400);
        Res.Send(
          '{"success":false,"message":"Erro ao processar o JSON enviado."}'
        );
        Exit;
      end;
    end;

    JsonResult := TEntityService.Update(
      EntityUuid,
      EntityType,
      TaxId,
      LegalName,
      TradeName,
      IsCustomer,
      IsSupplier,
      Email,
      Phone,
      MobilePhone,
      ValidUuid,
      ErrorMessage
    );

    if ErrorMessage <> '' then
    begin
      Res.Status(400);
      Res.Send(
        '{"success":false,"message":"' +
        StringReplace(
          ErrorMessage,
          '"',
          '\"',
          [rfReplaceAll]
        ) +
        '"}'
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

  finally
    JsonBody.Free;
  end;
end;

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
