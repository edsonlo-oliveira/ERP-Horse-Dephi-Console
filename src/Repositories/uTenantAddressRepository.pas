unit uTenantAddressRepository;

interface

uses
  System.JSON,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

type
  TTenantAddressRepository = class
  private
    class function ResolveTenantID(
      const ATenantUuid: string
    ): Int64; static;

    class function AddressToJson(
      const AQuery: TFDQuery
    ): TJSONObject; static;

  public
    class function List(
      const ATenantUuid: string
    ): string;

    class function GetByUuid(
      const ATenantUuid: string;
      const AAddressUuid: string
    ): string;

    class function Create(
      const AUserID: Int64;
      const ATenantUuid: string;
      const AAddressType: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const APostalCode: string;
      const ACountryCode: string;
      const AIsPrimary: Boolean
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantUuid: string;
      const AAddressUuid: string;
      const AAddressType: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const APostalCode: string;
      const ACountryCode: string;
      const AIsPrimary: Boolean
    ): string;

    class function Delete(
      const AUserID: Int64;
      const ATenantUuid: string;
      const AAddressUuid: string
    ): Boolean;

    class function Exists(
      const ATenantUuid: string;
      const AAddressUuid: string
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  uApiDatabase,
  uAuditContext,
  uDatabaseUtils;


//***************************************
//* RESOLVE TENANT ID
//***************************************
class function TTenantAddressRepository.ResolveTenantID(
  const ATenantUuid: string
): Int64;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := 0;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT tenant_id ' +
      'FROM core.tenants ' +
      'WHERE tenant_uuid = CAST(:tenant_uuid AS uuid) ' +
      '  AND deleted_at IS NULL';

    LQuery.ParamByName(
      'tenant_uuid'
    ).AsString :=
      Trim(
        ATenantUuid
      );

    LQuery.Open;

    if not LQuery.Eof then
    begin
      Result :=
        LQuery.FieldByName(
          'tenant_id'
        ).AsLargeInt;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* ADDRESS TO JSON
//***************************************
class function TTenantAddressRepository.AddressToJson(
  const AQuery: TFDQuery
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'tenant_address_id',
    TJSONNumber.Create(
      AQuery.FieldByName(
        'tenant_address_id'
      ).AsLargeInt
    )
  );

  Result.AddPair(
    'tenant_address_uuid',
    AQuery.FieldByName(
      'tenant_address_uuid'
    ).AsString
  );

  Result.AddPair(
    'tenant_id',
    TJSONNumber.Create(
      AQuery.FieldByName(
        'tenant_id'
      ).AsLargeInt
    )
  );

  Result.AddPair(
    'address_type',
    AQuery.FieldByName(
      'address_type'
    ).AsString
  );

  Result.AddPair(
    'address_line',
    AQuery.FieldByName(
      'address_line'
    ).AsString
  );

  //***************************************
  //* ADDRESS NUMBER
  //***************************************
  if AQuery.FieldByName(
    'address_number'
  ).IsNull then
  begin
    Result.AddPair(
      'address_number',
      TJSONNull.Create
    );
  end
  else
  begin
    Result.AddPair(
      'address_number',
      AQuery.FieldByName(
        'address_number'
      ).AsString
    );
  end;

  //***************************************
  //* ADDRESS COMPLEMENT
  //***************************************
  if AQuery.FieldByName(
    'address_complement'
  ).IsNull then
  begin
    Result.AddPair(
      'address_complement',
      TJSONNull.Create
    );
  end
  else
  begin
    Result.AddPair(
      'address_complement',
      AQuery.FieldByName(
        'address_complement'
      ).AsString
    );
  end;

  //***************************************
  //* NEIGHBORHOOD
  //***************************************
  if AQuery.FieldByName(
    'neighborhood'
  ).IsNull then
  begin
    Result.AddPair(
      'neighborhood',
      TJSONNull.Create
    );
  end
  else
  begin
    Result.AddPair(
      'neighborhood',
      AQuery.FieldByName(
        'neighborhood'
      ).AsString
    );
  end;

  Result.AddPair(
    'city',
    AQuery.FieldByName(
      'city'
    ).AsString
  );

  Result.AddPair(
    'state_code',
    Trim(
      AQuery.FieldByName(
        'state_code'
      ).AsString
    )
  );

  //***************************************
  //* POSTAL CODE
  //***************************************
  if AQuery.FieldByName(
    'postal_code'
  ).IsNull then
  begin
    Result.AddPair(
      'postal_code',
      TJSONNull.Create
    );
  end
  else
  begin
    Result.AddPair(
      'postal_code',
      AQuery.FieldByName(
        'postal_code'
      ).AsString
    );
  end;

  Result.AddPair(
    'country_code',
    Trim(
      AQuery.FieldByName(
        'country_code'
      ).AsString
    )
  );

  Result.AddPair(
    'is_primary',
    TJSONBool.Create(
      AQuery.FieldByName(
        'is_primary'
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
end;


//***************************************
//* LIST
//***************************************
class function TTenantAddressRepository.List(
  const ATenantUuid: string
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJsonArray: TJSONArray;
  LJson: TJSONObject;
  LTenantID: Int64;
begin
  Result := '';

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  LJsonArray :=
    TJSONArray.Create;

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '    tenant_address_id, ' +
      '    tenant_address_uuid::text AS tenant_address_uuid, ' +
      '    tenant_id, ' +
      '    address_type, ' +
      '    address_line, ' +
      '    address_number, ' +
      '    address_complement, ' +
      '    neighborhood, ' +
      '    city, ' +
      '    state_code, ' +
      '    postal_code, ' +
      '    country_code, ' +
      '    is_primary, ' +
      '    created_at, ' +
      '    updated_at ' +
      'FROM core.tenant_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      'ORDER BY ' +
      '    is_primary DESC, ' +
      '    address_type';

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      LTenantID;

    LQuery.Open;

    while not LQuery.Eof do
    begin
      LJson :=
        AddressToJson(
          LQuery
        );

      LJsonArray.AddElement(
        LJson
      );

      LQuery.Next;
    end;

    Result :=
      LJsonArray.ToJSON;

  finally
    LJsonArray.Free;
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* GET BY UUID
//***************************************
class function TTenantAddressRepository.GetByUuid(
  const ATenantUuid: string;
  const AAddressUuid: string
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LTenantID: Int64;
begin
  Result := '';

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '    tenant_address_id, ' +
      '    tenant_address_uuid::text AS tenant_address_uuid, ' +
      '    tenant_id, ' +
      '    address_type, ' +
      '    address_line, ' +
      '    address_number, ' +
      '    address_complement, ' +
      '    neighborhood, ' +
      '    city, ' +
      '    state_code, ' +
      '    postal_code, ' +
      '    country_code, ' +
      '    is_primary, ' +
      '    created_at, ' +
      '    updated_at ' +
      'FROM core.tenant_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND tenant_address_uuid = CAST(:address_uuid AS uuid)';

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      LTenantID;

    LQuery.ParamByName(
      'address_uuid'
    ).AsString :=
      Trim(
        AAddressUuid
      );

    LQuery.Open;

    if LQuery.Eof then
      Exit;

    LJson :=
      AddressToJson(
        LQuery
      );

    try
      Result :=
        LJson.ToJSON;

    finally
      LJson.Free;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* CREATE
//***************************************
class function TTenantAddressRepository.Create(
  const AUserID: Int64;
  const ATenantUuid: string;
  const AAddressType: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const APostalCode: string;
  const ACountryCode: string;
  const AIsPrimary: Boolean
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LTenantID: Int64;
begin
  Result := '';

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LConnection.StartTransaction;

    try
      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        LConnection,
        AUserID,
        LTenantID
      );

      //***************************************
      //* REMOVE CURRENT PRIMARY
      //***************************************
      if AIsPrimary then
      begin
        LQuery.SQL.Text :=
          'UPDATE core.tenant_addresses ' +
          'SET ' +
          '    is_primary = FALSE, ' +
          '    updated_at = CURRENT_TIMESTAMP ' +
          'WHERE tenant_id = :tenant_id ' +
          '  AND is_primary = TRUE';

        LQuery.ParamByName(
          'tenant_id'
        ).AsLargeInt :=
          LTenantID;

        LQuery.ExecSQL;

        LQuery.Close;
        LQuery.SQL.Clear;
        LQuery.Params.Clear;
      end;

      //***************************************
      //* INSERT
      //***************************************
      LQuery.SQL.Text :=
        'INSERT INTO core.tenant_addresses (' +
        '    tenant_id, ' +
        '    address_type, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    postal_code, ' +
        '    country_code, ' +
        '    is_primary ' +
        ') VALUES (' +
        '    :tenant_id, ' +
        '    :address_type, ' +
        '    :address_line, ' +
        '    :address_number, ' +
        '    :address_complement, ' +
        '    :neighborhood, ' +
        '    :city, ' +
        '    :state_code, ' +
        '    :postal_code, ' +
        '    :country_code, ' +
        '    :is_primary ' +
        ') ' +
        'RETURNING ' +
        '    tenant_address_id, ' +
        '    tenant_address_uuid::text AS tenant_address_uuid, ' +
        '    tenant_id, ' +
        '    address_type, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    postal_code, ' +
        '    country_code, ' +
        '    is_primary, ' +
        '    created_at, ' +
        '    updated_at';

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        LTenantID;

      LQuery.ParamByName(
        'address_type'
      ).AsString :=
        UpperCase(
          Trim(
            AAddressType
          )
        );

      LQuery.ParamByName(
        'address_line'
      ).AsString :=
        Trim(
          AAddressLine
        );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'address_number',
        AAddressNumber
      );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'address_complement',
        AAddressComplement
      );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'neighborhood',
        ANeighborhood
      );

      LQuery.ParamByName(
        'city'
      ).AsString :=
        Trim(
          ACity
        );

      LQuery.ParamByName(
        'state_code'
      ).AsString :=
        UpperCase(
          Trim(
            AStateCode
          )
        );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'postal_code',
        APostalCode
      );

      LQuery.ParamByName(
        'country_code'
      ).AsString :=
        UpperCase(
          Trim(
            ACountryCode
          )
        );

      LQuery.ParamByName(
        'is_primary'
      ).AsBoolean :=
        AIsPrimary;

      LQuery.Open;

      LJson :=
        AddressToJson(
          LQuery
        );

      try
        Result :=
          LJson.ToJSON;

      finally
        LJson.Free;
      end;

      LConnection.Commit;

    except
      if LConnection.InTransaction then
        LConnection.Rollback;

      raise;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* UPDATE
//***************************************
class function TTenantAddressRepository.Update(
  const AUserID: Int64;
  const ATenantUuid: string;
  const AAddressUuid: string;
  const AAddressType: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const APostalCode: string;
  const ACountryCode: string;
  const AIsPrimary: Boolean
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LTenantID: Int64;
begin
  Result := '';

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LConnection.StartTransaction;

    try
      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        LConnection,
        AUserID,
        LTenantID
      );

      //***************************************
      //* REMOVE CURRENT PRIMARY
      //***************************************
      if AIsPrimary then
      begin
        LQuery.SQL.Text :=
          'UPDATE core.tenant_addresses ' +
          'SET ' +
          '    is_primary = FALSE, ' +
          '    updated_at = CURRENT_TIMESTAMP ' +
          'WHERE tenant_id = :tenant_id ' +
          '  AND tenant_address_uuid <> CAST(:address_uuid AS uuid) ' +
          '  AND is_primary = TRUE';

        LQuery.ParamByName(
          'tenant_id'
        ).AsLargeInt :=
          LTenantID;

        LQuery.ParamByName(
          'address_uuid'
        ).AsString :=
          Trim(
            AAddressUuid
          );

        LQuery.ExecSQL;

        LQuery.Close;
        LQuery.SQL.Clear;
        LQuery.Params.Clear;
      end;

      //***************************************
      //* UPDATE
      //***************************************
      LQuery.SQL.Text :=
        'UPDATE core.tenant_addresses ' +
        'SET ' +
        '    address_type = :address_type, ' +
        '    address_line = :address_line, ' +
        '    address_number = :address_number, ' +
        '    address_complement = :address_complement, ' +
        '    neighborhood = :neighborhood, ' +
        '    city = :city, ' +
        '    state_code = :state_code, ' +
        '    postal_code = :postal_code, ' +
        '    country_code = :country_code, ' +
        '    is_primary = :is_primary, ' +
        '    updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND tenant_address_uuid = CAST(:address_uuid AS uuid) ' +
        'RETURNING ' +
        '    tenant_address_id, ' +
        '    tenant_address_uuid::text AS tenant_address_uuid, ' +
        '    tenant_id, ' +
        '    address_type, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    postal_code, ' +
        '    country_code, ' +
        '    is_primary, ' +
        '    created_at, ' +
        '    updated_at';

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        LTenantID;

      LQuery.ParamByName(
        'address_uuid'
      ).AsString :=
        Trim(
          AAddressUuid
        );

      LQuery.ParamByName(
        'address_type'
      ).AsString :=
        UpperCase(
          Trim(
            AAddressType
          )
        );

      LQuery.ParamByName(
        'address_line'
      ).AsString :=
        Trim(
          AAddressLine
        );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'address_number',
        AAddressNumber
      );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'address_complement',
        AAddressComplement
      );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'neighborhood',
        ANeighborhood
      );

      LQuery.ParamByName(
        'city'
      ).AsString :=
        Trim(
          ACity
        );

      LQuery.ParamByName(
        'state_code'
      ).AsString :=
        UpperCase(
          Trim(
            AStateCode
          )
        );

      TDatabaseUtils.SetOptionalString(
        LQuery,
        'postal_code',
        APostalCode
      );

      LQuery.ParamByName(
        'country_code'
      ).AsString :=
        UpperCase(
          Trim(
            ACountryCode
          )
        );

      LQuery.ParamByName(
        'is_primary'
      ).AsBoolean :=
        AIsPrimary;

      LQuery.Open;

      if LQuery.Eof then
      begin
        LConnection.Rollback;
        Exit;
      end;

      LJson :=
        AddressToJson(
          LQuery
        );

      try
        Result :=
          LJson.ToJSON;

      finally
        LJson.Free;
      end;

      LConnection.Commit;

    except
      if LConnection.InTransaction then
        LConnection.Rollback;

      raise;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* DELETE
//***************************************
class function TTenantAddressRepository.Delete(
  const AUserID: Int64;
  const ATenantUuid: string;
  const AAddressUuid: string
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LTenantID: Int64;
begin
  Result := False;

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LConnection.StartTransaction;

    try
      //***************************************
      //* AUDIT CONTEXT
      //***************************************
      SetAuditContext(
        LConnection,
        AUserID,
        LTenantID
      );

      //***************************************
      //* DELETE
      //***************************************
      LQuery.SQL.Text :=
        'DELETE FROM core.tenant_addresses ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND tenant_address_uuid = CAST(:address_uuid AS uuid)';

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        LTenantID;

      LQuery.ParamByName(
        'address_uuid'
      ).AsString :=
        Trim(
          AAddressUuid
        );

      LQuery.ExecSQL;

      Result :=
        LQuery.RowsAffected > 0;

      LConnection.Commit;

    except
      if LConnection.InTransaction then
        LConnection.Rollback;

      raise;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//***************************************
//* EXISTS
//***************************************
class function TTenantAddressRepository.Exists(
  const ATenantUuid: string;
  const AAddressUuid: string
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LTenantID: Int64;
begin
  Result := False;

  LTenantID :=
    ResolveTenantID(
      ATenantUuid
    );

  if LTenantID = 0 then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT 1 ' +
      'FROM core.tenant_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND tenant_address_uuid = CAST(:address_uuid AS uuid) ' +
      'LIMIT 1';

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      LTenantID;

    LQuery.ParamByName(
      'address_uuid'
    ).AsString :=
      Trim(
        AAddressUuid
      );

    LQuery.Open;

    Result :=
      not LQuery.Eof;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

end.
