unit uEntityAddressRepository;

interface

uses
  System.SysUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  uAuditContext;

type
  TEntityAddressRepository = class
  private
    class function AddressToJson(
      const AQuery: TFDQuery
    ): TJSONObject; static;

    class function ResolveEntity(
      const AConnection: TFDConnection;
      const AEntityUuid: string;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      out AEntityID: Int64;
      out AEffectiveTenantID: Int64
    ): Boolean; static;

    class procedure ClearCurrentPrimary(
      const AConnection: TFDConnection;
      const ATenantID: Int64;
      const AEntityID: Int64;
      const AExceptAddressID: Int64 = 0
    ); static;

  public
    class function List(
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string
    ): string;

    class function GetById(
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AEntityAddressID: Int64
    ): string;

    class function Create(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AAddressType: string;
      const APostalCode: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const AIsPrimary: Boolean
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AEntityAddressID: Int64;
      const AAddressType: string;
      const APostalCode: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const AIsPrimary: Boolean
    ): string;

    class function Delete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AGlobalScope: Boolean;
      const AEntityUuid: string;
      const AEntityAddressID: Int64
    ): Boolean;
  end;

implementation

uses
  uApiDatabase;

//***********************************************
//* ADDRESS TO JSON
//***********************************************
class function TEntityAddressRepository.AddressToJson(
  const AQuery: TFDQuery
): TJSONObject;
begin
  Result :=
    TJSONObject.Create
      .AddPair(
        'entity_address_id',
        TJSONNumber.Create(
          AQuery.FieldByName(
            'entity_address_id'
          ).AsLargeInt
        )
      )
      .AddPair(
        'tenant_id',
        TJSONNumber.Create(
          AQuery.FieldByName(
            'tenant_id'
          ).AsLargeInt
        )
      )
      .AddPair(
        'entity_id',
        TJSONNumber.Create(
          AQuery.FieldByName(
            'entity_id'
          ).AsLargeInt
        )
      )
      .AddPair(
        'address_type',
        AQuery.FieldByName(
          'address_type'
        ).AsString
      )
      .AddPair(
        'postal_code',
        AQuery.FieldByName(
          'postal_code'
        ).AsString
      )
      .AddPair(
        'address_line',
        AQuery.FieldByName(
          'address_line'
        ).AsString
      )
      .AddPair(
        'address_number',
        AQuery.FieldByName(
          'address_number'
        ).AsString
      )
      .AddPair(
        'address_complement',
        AQuery.FieldByName(
          'address_complement'
        ).AsString
      )
      .AddPair(
        'neighborhood',
        AQuery.FieldByName(
          'neighborhood'
        ).AsString
      )
      .AddPair(
        'city',
        AQuery.FieldByName(
          'city'
        ).AsString
      )
      .AddPair(
        'state_code',
        AQuery.FieldByName(
          'state_code'
        ).AsString
      )
      .AddPair(
        'is_primary',
        TJSONBool.Create(
          AQuery.FieldByName(
            'is_primary'
          ).AsBoolean
        )
      );
end;

//***********************************************
//* RESOLVE ENTITY
//***********************************************
class function TEntityAddressRepository.ResolveEntity(
  const AConnection: TFDConnection;
  const AEntityUuid: string;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  out AEntityID: Int64;
  out AEffectiveTenantID: Int64
): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;

  AEntityID := 0;
  AEffectiveTenantID := 0;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      AConnection;

    Query.SQL.Text :=
      'SELECT ' +
      '    entity_id, ' +
      '    tenant_id ' +
      'FROM master.entities ' +
      'WHERE entity_uuid = CAST(:entity_uuid AS uuid) ' +
      '  AND deleted_at IS NULL ';

    if not AGlobalScope then
    begin
      Query.SQL.Add(
        '  AND tenant_id = :tenant_id'
      );
    end;

    Query.ParamByName(
      'entity_uuid'
    ).AsString :=
      AEntityUuid;

    if not AGlobalScope then
    begin
      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;
    end;

    Query.Open;

    if Query.Eof then
      Exit;

    AEntityID :=
      Query.FieldByName(
        'entity_id'
      ).AsLargeInt;

    AEffectiveTenantID :=
      Query.FieldByName(
        'tenant_id'
      ).AsLargeInt;

    Result :=
      True;

  finally
    Query.Free;
  end;
end;

//***********************************************
//* CLEAR CURRENT PRIMARY
//***********************************************
class procedure TEntityAddressRepository.ClearCurrentPrimary(
  const AConnection: TFDConnection;
  const ATenantID: Int64;
  const AEntityID: Int64;
  const AExceptAddressID: Int64
);
var
  Query: TFDQuery;
begin
  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      AConnection;

    Query.SQL.Text :=
      'UPDATE master.entity_addresses SET ' +
      '    is_primary = FALSE, ' +
      '    updated_at = CURRENT_TIMESTAMP ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND entity_id = :entity_id ' +
      '  AND is_primary = TRUE ';

    if AExceptAddressID > 0 then
    begin
      Query.SQL.Add(
        '  AND entity_address_id <> :entity_address_id'
      );
    end;

    Query.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    Query.ParamByName(
      'entity_id'
    ).AsLargeInt :=
      AEntityID;

    if AExceptAddressID > 0 then
    begin
      Query.ParamByName(
        'entity_address_id'
      ).AsLargeInt :=
        AExceptAddressID;
    end;

    Query.ExecSQL;

  finally
    Query.Free;
  end;
end;

//***********************************************
//* LIST
//***********************************************
class function TEntityAddressRepository.List(
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
  EntityID: Int64;
  EffectiveTenantID: Int64;
begin
  Result := '[]';

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  JsonArray :=
    TJSONArray.Create;

  try
    Query.Connection :=
      Connection;

    if not ResolveEntity(
      Connection,
      AEntityUuid,
      ATenantID,
      AGlobalScope,
      EntityID,
      EffectiveTenantID
    ) then
      Exit;

    Query.SQL.Text :=
      'SELECT ' +
      '    entity_address_id, ' +
      '    tenant_id, ' +
      '    entity_id, ' +
      '    address_type, ' +
      '    postal_code, ' +
      '    address_line, ' +
      '    address_number, ' +
      '    address_complement, ' +
      '    neighborhood, ' +
      '    city, ' +
      '    state_code, ' +
      '    is_primary, ' +
      '    created_at, ' +
      '    updated_at ' +
      'FROM master.entity_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND entity_id = :entity_id ' +
      'ORDER BY ' +
      '    CASE address_type ' +
      '      WHEN ''BUSINESS'' THEN 1 ' +
      '      WHEN ''BILLING'' THEN 2 ' +
      '      WHEN ''SHIPPING'' THEN 3 ' +
      '      WHEN ''OTHER'' THEN 4 ' +
      '      ELSE 5 ' +
      '    END';

    Query.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      EffectiveTenantID;

    Query.ParamByName(
      'entity_id'
    ).AsLargeInt :=
      EntityID;

    Query.Open;

    while not Query.Eof do
    begin
      JsonObject :=
        AddressToJson(
          Query
        );

      JsonArray.AddElement(
        JsonObject
      );

      Query.Next;
    end;

    Result :=
      JsonArray.ToJSON;

  finally
    JsonArray.Free;
    Query.Free;
    Connection.Free;
  end;
end;

//***********************************************
//* GET BY ID
//***********************************************
class function TEntityAddressRepository.GetById(
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AEntityAddressID: Int64
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  EntityID: Int64;
  EffectiveTenantID: Int64;
begin
  Result := '';

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    if not ResolveEntity(
      Connection,
      AEntityUuid,
      ATenantID,
      AGlobalScope,
      EntityID,
      EffectiveTenantID
    ) then
      Exit;

    Query.SQL.Text :=
      'SELECT ' +
      '    entity_address_id, ' +
      '    tenant_id, ' +
      '    entity_id, ' +
      '    address_type, ' +
      '    postal_code, ' +
      '    address_line, ' +
      '    address_number, ' +
      '    address_complement, ' +
      '    neighborhood, ' +
      '    city, ' +
      '    state_code, ' +
      '    is_primary, ' +
      '    created_at, ' +
      '    updated_at ' +
      'FROM master.entity_addresses ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND entity_id = :entity_id ' +
      '  AND entity_address_id = :entity_address_id';

    Query.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      EffectiveTenantID;

    Query.ParamByName(
      'entity_id'
    ).AsLargeInt :=
      EntityID;

    Query.ParamByName(
      'entity_address_id'
    ).AsLargeInt :=
      AEntityAddressID;

    Query.Open;

    if Query.Eof then
      Exit;

    JsonObject :=
      AddressToJson(
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

//***********************************************
//* CREATE
//***********************************************
class function TEntityAddressRepository.Create(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AAddressType: string;
  const APostalCode: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const AIsPrimary: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  EntityID: Int64;
  EffectiveTenantID: Int64;
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
      if not ResolveEntity(
        Connection,
        AEntityUuid,
        ATenantID,
        AGlobalScope,
        EntityID,
        EffectiveTenantID
      ) then
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
      //* PRIMARY
      //***************************************
      if AIsPrimary then
      begin
        ClearCurrentPrimary(
          Connection,
          EffectiveTenantID,
          EntityID
        );
      end;

      //***************************************
      //* INSERT
      //***************************************
      Query.SQL.Text :=
        'INSERT INTO master.entity_addresses (' +
        '    tenant_id, ' +
        '    entity_id, ' +
        '    address_type, ' +
        '    postal_code, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    is_primary ' +
        ') VALUES (' +
        '    :tenant_id, ' +
        '    :entity_id, ' +
        '    :address_type, ' +
        '    :postal_code, ' +
        '    :address_line, ' +
        '    :address_number, ' +
        '    :address_complement, ' +
        '    :neighborhood, ' +
        '    :city, ' +
        '    :state_code, ' +
        '    :is_primary ' +
        ') ' +
        'RETURNING ' +
        '    entity_address_id, ' +
        '    tenant_id, ' +
        '    entity_id, ' +
        '    address_type, ' +
        '    postal_code, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    is_primary, ' +
        '    created_at, ' +
        '    updated_at';

      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        EffectiveTenantID;

      Query.ParamByName(
        'entity_id'
      ).AsLargeInt :=
        EntityID;

      Query.ParamByName(
        'address_type'
      ).AsString :=
        UpperCase(
          Trim(
            AAddressType
          )
        );

      //***************************************
      //* POSTAL CODE
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('postal_code') do
      begin
        DataType := ftString;

        if Trim(APostalCode) = '' then
          Clear
        else
          AsString := Trim(APostalCode);
      end;

      Query.ParamByName(
        'address_line'
      ).AsString :=
        Trim(AAddressLine);

      //***************************************
      //* ADDRESS NUMBER
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('address_number') do
      begin
        DataType := ftString;

        if Trim(AAddressNumber) = '' then
          Clear
        else
          AsString := Trim(AAddressNumber);
      end;

      //***************************************
      //* COMPLEMENT
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('address_complement') do
      begin
        DataType := ftString;

        if Trim(AAddressComplement) = '' then
          Clear
        else
          AsString := Trim(AAddressComplement);
      end;

      //***************************************
      //* NEIGHBORHOOD
      //* OPTIONAL
      //***************************************
      with Query.ParamByName('neighborhood') do
      begin
        DataType := ftString;

        if Trim(ANeighborhood) = '' then
          Clear
        else
          AsString := Trim(ANeighborhood);
      end;

      Query.ParamByName(
        'city'
      ).AsString :=
        Trim(ACity);

      Query.ParamByName(
        'state_code'
      ).AsString :=
        UpperCase(
          Trim(
            AStateCode
          )
        );

      Query.ParamByName(
        'is_primary'
      ).AsBoolean :=
        AIsPrimary;

      Query.Open;

      JsonObject :=
        AddressToJson(
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

//***********************************************
//* UPDATE
//***********************************************
class function TEntityAddressRepository.Update(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AEntityAddressID: Int64;
  const AAddressType: string;
  const APostalCode: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const AIsPrimary: Boolean
): string;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  JsonObject: TJSONObject;
  EntityID: Int64;
  EffectiveTenantID: Int64;
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
      if not ResolveEntity(
        Connection,
        AEntityUuid,
        ATenantID,
        AGlobalScope,
        EntityID,
        EffectiveTenantID
      ) then
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
      //* PRIMARY
      //***************************************
      if AIsPrimary then
      begin
        ClearCurrentPrimary(
          Connection,
          EffectiveTenantID,
          EntityID,
          AEntityAddressID
        );
      end;

      //***************************************
      //* UPDATE
      //***************************************
      Query.SQL.Text :=
        'UPDATE master.entity_addresses SET ' +
        '    address_type = :address_type, ' +
        '    postal_code = :postal_code, ' +
        '    address_line = :address_line, ' +
        '    address_number = :address_number, ' +
        '    address_complement = :address_complement, ' +
        '    neighborhood = :neighborhood, ' +
        '    city = :city, ' +
        '    state_code = :state_code, ' +
        '    is_primary = :is_primary, ' +
        '    updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND entity_id = :entity_id ' +
        '  AND entity_address_id = :entity_address_id ' +
        'RETURNING ' +
        '    entity_address_id, ' +
        '    tenant_id, ' +
        '    entity_id, ' +
        '    address_type, ' +
        '    postal_code, ' +
        '    address_line, ' +
        '    address_number, ' +
        '    address_complement, ' +
        '    neighborhood, ' +
        '    city, ' +
        '    state_code, ' +
        '    is_primary, ' +
        '    created_at, ' +
        '    updated_at';

      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        EffectiveTenantID;

      Query.ParamByName(
        'entity_id'
      ).AsLargeInt :=
        EntityID;

      Query.ParamByName(
        'entity_address_id'
      ).AsLargeInt :=
        AEntityAddressID;

      Query.ParamByName(
        'address_type'
      ).AsString :=
        UpperCase(
          Trim(
            AAddressType
          )
        );

      with Query.ParamByName('postal_code') do
      begin
        DataType := ftString;

        if Trim(APostalCode) = '' then
          Clear
        else
          AsString := Trim(APostalCode);
      end;

      Query.ParamByName(
        'address_line'
      ).AsString :=
        Trim(AAddressLine);

      with Query.ParamByName('address_number') do
      begin
        DataType := ftString;

        if Trim(AAddressNumber) = '' then
          Clear
        else
          AsString := Trim(AAddressNumber);
      end;

      with Query.ParamByName('address_complement') do
      begin
        DataType := ftString;

        if Trim(AAddressComplement) = '' then
          Clear
        else
          AsString := Trim(AAddressComplement);
      end;

      with Query.ParamByName('neighborhood') do
      begin
        DataType := ftString;

        if Trim(ANeighborhood) = '' then
          Clear
        else
          AsString := Trim(ANeighborhood);
      end;

      Query.ParamByName(
        'city'
      ).AsString :=
        Trim(ACity);

      Query.ParamByName(
        'state_code'
      ).AsString :=
        UpperCase(
          Trim(
            AStateCode
          )
        );

      Query.ParamByName(
        'is_primary'
      ).AsBoolean :=
        AIsPrimary;

      Query.Open;

      if Query.Eof then
      begin
        Connection.Commit;
        Exit;
      end;

      JsonObject :=
        AddressToJson(
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

//***********************************************
//* DELETE
//***********************************************
class function TEntityAddressRepository.Delete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AGlobalScope: Boolean;
  const AEntityUuid: string;
  const AEntityAddressID: Int64
): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  EntityID: Int64;
  EffectiveTenantID: Int64;
begin
  Result := False;

  Connection :=
    TApiDatabase.NewConnection;

  Query :=
    TFDQuery.Create(nil);

  try
    Query.Connection :=
      Connection;

    Connection.StartTransaction;

    try
      if not ResolveEntity(
        Connection,
        AEntityUuid,
        ATenantID,
        AGlobalScope,
        EntityID,
        EffectiveTenantID
      ) then
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
      //* DELETE
      //***************************************
      Query.SQL.Text :=
        'DELETE FROM master.entity_addresses ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND entity_id = :entity_id ' +
        '  AND entity_address_id = :entity_address_id';

      Query.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        EffectiveTenantID;

      Query.ParamByName(
        'entity_id'
      ).AsLargeInt :=
        EntityID;

      Query.ParamByName(
        'entity_address_id'
      ).AsLargeInt :=
        AEntityAddressID;

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
