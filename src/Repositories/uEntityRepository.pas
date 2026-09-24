unit uEntityRepository;

interface

uses
  FireDAC.Comp.Client, Data.DB, uAuditContext;

type
  TEntityRepository = class
  private
    class function IsValidSortField(
      const AConnection: TFDConnection;
      const AFieldName: string
    ): Boolean; static;

  public
    class function List(
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const ASearch: string;
      const APage: Integer;
      const APageSize: Integer;
      const ASortField: string;
      const ASortAscending: Boolean
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

    class function SetActive(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AActive: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  FireDAC.Stan.Param,
  uApiDatabase;


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
  const AGlobalScope: Boolean;
  const ASearch: string;
  const APage: Integer;
  const APageSize: Integer;
  const ASortField: string;
  const ASortAscending: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  CountQuery: TFDQuery;

  JSONArray: TJSONArray;
  JSONResult: TJSONObject;

  LSearch: string;
  LOffset: Integer;
  LSortField: string;
  LSortDirection: string;

  LTotalRecords: Int64;
  LTotalPages: Integer;
begin
  Connection := TApiDatabase.NewConnection;
  Query := TFDQuery.Create(nil);
  CountQuery := TFDQuery.Create(nil);

  JSONArray := TJSONArray.Create;
  JSONResult := TJSONObject.Create;

  try
    Query.Connection := Connection;
    CountQuery.Connection := Connection;

    LSearch := Trim(ASearch);
    LOffset := (APage - 1) * APageSize;

    //***************************************
    //* SORT
    //***************************************
    LSortField :=
      LowerCase(
        Trim(ASortField)
      );

    if not IsValidSortField(
      Connection,
      LSortField
    ) then
    begin
      LSortField :=
        'legal_name';
    end;

    if ASortAscending then
      LSortDirection := 'ASC'
    else
      LSortDirection := 'DESC';

    //***************************************
    //* COUNT
    //***************************************
    CountQuery.SQL.Text :=
      'SELECT COUNT(*) AS total_records ' +
      'FROM master.entities ' +
      'WHERE deleted_at IS NULL ';

    if not AGlobalScope then
    begin
      CountQuery.SQL.Add(
        'AND tenant_id = :tenant_id '
      );

      CountQuery.ParamByName('tenant_id').AsLargeInt :=
        ATenantID;
    end;

    if LSearch <> '' then
    begin
      CountQuery.SQL.Add(
        'AND ( ' +
        '       legal_name ILIKE :search ' +
        '    OR trade_name ILIKE :search ' +
        '    OR tax_id ILIKE :search ' +
        '    OR email ILIKE :search ' +
        '    OR phone ILIKE :search ' +
        '    OR mobile_phone ILIKE :search ' +
        ') '
      );

      CountQuery.ParamByName('search').AsString :=
        '%' + LSearch + '%';
    end;

    CountQuery.Open;

    LTotalRecords :=
      CountQuery.FieldByName('total_records').AsLargeInt;

    if LTotalRecords = 0 then
      LTotalPages := 0
    else
      LTotalPages :=
        (LTotalRecords + APageSize - 1) div APageSize;

    //***************************************
    //* DATA
    //***************************************
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
      'WHERE deleted_at IS NULL ';

    if not AGlobalScope then
    begin
      Query.SQL.Add(
        'AND tenant_id = :tenant_id '
      );

      Query.ParamByName('tenant_id').AsLargeInt :=
        ATenantID;
    end;

    if LSearch <> '' then
    begin
      Query.SQL.Add(
        'AND ( ' +
        '       legal_name ILIKE :search ' +
        '    OR trade_name ILIKE :search ' +
        '    OR tax_id ILIKE :search ' +
        '    OR email ILIKE :search ' +
        '    OR phone ILIKE :search ' +
        '    OR mobile_phone ILIKE :search ' +
        ') '
      );

      Query.ParamByName('search').AsString :=
        '%' + LSearch + '%';
    end;

    Query.SQL.Add(
      'ORDER BY "' +
      LSortField +
      '" ' +
      LSortDirection + ' '
    );

    Query.SQL.Add(
      'LIMIT :page_size ' +
      'OFFSET :offset'
    );

    Query.ParamByName('page_size').AsInteger :=
      APageSize;

    Query.ParamByName('offset').AsInteger :=
      LOffset;

    Query.Open;

    while not Query.Eof do
    begin
      JSONArray.AddElement(
        EntityToJson(Query)
      );

      Query.Next;
    end;

    //***************************************
    //* RESULT
    //***************************************
    JSONResult.AddPair(
      'page',
      TJSONNumber.Create(APage)
    );

    JSONResult.AddPair(
      'page_size',
      TJSONNumber.Create(APageSize)
    );

    JSONResult.AddPair(
      'total_records',
      TJSONNumber.Create(LTotalRecords)
    );

    JSONResult.AddPair(
      'total_pages',
      TJSONNumber.Create(LTotalPages)
    );

    JSONResult.AddPair(
      'data',
      JSONArray
    );

    JSONArray := nil;

    Result := JSONResult.ToJSON;

  finally
    JSONArray.Free;
    JSONResult.Free;

    CountQuery.Free;
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

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

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

      //***************************************
      //* TENANT ID
      //***************************************
      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      //***************************************
      //* ENTITY TYPE
      //***************************************
      Query.ParamByName(
        'entity_type'
      ).AsString :=
        Trim(AEntityType);

      //***************************************
      //* TAX ID
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('tax_id') do
      begin
        DataType :=
          ftString;

        if Trim(ATaxId) = '' then
          Clear
        else
          AsString :=
            Trim(ATaxId);
      end;

      //***************************************
      //* LEGAL NAME
      //***************************************
      Query.ParamByName(
        'legal_name'
      ).AsString :=
        Trim(ALegalName);

      //***************************************
      //* TRADE NAME
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('trade_name') do
      begin
        DataType :=
          ftString;

        if Trim(ATradeName) = '' then
          Clear
        else
          AsString :=
            Trim(ATradeName);
      end;

      //***************************************
      //* STATE REGISTRATION
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('state_registration') do
      begin
        DataType :=
          ftString;

        if Trim(AStateRegistration) = '' then
          Clear
        else
          AsString :=
            Trim(AStateRegistration);
      end;

      //***************************************
      //* MUNICIPAL REGISTRATION
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('municipal_registration') do
      begin
        DataType :=
          ftString;

        if Trim(AMunicipalRegistration) = '' then
          Clear
        else
          AsString :=
            Trim(AMunicipalRegistration);
      end;

      //***************************************
      //* IS CUSTOMER
      //***************************************
      Query.ParamByName(
        'is_customer'
      ).AsBoolean :=
        AIsCustomer;

      //***************************************
      //* IS SUPPLIER
      //***************************************
      Query.ParamByName(
        'is_supplier'
      ).AsBoolean :=
        AIsSupplier;

      //***************************************
      //* EMAIL
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('email') do
      begin
        DataType :=
          ftString;

        if Trim(AEmail) = '' then
          Clear
        else
          AsString :=
            Trim(AEmail);
      end;

      //***************************************
      //* PHONE
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('phone') do
      begin
        DataType :=
          ftString;

        if Trim(APhone) = '' then
          Clear
        else
          AsString :=
            Trim(APhone);
      end;

      //***************************************
      //* MOBILE PHONE
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('mobile_phone') do
      begin
        DataType :=
          ftString;

        if Trim(AMobilePhone) = '' then
          Clear
        else
          AsString :=
            Trim(AMobilePhone);
      end;

      //***************************************
      //* EXECUTE / RETURNING
      //***************************************
      Query.Open;

      //***************************************
      //* JSON RESULT
      //***************************************
      JSONObject :=
        EntityToJson(
          Query
        );

      try
        Result :=
          JSONObject.ToJSON;
      finally
        JSONObject.Free;
      end;

      //***************************************
      //* COMMIT
      //***************************************
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
      begin
        ResolveQuery.SQL.Add(
          '  AND tenant_id = :tenant_id'
        );
      end;

      ResolveQuery.ParamByName(
        'entity_uuid'
      ).AsString :=
        AEntityUuid;

      if not AGlobalScope then
      begin
        ResolveQuery.ParamByName(
          'tenant_id'
        ).AsLargeInt :=
          ATenantID;
      end;

      ResolveQuery.Open;

      if ResolveQuery.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      EffectiveTenantID :=
        ResolveQuery.FieldByName(
          'tenant_id'
        ).AsLargeInt;

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

      //***************************************
      //* ENTITY UUID
      //***************************************
      Query.ParamByName(
        'entity_uuid'
      ).AsString :=
        AEntityUuid;

      //***************************************
      //* TENANT ID
      //***************************************
      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        EffectiveTenantID;

      //***************************************
      //* ENTITY TYPE
      //***************************************
      Query.ParamByName(
        'entity_type'
      ).AsString :=
        Trim(AEntityType);

      //***************************************
      //* TAX ID
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('tax_id') do
      begin
        DataType := ftString;

        if Trim(ATaxId) = '' then
          Clear
        else
          AsString := Trim(ATaxId);
      end;

      //***************************************
      //* LEGAL NAME
      //***************************************
      Query.ParamByName(
        'legal_name'
      ).AsString :=
        Trim(ALegalName);

      //***************************************
      //* TRADE NAME
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('trade_name') do
      begin
        DataType := ftString;

        if Trim(ATradeName) = '' then
          Clear
        else
          AsString := Trim(ATradeName);
      end;

      //***************************************
      //* STATE REGISTRATION
      //* OPTIONAL
      //***************************************
      with Query.ParamByName(
        'state_registration'
      ) do
      begin
        DataType := ftString;

        if Trim(AStateRegistration) = '' then
          Clear
        else
          AsString := Trim(AStateRegistration);
      end;

      //***************************************
      //* MUNICIPAL REGISTRATION
      //* OPTIONAL
      //***************************************
      with Query.ParamByName(
        'municipal_registration'
      ) do
      begin
        DataType := ftString;

        if Trim(AMunicipalRegistration) = '' then
          Clear
        else
          AsString := Trim(AMunicipalRegistration);
      end;

      //***************************************
      //* IS CUSTOMER
      //***************************************
      Query.ParamByName(
        'is_customer'
      ).AsBoolean :=
        AIsCustomer;

      //***************************************
      //* IS SUPPLIER
      //***************************************
      Query.ParamByName(
        'is_supplier'
      ).AsBoolean :=
        AIsSupplier;

      //***************************************
      //* EMAIL
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('email') do
      begin
        DataType := ftString;

        if Trim(AEmail) = '' then
          Clear
        else
          AsString := Trim(AEmail);
      end;

      //***************************************
      //* PHONE
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('phone') do
      begin
        DataType := ftString;

        if Trim(APhone) = '' then
          Clear
        else
          AsString := Trim(APhone);
      end;

      //***************************************
      //* MOBILE PHONE
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('mobile_phone') do
      begin
        DataType := ftString;

        if Trim(AMobilePhone) = '' then
          Clear
        else
          AsString := Trim(AMobilePhone);
      end;

      //***************************************
      //* EXECUTE / RETURNING
      //***************************************
      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      //***************************************
      //* JSON RESULT
      //***************************************
      JSONObject :=
        EntityToJson(
          Query
        );

      try
        Result :=
          JSONObject.ToJSON;
      finally
        JSONObject.Free;
      end;

      //***************************************
      //* COMMIT
      //***************************************
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

//***************************************
//* ISVALIDSORTFIELD
//***************************************
class function TEntityRepository.IsValidSortField(
  const AConnection: TFDConnection;
  const AFieldName: string
): Boolean;
var
  LQuery: TFDQuery;
begin
  Result := False;

  if Trim(AFieldName) = '' then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConnection;

    LQuery.SQL.Text :=
      'SELECT 1 ' +
      'FROM information_schema.columns ' +
      'WHERE table_schema = :schema_name ' +
      '  AND table_name = :table_name ' +
      '  AND column_name = :column_name ' +
      'LIMIT 1';

    LQuery.ParamByName('schema_name').AsString :=
      'master';

    LQuery.ParamByName('table_name').AsString :=
      'entities';

    LQuery.ParamByName('column_name').AsString :=
      LowerCase(Trim(AFieldName));

    LQuery.Open;

    Result :=
      not LQuery.IsEmpty;

  finally
    LQuery.Free;
  end;
end;

//***************************************
//* SET ACTIVE
//***************************************
class function TEntityRepository.SetActive(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AActive: Boolean
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  ResolveQuery: TFDQuery;
  EffectiveTenantID: Int64;
begin
  Result := False;

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  ResolveQuery :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    ResolveQuery.Connection :=
      Connection;

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
      begin
        ResolveQuery.SQL.Add(
          '  AND tenant_id = :tenant_id'
        );
      end;

      ResolveQuery.ParamByName(
        'entity_uuid'
      ).AsString :=
        AEntityUuid;

      if not AGlobalScope then
      begin
        ResolveQuery.ParamByName(
          'tenant_id'
        ).AsLargeInt :=
          ATenantID;
      end;

      ResolveQuery.Open;

      if ResolveQuery.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      EffectiveTenantID :=
        ResolveQuery.FieldByName(
          'tenant_id'
        ).AsLargeInt;

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
      //* UPDATE ACTIVE
      //***************************************
      Query.SQL.Text :=
        'UPDATE master.entities SET ' +
        '    active = :active, ' +
        '    updated_at = CURRENT_TIMESTAMP ' +
        'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
        '  AND tenant_id = :tenant_id ' +
        '  AND deleted_at IS NULL';

      Query.ParamByName(
        'active'
      ).AsBoolean :=
        AActive;

      Query.ParamByName(
        'entity_uuid'
      ).AsString :=
        AEntityUuid;

      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
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

end.
