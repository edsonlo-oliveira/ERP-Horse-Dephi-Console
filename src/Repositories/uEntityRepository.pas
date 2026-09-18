unit uEntityRepository;

interface

type
  TEntityRepository = class
  public
    class function List(
      const ATenantID: Int64;
      const AGlobalScope: Boolean
    ): string;

    class function GetByUuid(
      const AEntityUuid: string;
      const ATenantID: Int64;
      const AGlobalScope: Boolean
    ): string;

    class function Create(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string
    ): string;

    class function Delete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string
    ): Boolean;

    class function HardDelete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      out AHasDependencies: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uApiDatabase;


//***************************************
//* AUDIT CONTEXT
//***************************************
procedure SetAuditContext(
  const AConnection: TFDConnection;
  const AUserID: Int64;
  const ATenantID: Int64
);
var
  ContextQuery: TFDQuery;
begin
  ContextQuery := TFDQuery.Create(nil);
  try
    ContextQuery.Connection := AConnection;

    ContextQuery.SQL.Text :=
      'SELECT ' +
      'set_config(''app.user_id'', :user_id, true), ' +
      'set_config(''app.tenant_id'', :tenant_id, true)';

    ContextQuery.ParamByName('user_id').AsString :=
      AUserID.ToString;

    ContextQuery.ParamByName('tenant_id').AsString :=
      ATenantID.ToString;

    ContextQuery.Open;

  finally
    ContextQuery.Free;
  end;
end;


//***************************************
//* ENTITY JSON
//***************************************
function EntityToJson(
  const AQuery: TFDQuery
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'entity_id',
    TJSONNumber.Create(
      AQuery.FieldByName('entity_id').AsLargeInt
    )
  );

  Result.AddPair(
    'entity_uuid',
    AQuery.FieldByName('entity_uuid').AsString
  );

  Result.AddPair(
    'tenant_id',
    TJSONNumber.Create(
      AQuery.FieldByName('tenant_id').AsLargeInt
    )
  );

  Result.AddPair(
    'entity_type',
    AQuery.FieldByName('entity_type').AsString
  );

  if AQuery.FieldByName('tax_id').IsNull then
    Result.AddPair(
      'tax_id',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'tax_id',
      AQuery.FieldByName('tax_id').AsString
    );

  Result.AddPair(
    'legal_name',
    AQuery.FieldByName('legal_name').AsString
  );

  if AQuery.FieldByName('trade_name').IsNull then
    Result.AddPair(
      'trade_name',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'trade_name',
      AQuery.FieldByName('trade_name').AsString
    );

  if AQuery.FieldByName('state_registration').IsNull then
    Result.AddPair(
      'state_registration',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'state_registration',
      AQuery.FieldByName('state_registration').AsString
    );

  if AQuery.FieldByName('municipal_registration').IsNull then
    Result.AddPair(
      'municipal_registration',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'municipal_registration',
      AQuery.FieldByName('municipal_registration').AsString
    );

  Result.AddPair(
    'is_customer',
    TJSONBool.Create(
      AQuery.FieldByName('is_customer').AsBoolean
    )
  );

  Result.AddPair(
    'is_supplier',
    TJSONBool.Create(
      AQuery.FieldByName('is_supplier').AsBoolean
    )
  );

  if AQuery.FieldByName('email').IsNull then
    Result.AddPair(
      'email',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'email',
      AQuery.FieldByName('email').AsString
    );

  if AQuery.FieldByName('phone').IsNull then
    Result.AddPair(
      'phone',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'phone',
      AQuery.FieldByName('phone').AsString
    );

  if AQuery.FieldByName('mobile_phone').IsNull then
    Result.AddPair(
      'mobile_phone',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'mobile_phone',
      AQuery.FieldByName('mobile_phone').AsString
    );

  Result.AddPair(
    'active',
    TJSONBool.Create(
      AQuery.FieldByName('active').AsBoolean
    )
  );

  Result.AddPair(
    'created_at',
    AQuery.FieldByName('created_at').AsString
  );

  Result.AddPair(
    'updated_at',
    AQuery.FieldByName('updated_at').AsString
  );

  if AQuery.FieldByName('deleted_at').IsNull then
    Result.AddPair(
      'deleted_at',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'deleted_at',
      AQuery.FieldByName('deleted_at').AsString
    );
end;


//***************************************
//* LIST
//***************************************
class function TEntityRepository.List(
  const ATenantID: Int64;
  const AGlobalScope: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JSONArray: TJSONArray;
begin
  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  JSONArray := TJSONArray.Create;

  try
    Query.Connection := Connection;

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
      'FROM master.entities ';

    if AGlobalScope then
    begin
      Query.SQL.Add(
        'WHERE deleted_at IS NULL '
      );
    end
    else
    begin
      Query.SQL.Add(
        'WHERE tenant_id = :tenant_id ' +
        '  AND deleted_at IS NULL '
      );

      Query.ParamByName('tenant_id').AsLargeInt :=
        ATenantID;
    end;

    Query.SQL.Add(
      'ORDER BY legal_name'
    );

    Query.Open;

    while not Query.Eof do
    begin
      JSONArray.AddElement(
        EntityToJson(Query)
      );

      Query.Next;
    end;

    Result := JSONArray.ToJSON;

  finally
    JSONArray.Free;
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* GET BY UUID
//***************************************
class function TEntityRepository.GetByUuid(
  const AEntityUuid: string;
  const ATenantID: Int64;
  const AGlobalScope: Boolean
): string;
var
  Connection: TFDConnection;
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

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);

  try
    Query.Connection := Connection;

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
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ';

    if not AGlobalScope then
      Query.SQL.Add(
        '  AND tenant_id = :tenant_id '
      );

    Query.SQL.Add(
      '  AND deleted_at IS NULL'
    );

    Query.ParamByName('entity_uuid').AsString :=
      EntityUuid;

    if not AGlobalScope then
      Query.ParamByName('tenant_id').AsLargeInt :=
        ATenantID;

    Query.Open;

    if Query.Eof then
      Exit;

    JSONObject := EntityToJson(Query);

    try
      Result := JSONObject.ToJSON;
    finally
      JSONObject.Free;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* CREATE
//***************************************
class function TEntityRepository.Create(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JSONObject: TJSONObject;
begin
  Result := '';

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);

  try
    Query.Connection := Connection;

    Connection.StartTransaction;

    try
      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        Connection,
        AUserID,
        ATenantID
      );

      //***************************************
      //* INSERT
      //***************************************
      Query.SQL.Text :=
        'INSERT INTO master.entities (' +
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
        '    mobile_phone ' +
        ') VALUES (' +
        '    :tenant_id, ' +
        '    :entity_type, ' +
        '    :tax_id, ' +
        '    :legal_name, ' +
        '    :trade_name, ' +
        '    :state_registration, ' +
        '    :municipal_registration, ' +
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
        ATenantID;

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

      if Trim(AStateRegistration) = '' then
        Query.ParamByName('state_registration').Clear
      else
        Query.ParamByName('state_registration').AsString :=
          AStateRegistration;

      if Trim(AMunicipalRegistration) = '' then
        Query.ParamByName('municipal_registration').Clear
      else
        Query.ParamByName('municipal_registration').AsString :=
          AMunicipalRegistration;

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

      JSONObject := EntityToJson(Query);

      try
        Result := JSONObject.ToJSON;
      finally
        JSONObject.Free;
      end;

      Connection.Commit;

    except
      if Connection.InTransaction then
        Connection.Rollback;

      raise;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* UPDATE
//***************************************
class function TEntityRepository.Update(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  ResolveQuery: TFDQuery;
  JSONObject: TJSONObject;
  EffectiveTenantID: Int64;
begin
  Result := '';

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  ResolveQuery := TFDQuery.Create(nil);

  try
    Query.Connection := Connection;
    ResolveQuery.Connection := Connection;

    Connection.StartTransaction;

    try
      //***************************************
      //* RESOLVE TARGET TENANT
      //***************************************
      ResolveQuery.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM master.entities ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ';

      if not AGlobalScope then
        ResolveQuery.SQL.Add(
          '  AND tenant_id = :tenant_id'
        );

      ResolveQuery.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      if not AGlobalScope then
        ResolveQuery.ParamByName('tenant_id').AsLargeInt :=
          ATenantID;

      ResolveQuery.Open;

      if ResolveQuery.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      EffectiveTenantID :=
        ResolveQuery.FieldByName('tenant_id').AsLargeInt;

      ResolveQuery.Close;

      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        Connection,
        AUserID,
        EffectiveTenantID
      );

      //***************************************
      //* UPDATE
      //***************************************
      Query.SQL.Text :=
        'UPDATE master.entities SET ' +
        '    entity_type = :entity_type, ' +
        '    tax_id = :tax_id, ' +
        '    legal_name = :legal_name, ' +
        '    trade_name = :trade_name, ' +
        '    state_registration = :state_registration, ' +
        '    municipal_registration = :municipal_registration, ' +
        '    is_customer = :is_customer, ' +
        '    is_supplier = :is_supplier, ' +
        '    email = :email, ' +
        '    phone = :phone, ' +
        '    mobile_phone = :mobile_phone, ' +
        '    updated_at = CURRENT_TIMESTAMP ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND tenant_id = :tenant_id ' +
        '  AND deleted_at IS NULL ' +
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

      Query.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      Query.ParamByName('tenant_id').AsLargeInt :=
        EffectiveTenantID;

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

      if Trim(AStateRegistration) = '' then
        Query.ParamByName('state_registration').Clear
      else
        Query.ParamByName('state_registration').AsString :=
          AStateRegistration;

      if Trim(AMunicipalRegistration) = '' then
        Query.ParamByName('municipal_registration').Clear
      else
        Query.ParamByName('municipal_registration').AsString :=
          AMunicipalRegistration;

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

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      JSONObject := EntityToJson(Query);

      try
        Result := JSONObject.ToJSON;
      finally
        JSONObject.Free;
      end;

      Connection.Commit;

    except
      if Connection.InTransaction then
        Connection.Rollback;

      raise;
    end;

  finally
    ResolveQuery.Free;
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* SOFT DELETE
//***************************************
class function TEntityRepository.Delete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  ResolveQuery: TFDQuery;
  EffectiveTenantID: Int64;
begin
  Result := False;

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  ResolveQuery := TFDQuery.Create(nil);

  try
    Query.Connection := Connection;
    ResolveQuery.Connection := Connection;

    Connection.StartTransaction;

    try
      //***************************************
      //* RESOLVE TARGET TENANT
      //***************************************
      ResolveQuery.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM master.entities ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ';

      if not AGlobalScope then
        ResolveQuery.SQL.Add(
          '  AND tenant_id = :tenant_id'
        );

      ResolveQuery.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      if not AGlobalScope then
        ResolveQuery.ParamByName('tenant_id').AsLargeInt :=
          ATenantID;

      ResolveQuery.Open;

      if ResolveQuery.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      EffectiveTenantID :=
        ResolveQuery.FieldByName('tenant_id').AsLargeInt;

      ResolveQuery.Close;

      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        Connection,
        AUserID,
        EffectiveTenantID
      );

      //***************************************
      //* SOFT DELETE
      //***************************************
      Query.SQL.Text :=
        'UPDATE master.entities SET ' +
        '    deleted_at = CURRENT_TIMESTAMP, ' +
        '    active = FALSE, ' +
        '    updated_at = CURRENT_TIMESTAMP ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND tenant_id = :tenant_id ' +
        '  AND deleted_at IS NULL';

      Query.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      Query.ParamByName('tenant_id').AsLargeInt :=
        EffectiveTenantID;

      Query.ExecSQL;

      Result :=
        Query.RowsAffected > 0;

      Connection.Commit;

    except
      if Connection.InTransaction then
        Connection.Rollback;

      raise;
    end;

  finally
    ResolveQuery.Free;
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* HARD DELETE
//***************************************
class function TEntityRepository.HardDelete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  out AHasDependencies: Boolean
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  EffectiveTenantID: Int64;
  EntityId: Int64;
begin
  Result := False;
  AHasDependencies := False;

  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);

  try
    Query.Connection := Connection;

    Connection.StartTransaction;

    try
      //***************************************
      //* LOCALIZA A ENTIDADE
      //* E RESOLVE O TENANT REAL
      //***************************************
      Query.SQL.Text :=
        'SELECT ' +
        '    entity_id, ' +
        '    tenant_id ' +
        'FROM master.entities ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ';

      if not AGlobalScope then
        Query.SQL.Add(
          '  AND tenant_id = :tenant_id'
        );

      Query.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      if not AGlobalScope then
        Query.ParamByName('tenant_id').AsLargeInt :=
          ATenantID;

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      EntityId :=
        Query.FieldByName('entity_id').AsLargeInt;

      EffectiveTenantID :=
        Query.FieldByName('tenant_id').AsLargeInt;

      Query.Close;

      //***************************************
      //* VERIFICA DEPENDÊNCIAS
      //***************************************
      Query.SQL.Text :=
        'SELECT COUNT(*) AS dependency_count ' +
        'FROM master.entity_addresses ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND entity_id = :entity_id';

      Query.ParamByName('tenant_id').AsLargeInt :=
        EffectiveTenantID;

      Query.ParamByName('entity_id').AsLargeInt :=
        EntityId;

      Query.Open;

      AHasDependencies :=
        Query.FieldByName('dependency_count').AsLargeInt > 0;

      Query.Close;

      if AHasDependencies then
      begin
        Connection.Commit;
        Exit;
      end;

      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        Connection,
        AUserID,
        EffectiveTenantID
      );

      //***************************************
      //* HARD DELETE
      //***************************************
      Query.SQL.Text :=
        'DELETE FROM master.entities ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND tenant_id = :tenant_id';

      Query.ParamByName('entity_uuid').AsString :=
        AEntityUuid;

      Query.ParamByName('tenant_id').AsLargeInt :=
        EffectiveTenantID;

      Query.ExecSQL;

      Result :=
        Query.RowsAffected > 0;

      Connection.Commit;

    except
      if Connection.InTransaction then
        Connection.Rollback;

      raise;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

end.
