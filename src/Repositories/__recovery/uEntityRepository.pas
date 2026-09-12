unit uEntityRepository;

interface

type
  TEntityRepository = class
  public
    class function List: string;
    class function GetByUuid(const AEntityUuid: string): string;

    class function Create(
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string
    ): string;

    class function Update(
      const AEntityUuid: string;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string
    ): string;

    class function Delete(const AEntityUuid: string): Boolean;
    class function HardDelete(const AEntityUuid: string; out AHasDependencies: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uApiDatabase;

const
  // TEMPORÁRIO: será substituído pelo tenant do usuário autenticado.
  TEST_TENANT_ID: Int64 = 3;

class function TEntityRepository.List: string;
var
  Query: TFDQuery;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
begin
  Query := TFDQuery.Create(nil);
  JSONArray := TJSONArray.Create;
  try
    Query.Connection := TApiDatabase.Connection;

    Query.SQL.Text :=
      'SELECT ' +
      '    entity_id, ' +
      '    entity_uuid::text AS entity_uuid, ' +
      '    tenant_id, ' +
      '    entity_type, ' +
      '    tax_id, ' +
      '    legal_name, ' +
      '    trade_name, ' +
      '    state_registration, ' +
      '    municipal_registration, ' +
      '    is_customer, ' +
      '    is_supplier, ' +
      '    email, ' +
      '    phone, ' +
      '    mobile_phone, ' +
      '    active, ' +
      '    created_at, ' +
      '    updated_at, ' +
      '    deleted_at ' +
      'FROM master.entities ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL ' +
      'ORDER BY legal_name';

    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;

    Query.Open;

    while not Query.Eof do
    begin
      JSONObject := TJSONObject.Create;

      JSONObject.AddPair(
        'entity_id',
        TJSONNumber.Create(
          Query.FieldByName('entity_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_uuid',
        Query.FieldByName('entity_uuid').AsString
      );

      JSONObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(
          Query.FieldByName('tenant_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_type',
        Query.FieldByName('entity_type').AsString
      );

      if Query.FieldByName('tax_id').IsNull then
        JSONObject.AddPair(
          'tax_id',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'tax_id',
          Query.FieldByName('tax_id').AsString
        );

      JSONObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JSONObject.AddPair(
          'trade_name',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      if Query.FieldByName('state_registration').IsNull then
        JSONObject.AddPair(
          'state_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JSONObject.AddPair(
          'municipal_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      JSONObject.AddPair(
        'is_customer',
        TJSONBool.Create(
          Query.FieldByName('is_customer').AsBoolean
        )
      );

      JSONObject.AddPair(
        'is_supplier',
        TJSONBool.Create(
          Query.FieldByName('is_supplier').AsBoolean
        )
      );

      if Query.FieldByName('email').IsNull then
        JSONObject.AddPair(
          'email',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JSONObject.AddPair(
          'phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JSONObject.AddPair(
          'mobile_phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      JSONObject.AddPair(
        'active',
        TJSONBool.Create(
          Query.FieldByName('active').AsBoolean
        )
      );

      JSONObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JSONObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JSONObject.AddPair(
          'deleted_at',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      JSONArray.AddElement(JSONObject);

      Query.Next;
    end;

    Result := JSONArray.ToJSON;

  finally
    Query.Free;
    JSONArray.Free;
  end;
end;

class function TEntityRepository.GetByUuid(
  const AEntityUuid: string
): string;
var
  Query: TFDQuery;
  JSONObject: TJSONObject;
  EntityUuid: string;
begin
  Result := '';

  EntityUuid := StringReplace(
    Trim(AEntityUuid),
    '{',
    '',
    [rfReplaceAll]
  );

  EntityUuid := StringReplace(
    EntityUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := TApiDatabase.Connection;

    Query.SQL.Text :=
      'SELECT ' +
      '    entity_id, ' +
      '    entity_uuid::text AS entity_uuid, ' +
      '    tenant_id, ' +
      '    entity_type, ' +
      '    tax_id, ' +
      '    legal_name, ' +
      '    trade_name, ' +
      '    state_registration, ' +
      '    municipal_registration, ' +
      '    is_customer, ' +
      '    is_supplier, ' +
      '    email, ' +
      '    phone, ' +
      '    mobile_phone, ' +
      '    active, ' +
      '    created_at, ' +
      '    updated_at, ' +
      '    deleted_at ' +
      'FROM master.entities ' +
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL';

    Query.ParamByName('entity_uuid').AsString := EntityUuid;
    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;

    Query.Open;

    if Query.Eof then
      Exit;

    JSONObject := TJSONObject.Create;
    try
      JSONObject.AddPair(
        'entity_id',
        TJSONNumber.Create(
          Query.FieldByName('entity_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_uuid',
        Query.FieldByName('entity_uuid').AsString
      );

      JSONObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(
          Query.FieldByName('tenant_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_type',
        Query.FieldByName('entity_type').AsString
      );

      if Query.FieldByName('tax_id').IsNull then
        JSONObject.AddPair(
          'tax_id',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'tax_id',
          Query.FieldByName('tax_id').AsString
        );

      JSONObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JSONObject.AddPair(
          'trade_name',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      if Query.FieldByName('state_registration').IsNull then
        JSONObject.AddPair(
          'state_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JSONObject.AddPair(
          'municipal_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      JSONObject.AddPair(
        'is_customer',
        TJSONBool.Create(
          Query.FieldByName('is_customer').AsBoolean
        )
      );

      JSONObject.AddPair(
        'is_supplier',
        TJSONBool.Create(
          Query.FieldByName('is_supplier').AsBoolean
        )
      );

      if Query.FieldByName('email').IsNull then
        JSONObject.AddPair(
          'email',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JSONObject.AddPair(
          'phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JSONObject.AddPair(
          'mobile_phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      JSONObject.AddPair(
        'active',
        TJSONBool.Create(
          Query.FieldByName('active').AsBoolean
        )
      );

      JSONObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JSONObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JSONObject.AddPair(
          'deleted_at',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      Result := JSONObject.ToJSON;

    finally
      JSONObject.Free;
    end;

  finally
    Query.Free;
  end;
end;

class function TEntityRepository.Create(
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string
): string;
var
  Query: TFDQuery;
  JSONObject: TJSONObject;
begin
  Result := '';

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := TApiDatabase.Connection;

    Query.SQL.Text :=
      'INSERT INTO master.entities (' +
      '    tenant_id, ' +
      '    entity_type, ' +
      '    tax_id, ' +
      '    legal_name, ' +
      '    trade_name, ' +
      '    is_customer, ' +
      '    is_supplier, ' +
      '    email, ' +
      '    phone, ' +
      '    mobile_phone ' +
      ') VALUES (' +
      '    :tenant_id, ' +
      '    :entity_type, ' +
      '    :tax_id, ' +
      '    :legal_name, ' +
      '    :trade_name, ' +
      '    :is_customer, ' +
      '    :is_supplier, ' +
      '    :email, ' +
      '    :phone, ' +
      '    :mobile_phone ' +
      ') ' +
      'RETURNING ' +
      '    entity_id, ' +
      '    entity_uuid::text AS entity_uuid, ' +
      '    tenant_id, ' +
      '    entity_type, ' +
      '    tax_id, ' +
      '    legal_name, ' +
      '    trade_name, ' +
      '    state_registration, ' +
      '    municipal_registration, ' +
      '    is_customer, ' +
      '    is_supplier, ' +
      '    email, ' +
      '    phone, ' +
      '    mobile_phone, ' +
      '    active, ' +
      '    created_at, ' +
      '    updated_at, ' +
      '    deleted_at';

    Query.ParamByName('tenant_id').AsLargeInt :=
      TEST_TENANT_ID;

    Query.ParamByName('entity_type').AsString :=
      AEntityType;

    if Trim(ATaxId) = '' then
      Query.ParamByName('tax_id').Clear
    else
      Query.ParamByName('tax_id').AsString :=
        ATaxId;

    Query.ParamByName('legal_name').AsString :=
      ALegalName;

    if Trim(ATradeName) = '' then
      Query.ParamByName('trade_name').Clear
    else
      Query.ParamByName('trade_name').AsString :=
        ATradeName;

    Query.ParamByName('is_customer').AsBoolean :=
      AIsCustomer;

    Query.ParamByName('is_supplier').AsBoolean :=
      AIsSupplier;

    if Trim(AEmail) = '' then
      Query.ParamByName('email').Clear
    else
      Query.ParamByName('email').AsString :=
        AEmail;

    if Trim(APhone) = '' then
      Query.ParamByName('phone').Clear
    else
      Query.ParamByName('phone').AsString :=
        APhone;

    if Trim(AMobilePhone) = '' then
      Query.ParamByName('mobile_phone').Clear
    else
      Query.ParamByName('mobile_phone').AsString :=
        AMobilePhone;

    Query.Open;

    JSONObject := TJSONObject.Create;
    try
      JSONObject.AddPair(
        'entity_id',
        TJSONNumber.Create(
          Query.FieldByName('entity_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_uuid',
        Query.FieldByName('entity_uuid').AsString
      );

      JSONObject.AddPair(
        'tenant_id',
        TJSONNumber.Create(
          Query.FieldByName('tenant_id').AsLargeInt
        )
      );

      JSONObject.AddPair(
        'entity_type',
        Query.FieldByName('entity_type').AsString
      );

      if Query.FieldByName('tax_id').IsNull then
        JSONObject.AddPair(
          'tax_id',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'tax_id',
          Query.FieldByName('tax_id').AsString
        );

      JSONObject.AddPair(
        'legal_name',
        Query.FieldByName('legal_name').AsString
      );

      if Query.FieldByName('trade_name').IsNull then
        JSONObject.AddPair(
          'trade_name',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'trade_name',
          Query.FieldByName('trade_name').AsString
        );

      if Query.FieldByName('state_registration').IsNull then
        JSONObject.AddPair(
          'state_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'state_registration',
          Query.FieldByName('state_registration').AsString
        );

      if Query.FieldByName('municipal_registration').IsNull then
        JSONObject.AddPair(
          'municipal_registration',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'municipal_registration',
          Query.FieldByName('municipal_registration').AsString
        );

      JSONObject.AddPair(
        'is_customer',
        TJSONBool.Create(
          Query.FieldByName('is_customer').AsBoolean
        )
      );

      JSONObject.AddPair(
        'is_supplier',
        TJSONBool.Create(
          Query.FieldByName('is_supplier').AsBoolean
        )
      );

      if Query.FieldByName('email').IsNull then
        JSONObject.AddPair(
          'email',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'email',
          Query.FieldByName('email').AsString
        );

      if Query.FieldByName('phone').IsNull then
        JSONObject.AddPair(
          'phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'phone',
          Query.FieldByName('phone').AsString
        );

      if Query.FieldByName('mobile_phone').IsNull then
        JSONObject.AddPair(
          'mobile_phone',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'mobile_phone',
          Query.FieldByName('mobile_phone').AsString
        );

      JSONObject.AddPair(
        'active',
        TJSONBool.Create(
          Query.FieldByName('active').AsBoolean
        )
      );

      JSONObject.AddPair(
        'created_at',
        Query.FieldByName('created_at').AsString
      );

      JSONObject.AddPair(
        'updated_at',
        Query.FieldByName('updated_at').AsString
      );

      if Query.FieldByName('deleted_at').IsNull then
        JSONObject.AddPair(
          'deleted_at',
          TJSONNull.Create
        )
      else
        JSONObject.AddPair(
          'deleted_at',
          Query.FieldByName('deleted_at').AsString
        );

      Result := JSONObject.ToJSON;

    finally
      JSONObject.Free;
    end;

  finally
    Query.Free;
  end;
end;

class function TEntityRepository.Delete(const AEntityUuid: string): Boolean;
var
  Query: TFDQuery;
begin

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := TApiDatabase.Connection;

    Query.SQL.Text :=
      'UPDATE master.entities SET ' +
      '    deleted_at = CURRENT_TIMESTAMP, ' +
      '    active = FALSE, ' +
      '    updated_at = CURRENT_TIMESTAMP ' +
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL';

    Query.ParamByName('entity_uuid').AsString := AEntityUuid;
    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;

    Query.ExecSQL;

    Result := Query.RowsAffected > 0;

  finally
    Query.Free;
  end;
end;

class function TEntityRepository.HardDelete(
  const AEntityUuid: string;
  out AHasDependencies: Boolean
): Boolean;
var
  Query: TFDQuery;
  EntityId: Int64;
begin
  Result := False;
  AHasDependencies := False;

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := TApiDatabase.Connection;

    // Localiza a entidade pelo UUID e tenant.
    Query.SQL.Text :=
      'SELECT entity_id ' +
      'FROM master.entities ' +
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id';

    Query.ParamByName('entity_uuid').AsString := AEntityUuid;
    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;

    Query.Open;

    if Query.Eof then
      Exit;

    EntityId := Query.FieldByName('entity_id').AsLargeInt;

    Query.Close;

    // Verifica dependências em entity_addresses.
    Query.SQL.Text :=
      'SELECT COUNT(*) AS dependency_count ' +
      'FROM master.entity_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND entity_id = :entity_id';

    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;
    Query.ParamByName('entity_id').AsLargeInt := EntityId;

    Query.Open;

    AHasDependencies :=
      Query.FieldByName('dependency_count').AsLargeInt > 0;

    Query.Close;

    if AHasDependencies then
      Exit;

    // Exclusão física.
    Query.SQL.Text :=
      'DELETE FROM master.entities ' +
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id';

    Query.ParamByName('entity_uuid').AsString := AEntityUuid;
    Query.ParamByName('tenant_id').AsLargeInt := TEST_TENANT_ID;

    Query.ExecSQL;

    Result := Query.RowsAffected > 0;

  finally
    Query.Free;
  end;
end;

end.
