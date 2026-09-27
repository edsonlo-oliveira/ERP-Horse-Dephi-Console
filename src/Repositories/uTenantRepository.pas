unit uTenantRepository;

interface

type
  TTenantRepository = class
  public
    class function List(
      const ASearch: string;
      const APage: Integer;
      const APageSize: Integer;
      const ASortField: string;
      const ASortDirection: string
    ): string;

    class function GetByUuid(
      const ATenantUuid: string;
      const AIncludeDeleted: Boolean = False
    ): string;

    class function Create(
      const AUserID: Int64;
      const AAuditTenantID: Int64;
      const ALegalName: string;
      const ATradeName: string;
      const ATaxId: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      const AWebsiteUrl: string;
      const ALogoUrl: string;
      const ATimezone: string;
      const ACurrencyCode: string;
      const ALocaleCode: string;
      const AStatus: string
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantUuid: string;
      const ALegalName: string;
      const ATradeName: string;
      const ATaxId: string;
      const AStateRegistration: string;
      const AMunicipalRegistration: string;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      const AWebsiteUrl: string;
      const ALogoUrl: string;
      const ATimezone: string;
      const ACurrencyCode: string;
      const ALocaleCode: string
    ): string;

    class function ChangeStatus(
      const AUserID: Int64;
      const ATenantUuid: string;
      const AStatus: string
    ): Boolean;

    class function Delete(
      const AUserID: Int64;
      const ATenantUuid: string
    ): Boolean;

    class function HardDelete(
      const AUserID: Int64;
      const ATenantUuid: string;
      out AHasDependencies: Boolean
    ): Boolean;

    class function TaxIdExists(
      const ATaxId: string;
      const ATenantUuid: string = ''
    ): Boolean;

    class function IsMaster(
      const ATenantUuid: string
    ): Boolean; overload;

    class function IsMaster(
      const ATenantID: Int64
    ): Boolean; overload;

    class function Exists(
      const ATenantUuid: string;
      const AIncludeDeleted: Boolean = False
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  uApiDatabase,
  uAuditContext,
  uDatabaseUtils;


//***************************************
//* NORMALIZE UUID
//***************************************
function NormalizeUuid(
  const AUuid: string
): string;
begin
  Result := Trim(AUuid);

  Result := StringReplace(
    Result,
    '{',
    '',
    [rfReplaceAll]
  );

  Result := StringReplace(
    Result,
    '}',
    '',
    [rfReplaceAll]
  );
end;


//***************************************
//* TENANT TO JSON
//***************************************
function TenantToJson(
  const AQuery: TFDQuery
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'tenant_id',
    TJSONNumber.Create(
      AQuery.FieldByName(
        'tenant_id'
      ).AsLargeInt
    )
  );

  Result.AddPair(
    'tenant_uuid',
    AQuery.FieldByName(
      'tenant_uuid'
    ).AsString
  );

  Result.AddPair(
    'legal_name',
    AQuery.FieldByName(
      'legal_name'
    ).AsString
  );

  if AQuery.FieldByName(
    'trade_name'
  ).IsNull then
    Result.AddPair(
      'trade_name',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'trade_name',
      AQuery.FieldByName(
        'trade_name'
      ).AsString
    );

  Result.AddPair(
    'tax_id',
    AQuery.FieldByName(
      'tax_id'
    ).AsString
  );

  if AQuery.FieldByName(
    'state_registration'
  ).IsNull then
    Result.AddPair(
      'state_registration',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'state_registration',
      AQuery.FieldByName(
        'state_registration'
      ).AsString
    );

  if AQuery.FieldByName(
    'municipal_registration'
  ).IsNull then
    Result.AddPair(
      'municipal_registration',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'municipal_registration',
      AQuery.FieldByName(
        'municipal_registration'
      ).AsString
    );

  if AQuery.FieldByName(
    'email'
  ).IsNull then
    Result.AddPair(
      'email',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'email',
      AQuery.FieldByName(
        'email'
      ).AsString
    );

  if AQuery.FieldByName(
    'phone'
  ).IsNull then
    Result.AddPair(
      'phone',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'phone',
      AQuery.FieldByName(
        'phone'
      ).AsString
    );

  if AQuery.FieldByName(
    'mobile_phone'
  ).IsNull then
    Result.AddPair(
      'mobile_phone',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'mobile_phone',
      AQuery.FieldByName(
        'mobile_phone'
      ).AsString
    );

  if AQuery.FieldByName(
    'website_url'
  ).IsNull then
    Result.AddPair(
      'website_url',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'website_url',
      AQuery.FieldByName(
        'website_url'
      ).AsString
    );

  if AQuery.FieldByName(
    'logo_url'
  ).IsNull then
    Result.AddPair(
      'logo_url',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'logo_url',
      AQuery.FieldByName(
        'logo_url'
      ).AsString
    );

  Result.AddPair(
    'timezone',
    AQuery.FieldByName(
      'timezone'
    ).AsString
  );

  Result.AddPair(
    'currency_code',
    Trim(
      AQuery.FieldByName(
        'currency_code'
      ).AsString
    )
  );

  Result.AddPair(
    'locale_code',
    AQuery.FieldByName(
      'locale_code'
    ).AsString
  );

  Result.AddPair(
    'status',
    AQuery.FieldByName(
      'status'
    ).AsString
  );

  Result.AddPair(
    'is_master',
    TJSONBool.Create(
      AQuery.FieldByName(
        'is_master'
      ).AsBoolean
    )
  );

  Result.AddPair(
    'created_at',
    AQuery.FieldByName(
      'created_at'
    ).AsString
  );

  Result.AddPair(
    'updated_at',
    AQuery.FieldByName(
      'updated_at'
    ).AsString
  );

  if AQuery.FieldByName(
    'deleted_at'
  ).IsNull then
    Result.AddPair(
      'deleted_at',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'deleted_at',
      AQuery.FieldByName(
        'deleted_at'
      ).AsString
    );
end;


//***************************************
//* SORT FIELD
//***************************************
function GetSortField(
  const ASortField: string
): string;
var
  LField: string;
begin
  LField :=
    LowerCase(
      Trim(
        ASortField
      )
    );

  if LField = 'tenant_id' then
    Exit('tenant_id');

  if LField = 'legal_name' then
    Exit('legal_name');

  if LField = 'trade_name' then
    Exit('trade_name');

  if LField = 'tax_id' then
    Exit('tax_id');

  if LField = 'email' then
    Exit('email');

  if LField = 'status' then
    Exit('status');

  if LField = 'created_at' then
    Exit('created_at');

  if LField = 'updated_at' then
    Exit('updated_at');

  Result := 'legal_name';
end;


//***************************************
//* SORT DIRECTION
//***************************************
function GetSortDirection(
  const ASortDirection: string
): string;
begin
  if SameText(
    Trim(ASortDirection),
    'DESC'
  ) then
    Result := 'DESC'
  else
    Result := 'ASC';
end;


//***************************************
//* LIST
//***************************************
class function TTenantRepository.List(
  const ASearch: string;
  const APage: Integer;
  const APageSize: Integer;
  const ASortField: string;
  const ASortDirection: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  CountQuery: TFDQuery;
  JsonRoot: TJSONObject;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;

  LSearch: string;
  LSortField: string;
  LSortDirection: string;

  LPage: Integer;
  LPageSize: Integer;
  LOffset: Integer;

  LTotalRecords: Int64;
  LTotalPages: Integer;
begin
  Result := '';

  LPage := APage;

  if LPage < 1 then
    LPage := 1;

  LPageSize := APageSize;

  if LPageSize < 1 then
    LPageSize := 100;

  if LPageSize > 500 then
    LPageSize := 500;

  LOffset :=
    (LPage - 1) *
    LPageSize;

  LSearch :=
    Trim(
      ASearch
    );

  LSortField :=
    GetSortField(
      ASortField
    );

  LSortDirection :=
    GetSortDirection(
      ASortDirection
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  CountQuery :=
    TFDQuery.Create(nil);

  JsonRoot :=
    TJSONObject.Create;

  JsonArray :=
    TJSONArray.Create;

  try
    Query.Connection :=
      Connection;

    CountQuery.Connection :=
      Connection;

    //***************************************
    //* COUNT
    //***************************************
    CountQuery.SQL.Text :=
      'SELECT COUNT(*) AS total_records ' +
      'FROM core.tenants ' +
      'WHERE deleted_at IS NULL ';

    if LSearch <> '' then
    begin
      CountQuery.SQL.Add(
        'AND (' +
        '  legal_name ILIKE :search ' +
        '  OR trade_name ILIKE :search ' +
        '  OR tax_id ILIKE :search ' +
        '  OR email ILIKE :search ' +
        ')'
      );

      CountQuery.ParamByName(
        'search'
      ).AsString :=
        '%' + LSearch + '%';
    end;

    CountQuery.Open;

    LTotalRecords :=
      CountQuery.FieldByName(
        'total_records'
      ).AsLargeInt;

    if LTotalRecords = 0 then
      LTotalPages := 0
    else
      LTotalPages :=
        (LTotalRecords + LPageSize - 1)
        div
        LPageSize;

    //***************************************
    //* DATA
    //***************************************
    Query.SQL.Text :=
      'SELECT ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  is_master, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at ' +
      'FROM core.tenants ' +
      'WHERE deleted_at IS NULL ';

    if LSearch <> '' then
    begin
      Query.SQL.Add(
        'AND (' +
        '  legal_name ILIKE :search ' +
        '  OR trade_name ILIKE :search ' +
        '  OR tax_id ILIKE :search ' +
        '  OR email ILIKE :search ' +
        ')'
      );
    end;

    Query.SQL.Add(
      'ORDER BY ' +
      LSortField +
      ' ' +
      LSortDirection +
      ', tenant_id ASC '
    );

    Query.SQL.Add(
      'LIMIT :limit OFFSET :offset'
    );

    if LSearch <> '' then
      Query.ParamByName(
        'search'
      ).AsString :=
        '%' + LSearch + '%';

    Query.ParamByName(
      'limit'
    ).AsInteger :=
      LPageSize;

    Query.ParamByName(
      'offset'
    ).AsInteger :=
      LOffset;

    Query.Open;

    while not Query.Eof do
    begin
      JsonObject :=
        TenantToJson(
          Query
        );

      JsonArray.AddElement(
        JsonObject
      );

      Query.Next;
    end;

    JsonRoot.AddPair(
      'page',
      TJSONNumber.Create(
        LPage
      )
    );

    JsonRoot.AddPair(
      'page_size',
      TJSONNumber.Create(
        LPageSize
      )
    );

    JsonRoot.AddPair(
      'total_records',
      TJSONNumber.Create(
        LTotalRecords
      )
    );

    JsonRoot.AddPair(
      'total_pages',
      TJSONNumber.Create(
        LTotalPages
      )
    );

    JsonRoot.AddPair(
      'data',
      JsonArray
    );

    JsonArray := nil;

    Result :=
      JsonRoot.ToJSON;

  finally
    JsonArray.Free;
    JsonRoot.Free;
    CountQuery.Free;
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* GET BY UUID
//***************************************
class function TTenantRepository.GetByUuid(
  const ATenantUuid: string;
  const AIncludeDeleted: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  LUuid: string;
begin
  Result := '';

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Query.SQL.Text :=
      'SELECT ' +
      '  tenant_id, ' +
      '  tenant_uuid::text AS tenant_uuid, ' +
      '  legal_name, ' +
      '  trade_name, ' +
      '  tax_id, ' +
      '  state_registration, ' +
      '  municipal_registration, ' +
      '  email, ' +
      '  phone, ' +
      '  mobile_phone, ' +
      '  website_url, ' +
      '  logo_url, ' +
      '  timezone, ' +
      '  currency_code, ' +
      '  locale_code, ' +
      '  status, ' +
      '  is_master, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at ' +
      'FROM core.tenants ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ';

    if not AIncludeDeleted then
      Query.SQL.Add(
        'AND deleted_at IS NULL'
      );

    Query.ParamByName(
      'tenant_uuid'
    ).AsString :=
      LUuid;

    Query.Open;

    if Query.Eof then
      Exit;

    JsonObject :=
      TenantToJson(
        Query
      );

    try
      Result :=
        JsonObject.ToJSON;
    finally
      JsonObject.Free;
    end;

  finally
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* CREATE
//***************************************
class function TTenantRepository.Create(
  const AUserID: Int64;
  const AAuditTenantID: Int64;
  const ALegalName: string;
  const ATradeName: string;
  const ATaxId: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  const AWebsiteUrl: string;
  const ALogoUrl: string;
  const ATimezone: string;
  const ACurrencyCode: string;
  const ALocaleCode: string;
  const AStatus: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
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
      SetAuditContext(
        Connection,
        AUserID,
        AAuditTenantID
      );

      Query.SQL.Text :=
        'INSERT INTO core.tenants (' +
        '  legal_name, ' +
        '  trade_name, ' +
        '  tax_id, ' +
        '  state_registration, ' +
        '  municipal_registration, ' +
        '  email, ' +
        '  phone, ' +
        '  mobile_phone, ' +
        '  website_url, ' +
        '  logo_url, ' +
        '  timezone, ' +
        '  currency_code, ' +
        '  locale_code, ' +
        '  status ' +
        ') VALUES (' +
        '  :legal_name, ' +
        '  :trade_name, ' +
        '  :tax_id, ' +
        '  :state_registration, ' +
        '  :municipal_registration, ' +
        '  :email, ' +
        '  :phone, ' +
        '  :mobile_phone, ' +
        '  :website_url, ' +
        '  :logo_url, ' +
        '  :timezone, ' +
        '  :currency_code, ' +
        '  :locale_code, ' +
        '  :status ' +
        ') ' +
        'RETURNING ' +
        '  tenant_id, ' +
        '  tenant_uuid::text AS tenant_uuid, ' +
        '  legal_name, ' +
        '  trade_name, ' +
        '  tax_id, ' +
        '  state_registration, ' +
        '  municipal_registration, ' +
        '  email, ' +
        '  phone, ' +
        '  mobile_phone, ' +
        '  website_url, ' +
        '  logo_url, ' +
        '  timezone, ' +
        '  currency_code, ' +
        '  locale_code, ' +
        '  status, ' +
        '  is_master, ' +
        '  created_at, ' +
        '  updated_at, ' +
        '  deleted_at';

      Query.ParamByName(
        'legal_name'
      ).AsString :=
        Trim(ALegalName);

      Query.ParamByName(
        'tax_id'
      ).AsString :=
        Trim(ATaxId);

      TDatabaseUtils.SetOptionalString(
        Query,
        'trade_name',
        ATradeName
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'state_registration',
        AStateRegistration
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'municipal_registration',
        AMunicipalRegistration
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'email',
        AEmail
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'phone',
        APhone
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'mobile_phone',
        AMobilePhone
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'website_url',
        AWebsiteUrl
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'logo_url',
        ALogoUrl
      );

      Query.ParamByName(
        'timezone'
      ).AsString :=
        Trim(ATimezone);

      Query.ParamByName(
        'currency_code'
      ).AsString :=
        UpperCase(
          Trim(
            ACurrencyCode
          )
        );

      Query.ParamByName(
        'locale_code'
      ).AsString :=
        Trim(ALocaleCode);

      Query.ParamByName(
        'status'
      ).AsString :=
        UpperCase(
          Trim(
            AStatus
          )
        );

      Query.Open;

      JsonObject :=
        TenantToJson(
          Query
        );

      try
        Result :=
          JsonObject.ToJSON;
      finally
        JsonObject.Free;
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
class function TTenantRepository.Update(
  const AUserID: Int64;
  const ATenantUuid: string;
  const ALegalName: string;
  const ATradeName: string;
  const ATaxId: string;
  const AStateRegistration: string;
  const AMunicipalRegistration: string;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  const AWebsiteUrl: string;
  const ALogoUrl: string;
  const ATimezone: string;
  const ACurrencyCode: string;
  const ALocaleCode: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  ResolveQuery: TFDQuery;
  JsonObject: TJSONObject;

  LUuid: string;
  LTenantID: Int64;
begin
  Result := '';

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

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
      ResolveQuery.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM core.tenants ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL';

      ResolveQuery.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      ResolveQuery.Open;

      if ResolveQuery.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      LTenantID :=
        ResolveQuery.FieldByName(
          'tenant_id'
        ).AsLargeInt;

      ResolveQuery.Close;

      SetAuditContext(
        Connection,
        AUserID,
        LTenantID
      );

      Query.SQL.Text :=
        'UPDATE core.tenants SET ' +
        '  legal_name = :legal_name, ' +
        '  trade_name = :trade_name, ' +
        '  tax_id = :tax_id, ' +
        '  state_registration = :state_registration, ' +
        '  municipal_registration = :municipal_registration, ' +
        '  email = :email, ' +
        '  phone = :phone, ' +
        '  mobile_phone = :mobile_phone, ' +
        '  website_url = :website_url, ' +
        '  logo_url = :logo_url, ' +
        '  timezone = :timezone, ' +
        '  currency_code = :currency_code, ' +
        '  locale_code = :locale_code, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ' +
        'RETURNING ' +
        '  tenant_id, ' +
        '  tenant_uuid::text AS tenant_uuid, ' +
        '  legal_name, ' +
        '  trade_name, ' +
        '  tax_id, ' +
        '  state_registration, ' +
        '  municipal_registration, ' +
        '  email, ' +
        '  phone, ' +
        '  mobile_phone, ' +
        '  website_url, ' +
        '  logo_url, ' +
        '  timezone, ' +
        '  currency_code, ' +
        '  locale_code, ' +
        '  status, ' +
        '  is_master, ' +
        '  created_at, ' +
        '  updated_at, ' +
        '  deleted_at';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      Query.ParamByName(
        'legal_name'
      ).AsString :=
        Trim(ALegalName);

      Query.ParamByName(
        'tax_id'
      ).AsString :=
        Trim(ATaxId);

      TDatabaseUtils.SetOptionalString(
        Query,
        'trade_name',
        ATradeName
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'state_registration',
        AStateRegistration
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'municipal_registration',
        AMunicipalRegistration
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'email',
        AEmail
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'phone',
        APhone
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'mobile_phone',
        AMobilePhone
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'website_url',
        AWebsiteUrl
      );

      TDatabaseUtils.SetOptionalString(
        Query,
        'logo_url',
        ALogoUrl
      );

      Query.ParamByName(
        'timezone'
      ).AsString :=
        Trim(ATimezone);

      Query.ParamByName(
        'currency_code'
      ).AsString :=
        UpperCase(
          Trim(
            ACurrencyCode
          )
        );

      Query.ParamByName(
        'locale_code'
      ).AsString :=
        Trim(ALocaleCode);

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      JsonObject :=
        TenantToJson(
          Query
        );

      try
        Result :=
          JsonObject.ToJSON;
      finally
        JsonObject.Free;
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
//* CHANGE STATUS
//***************************************
class function TTenantRepository.ChangeStatus(
  const AUserID: Int64;
  const ATenantUuid: string;
  const AStatus: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;

  LUuid: string;
  LTenantID: Int64;
begin
  Result := False;

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Connection.StartTransaction;

    try
      Query.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM core.tenants ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      LTenantID :=
        Query.FieldByName(
          'tenant_id'
        ).AsLargeInt;

      Query.Close;

      SetAuditContext(
        Connection,
        AUserID,
        LTenantID
      );

      Query.SQL.Text :=
        'UPDATE core.tenants SET ' +
        '  status = :status, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ' +
        '  AND is_master = FALSE';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      Query.ParamByName(
        'status'
      ).AsString :=
        UpperCase(
          Trim(
            AStatus
          )
        );

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
//* SOFT DELETE
//***************************************
class function TTenantRepository.Delete(
  const AUserID: Int64;
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;

  LUuid: string;
  LTenantID: Int64;
begin
  Result := False;

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Connection.StartTransaction;

    try
      Query.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM core.tenants ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ' +
        '  AND is_master = FALSE';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      LTenantID :=
        Query.FieldByName(
          'tenant_id'
        ).AsLargeInt;

      Query.Close;

      SetAuditContext(
        Connection,
        AUserID,
        LTenantID
      );

      Query.SQL.Text :=
        'UPDATE core.tenants SET ' +
        '  deleted_at = CURRENT_TIMESTAMP, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NULL ' +
        '  AND is_master = FALSE';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

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
//* HARD DELETE
//***************************************
class function TTenantRepository.HardDelete(
  const AUserID: Int64;
  const ATenantUuid: string;
  out AHasDependencies: Boolean
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;

  LUuid: string;
  LTenantID: Int64;
begin
  Result := False;
  AHasDependencies := False;

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Connection.StartTransaction;

    try
      // Hard Delete somente pode ocorrer
      // depois do Soft Delete.
      Query.SQL.Text :=
        'SELECT tenant_id ' +
        'FROM core.tenants ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NOT NULL ' +
        '  AND is_master = FALSE';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      LTenantID :=
        Query.FieldByName(
          'tenant_id'
        ).AsLargeInt;

      Query.Close;

      SetAuditContext(
        Connection,
        AUserID,
        LTenantID
      );

      Query.SQL.Text :=
        'DELETE FROM core.tenants ' +
        'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
        '  AND deleted_at IS NOT NULL ' +
        '  AND is_master = FALSE';

      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

      try
        Query.ExecSQL;

        Result :=
          Query.RowsAffected > 0;

        except
          on E: EFDDBEngineException do
          begin
            //***************************************
            //* FOREIGN KEY VIOLATION
            //* PostgreSQL error code 23503
            //***************************************
            if
              (E.ErrorCount > 0) and
              (E.Errors[0].ErrorCode = 23503)
            then
            begin
              AHasDependencies := True;

              if Connection.InTransaction then
                Connection.Rollback;

              Exit;
            end;

            raise;
          end;
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
//* TAX ID EXISTS
//***************************************
class function TTenantRepository.TaxIdExists(
  const ATaxId: string;
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;

  LUuid: string;
begin

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Query.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.tenants ' +
      '  WHERE tax_id = :tax_id ';

    if LUuid <> '' then
      Query.SQL.Add(
        'AND tenant_uuid <> CAST(:tenant_uuid AS uuid) '
      );

    Query.SQL.Add(
      ') AS tax_id_exists'
    );

    Query.ParamByName(
      'tax_id'
    ).AsString :=
      Trim(
        ATaxId
      );

    if LUuid <> '' then
      Query.ParamByName(
        'tenant_uuid'
      ).AsString :=
        LUuid;

    Query.Open;

    Result :=
      Query.FieldByName(
        'tax_id_exists'
      ).AsBoolean;

  finally
    Query.Free;
    Connection.Free;
  end;
end;


//***************************************
//* IS MASTER BY UUID
//***************************************
class function TTenantRepository.IsMaster(
  const ATenantUuid: string
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  LUuid: string;
begin
  Result := False;

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Query.SQL.Text :=
      'SELECT is_master ' +
      'FROM core.tenants ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid)';

    Query.ParamByName(
      'tenant_uuid'
    ).AsString :=
      LUuid;

    Query.Open;

    if Query.Eof then
      Exit;

    Result :=
      Query.FieldByName(
        'is_master'
      ).AsBoolean;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* IS MASTER BY ID
//***************************************
class function TTenantRepository.IsMaster(
  const ATenantID: Int64
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
begin
  Result := False;

  if ATenantID <= 0 then
    Exit;

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Query.SQL.Text :=
      'SELECT is_master ' +
      'FROM core.tenants ' +
      'WHERE tenant_id = :tenant_id';

    Query.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    Query.Open;

    if Query.Eof then
      Exit;

    Result :=
      Query.FieldByName(
        'is_master'
      ).AsBoolean;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

//***************************************
//* EXISTS
//***************************************
class function TTenantRepository.Exists(
  const ATenantUuid: string;
  const AIncludeDeleted: Boolean
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  LUuid: string;
begin

  LUuid :=
    NormalizeUuid(
      ATenantUuid
    );

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Query.SQL.Text :=
      'SELECT 1 ' +
      'FROM core.tenants ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ';

    if not AIncludeDeleted then
      Query.SQL.Add(
        'AND deleted_at IS NULL'
      );

    Query.ParamByName(
      'tenant_uuid'
    ).AsString :=
      LUuid;

    Query.Open;

    Result :=
      not Query.Eof;

  finally
    Query.Free;
    Connection.Free;
  end;
end;

end.
