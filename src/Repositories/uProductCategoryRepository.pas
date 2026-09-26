unit uProductCategoryRepository;

interface

uses
  System.JSON,
  FireDAC.Comp.Client;

type
  TProductCategoryRepository = class
  private
    class function NormalizeUuid(
      const AUuid: string
    ): string; static;

    class function CategoryToJson(
      const AQuery: TFDQuery
    ): TJSONObject; static;

  public
    class function List(
      const ATenantID: Int64
    ): string; static;

    class function GetByUuid(
      const ATenantID: Int64;
      const AProductCategoryUuid: string
    ): string; static;

    class function Create(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ACategoryName: string;
      const AParentCategoryID: Int64;
      const AActive: Boolean
    ): string; static;

    class function Update(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AProductCategoryID: Int64;
      const ACategoryName: string;
      const AParentCategoryID: Int64;
      const AActive: Boolean
    ): string; static;

    class function Delete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean; static;

    class function HardDelete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean;

    class function SetActive(
      const AUserID: Int64;
      const ATenantID: Int64;
      const AProductCategoryID: Int64;
      const AActive: Boolean
    ): Boolean; static;

    class function GetIdByUuid(
      const ATenantID: Int64;
      const AProductCategoryUuid: string
    ): Int64; static;

    class function GetIdByUuidIncludingDeleted(
      const ATenantID: Int64;
      const AProductCategoryUuid: string
    ): Int64; static;

    class function Exists(
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean; static;

    class function CategoryBelongsToTenant(
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean; static;

    class function ExistsNameInLevel(
      const ATenantID: Int64;
      const ACategoryName: string;
      const AParentCategoryID: Int64;
      const AIgnoreCategoryID: Int64 = 0
    ): Boolean; static;

    class function HasChildren(
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean; static;

    class function HasAnyChildren(
      const ATenantID: Int64;
      const AProductCategoryID: Int64
    ): Boolean;

    class function IsDescendant(
      const ATenantID: Int64;
      const AProductCategoryID: Int64;
      const APossibleDescendantID: Int64
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Param,
  uApiDatabase,
  uAuditContext;


//******************************************
//* NORMALIZE UUID
//******************************************
class function TProductCategoryRepository.NormalizeUuid(
  const AUuid: string
): string;
begin
  Result :=
    Trim(
      AUuid
    );

  Result :=
    StringReplace(
      Result,
      '{',
      '',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '}',
      '',
      [rfReplaceAll]
    );
end;


//******************************************
//* CATEGORY TO JSON
//******************************************
class function TProductCategoryRepository.CategoryToJson(
  const AQuery: TFDQuery
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'product_category_uuid',
    AQuery.FieldByName(
      'product_category_uuid'
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
    'category_name',
    AQuery.FieldByName(
      'category_name'
    ).AsString
  );

  if AQuery.FieldByName(
    'parent_category_uuid'
  ).IsNull then
  begin
    Result.AddPair(
      'parent_category_uuid',
      TJSONNull.Create
    );
  end
  else
  begin
    Result.AddPair(
      'parent_category_uuid',
      AQuery.FieldByName(
        'parent_category_uuid'
      ).AsString
    );
  end;

  Result.AddPair(
    'active',
    TJSONBool.Create(
      AQuery.FieldByName(
        'active'
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


//******************************************
//* LIST
//******************************************
class function TProductCategoryRepository.List(
  const ATenantID: Int64
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  LArray :=
    TJSONArray.Create;

  try
    LQuery.Connection :=
      LConnection;

      LQuery.SQL.Text :=
        'SELECT ' +
        '  c.product_category_uuid::text AS product_category_uuid, ' +
        '  c.tenant_id, ' +
        '  c.category_name, ' +
        '  p.product_category_uuid::text AS parent_category_uuid, ' +
        '  c.active, ' +
        '  c.created_at, ' +
        '  c.updated_at ' +
        'FROM master.product_categories c ' +
        'LEFT JOIN master.product_categories p ' +
        '  ON p.tenant_id = c.tenant_id ' +
        ' AND p.product_category_id = c.parent_category_id ' +
        ' AND p.deleted_at IS NULL ' +
        'WHERE c.tenant_id = :tenant_id ' +
        '  AND c.deleted_at IS NULL ' +
        'ORDER BY c.category_name';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.Open;

    while not LQuery.Eof do
    begin
      LArray.AddElement(
        CategoryToJson(
          LQuery
        )
      );

      LQuery.Next;
    end;

    Result :=
      LArray.ToJSON;

  finally
    LArray.Free;
    LQuery.Free;
    LConnection.Free;
  end;
end;


//******************************************
//* GET BY UUID
//******************************************
class function TProductCategoryRepository.GetByUuid(
  const ATenantID: Int64;
  const AProductCategoryUuid: string
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LUuid: string;
begin
  Result := '';

  LUuid :=
    NormalizeUuid(
      AProductCategoryUuid
    );

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '  c.product_category_uuid::text AS product_category_uuid, ' +
      '  c.tenant_id, ' +
      '  c.category_name, ' +
      '  p.product_category_uuid::text AS parent_category_uuid, ' +
      '  c.active, ' +
      '  c.created_at, ' +
      '  c.updated_at ' +
      'FROM master.product_categories c ' +
      'LEFT JOIN master.product_categories p ' +
      '  ON p.tenant_id = c.tenant_id ' +
      ' AND p.product_category_id = c.parent_category_id ' +
      ' AND p.deleted_at IS NULL ' +
      'WHERE c.tenant_id = :tenant_id ' +
      '  AND c.product_category_uuid = ' +
      '      CAST(:product_category_uuid AS uuid) ' +
      '  AND c.deleted_at IS NULL';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_uuid'
    ).DataType :=
      ftString;

    LQuery.ParamByName(
      'product_category_uuid'
    ).AsString :=
      LUuid;

    LQuery.Open;

    if LQuery.Eof then
      Exit;

    LJson :=
      CategoryToJson(
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


//******************************************
//* CREATE
//******************************************
class function TProductCategoryRepository.Create(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ACategoryName: string;
  const AParentCategoryID: Int64;
  const AActive: Boolean
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LProductCategoryID: Int64;
begin
  Result := '';

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
        ATenantID
      );

      //***************************************
      //* INSERT
      //***************************************
      LQuery.SQL.Text :=
        'INSERT INTO master.product_categories ( ' +
        '  tenant_id, ' +
        '  category_name, ' +
        '  parent_category_id, ' +
        '  active ' +
        ') VALUES ( ' +
        '  :tenant_id, ' +
        '  :category_name, ' +
        '  :parent_category_id, ' +
        '  :active ' +
        ') ' +
        'RETURNING product_category_id';

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'category_name'
      ).DataType :=
        ftString;

      LQuery.ParamByName(
        'category_name'
      ).AsString :=
        Trim(
          ACategoryName
        );

      LQuery.ParamByName(
        'parent_category_id'
      ).DataType :=
        ftLargeint;

      if AParentCategoryID > 0 then
      begin
        LQuery.ParamByName(
          'parent_category_id'
        ).AsLargeInt :=
          AParentCategoryID;
      end
      else
      begin
        LQuery.ParamByName(
          'parent_category_id'
        ).Clear;
      end;

      LQuery.ParamByName(
        'active'
      ).DataType :=
        ftBoolean;

      LQuery.ParamByName(
        'active'
      ).AsBoolean :=
        AActive;

      LQuery.Open;

      if LQuery.Eof then
      begin
        LConnection.Rollback;
        Exit;
      end;

      LProductCategoryID :=
        LQuery.FieldByName(
          'product_category_id'
        ).AsLargeInt;

      LQuery.Close;

      //***************************************
      //* LOAD CREATED CATEGORY
      //***************************************
      LQuery.SQL.Text :=
        'SELECT ' +
        '  c.product_category_uuid::text ' +
        '    AS product_category_uuid, ' +
        '  c.tenant_id, ' +
        '  c.category_name, ' +
        '  p.product_category_uuid::text ' +
        '    AS parent_category_uuid, ' +
        '  c.active, ' +
        '  c.created_at, ' +
        '  c.updated_at ' +
        'FROM master.product_categories c ' +
        'LEFT JOIN master.product_categories p ' +
        '  ON p.tenant_id = c.tenant_id ' +
        ' AND p.product_category_id = c.parent_category_id ' +
        'WHERE c.tenant_id = :tenant_id ' +
        '  AND c.product_category_id = ' +
        '      :product_category_id';

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        LProductCategoryID;

      LQuery.Open;

      if LQuery.Eof then
      begin
        LConnection.Rollback;
        Exit;
      end;

      LJson :=
        CategoryToJson(
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


//******************************************
//* UPDATE
//******************************************
class function TProductCategoryRepository.Update(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AProductCategoryID: Int64;
  const ACategoryName: string;
  const AParentCategoryID: Int64;
  const AActive: Boolean
): string;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
begin
  Result := '';

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
        ATenantID
      );

      //***************************************
      //* UPDATE
      //***************************************
      LQuery.SQL.Text :=
        'UPDATE master.product_categories SET ' +
        '  category_name = :category_name, ' +
        '  parent_category_id = :parent_category_id, ' +
        '  active = :active, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND product_category_id = :product_category_id ' +
        '  AND deleted_at IS NULL';

      LQuery.ParamByName(
        'category_name'
      ).DataType :=
        ftString;

      LQuery.ParamByName(
        'category_name'
      ).AsString :=
        Trim(
          ACategoryName
        );

      LQuery.ParamByName(
        'parent_category_id'
      ).DataType :=
        ftLargeint;

      if AParentCategoryID > 0 then
      begin
        LQuery.ParamByName(
          'parent_category_id'
        ).AsLargeInt :=
          AParentCategoryID;
      end
      else
      begin
        LQuery.ParamByName(
          'parent_category_id'
        ).Clear;
      end;

      LQuery.ParamByName(
        'active'
      ).DataType :=
        ftBoolean;

      LQuery.ParamByName(
        'active'
      ).AsBoolean :=
        AActive;

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        AProductCategoryID;

      LQuery.ExecSQL;

      if LQuery.RowsAffected = 0 then
      begin
        LConnection.Rollback;
        Exit;
      end;

      //***************************************
      //* LOAD UPDATED CATEGORY
      //***************************************
      LQuery.SQL.Text :=
        'SELECT ' +
        '  c.product_category_uuid::text ' +
        '    AS product_category_uuid, ' +
        '  c.tenant_id, ' +
        '  c.category_name, ' +
        '  p.product_category_uuid::text ' +
        '    AS parent_category_uuid, ' +
        '  c.active, ' +
        '  c.created_at, ' +
        '  c.updated_at ' +
        'FROM master.product_categories c ' +
        'LEFT JOIN master.product_categories p ' +
        '  ON p.tenant_id = c.tenant_id ' +
        ' AND p.product_category_id = c.parent_category_id ' +
        'WHERE c.tenant_id = :tenant_id ' +
        '  AND c.product_category_id = :product_category_id ' +
        '  AND c.deleted_at IS NULL';

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        AProductCategoryID;

      LQuery.Open;

      if LQuery.Eof then
      begin
        LConnection.Rollback;
        Exit;
      end;

      LJson :=
        CategoryToJson(
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


//******************************************
//* SOFT DELETE
//******************************************
class function TProductCategoryRepository.Delete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
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
        ATenantID
      );

      //***************************************
      //* SOFT DELETE
      //***************************************
      LQuery.SQL.Text :=
        'UPDATE master.product_categories SET ' +
        '  active = FALSE, ' +
        '  deleted_at = CURRENT_TIMESTAMP, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND product_category_id = :product_category_id ' +
        '  AND deleted_at IS NULL';

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        AProductCategoryID;

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

//******************************************
//* HARD DELETE
//******************************************
class function TProductCategoryRepository.HardDelete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
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
        ATenantID
      );

      //***************************************
      //* HARD DELETE
      //***************************************
      LQuery.SQL.Text :=
        'DELETE FROM master.product_categories ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND product_category_id = :product_category_id';

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        AProductCategoryID;

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

//******************************************
//* SET ACTIVE
//******************************************
class function TProductCategoryRepository.SetActive(
  const AUserID: Int64;
  const ATenantID: Int64;
  const AProductCategoryID: Int64;
  const AActive: Boolean
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
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
        ATenantID
      );

      //***************************************
      //* UPDATE ACTIVE
      //***************************************
      LQuery.SQL.Text :=
        'UPDATE master.product_categories SET ' +
        '  active = :active, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE tenant_id = :tenant_id ' +
        '  AND product_category_id = :product_category_id ' +
        '  AND deleted_at IS NULL';

      LQuery.ParamByName(
        'active'
      ).DataType :=
        ftBoolean;

      LQuery.ParamByName(
        'active'
      ).AsBoolean :=
        AActive;

      LQuery.ParamByName(
        'tenant_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'tenant_id'
      ).AsLargeInt :=
        ATenantID;

      LQuery.ParamByName(
        'product_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'product_category_id'
      ).AsLargeInt :=
        AProductCategoryID;

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


//******************************************
//* GET ID BY UUID
//******************************************
class function TProductCategoryRepository.GetIdByUuid(
  const ATenantID: Int64;
  const AProductCategoryUuid: string
): Int64;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LUuid: string;
begin
  Result := 0;

  LUuid :=
    NormalizeUuid(
      AProductCategoryUuid
    );

  if LUuid = '' then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT product_category_id ' +
      'FROM master.product_categories ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND product_category_uuid = ' +
      '      CAST(:product_category_uuid AS uuid) ' +
      '  AND deleted_at IS NULL';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_uuid'
    ).DataType :=
      ftString;

    LQuery.ParamByName(
      'product_category_uuid'
    ).AsString :=
      LUuid;

    LQuery.Open;

    if not LQuery.Eof then
    begin
      Result :=
        LQuery.FieldByName(
          'product_category_id'
        ).AsLargeInt;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//******************************************
//* EXISTS
//******************************************
class function TProductCategoryRepository.Exists(
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT EXISTS ( ' +
      '  SELECT 1 ' +
      '  FROM master.product_categories ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND product_category_id = :product_category_id ' +
      '    AND deleted_at IS NULL ' +
      ') AS exists_category';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'product_category_id'
    ).AsLargeInt :=
      AProductCategoryID;

    LQuery.Open;

    Result :=
      LQuery.FieldByName(
        'exists_category'
      ).AsBoolean;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//******************************************
//* CATEGORY BELONGS TO TENANT
//******************************************
class function TProductCategoryRepository.CategoryBelongsToTenant(
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
begin
  Result :=
    Exists(
      ATenantID,
      AProductCategoryID
    );
end;


//******************************************
//* EXISTS NAME IN LEVEL
//******************************************
class function TProductCategoryRepository.ExistsNameInLevel(
  const ATenantID: Int64;
  const ACategoryName: string;
  const AParentCategoryID: Int64;
  const AIgnoreCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT EXISTS ( ' +
      '  SELECT 1 ' +
      '  FROM master.product_categories ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND LOWER(TRIM(category_name)) = ' +
      '        LOWER(TRIM(:category_name)) ' +
      '    AND deleted_at IS NULL ';

    if AParentCategoryID > 0 then
    begin
      LQuery.SQL.Add(
        '    AND parent_category_id = ' +
        '        :parent_category_id '
      );
    end
    else
    begin
      LQuery.SQL.Add(
        '    AND parent_category_id IS NULL '
      );
    end;

    if AIgnoreCategoryID > 0 then
    begin
      LQuery.SQL.Add(
        '    AND product_category_id <> ' +
        '        :ignore_category_id '
      );
    end;

    LQuery.SQL.Add(
      ') AS exists_name'
    );

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'category_name'
    ).DataType :=
      ftString;

    LQuery.ParamByName(
      'category_name'
    ).AsString :=
      Trim(
        ACategoryName
      );

    if AParentCategoryID > 0 then
    begin
      LQuery.ParamByName(
        'parent_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'parent_category_id'
      ).AsLargeInt :=
        AParentCategoryID;
    end;

    if AIgnoreCategoryID > 0 then
    begin
      LQuery.ParamByName(
        'ignore_category_id'
      ).DataType :=
        ftLargeint;

      LQuery.ParamByName(
        'ignore_category_id'
      ).AsLargeInt :=
        AIgnoreCategoryID;
    end;

    LQuery.Open;

    Result :=
      LQuery.FieldByName(
        'exists_name'
      ).AsBoolean;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//******************************************
//* HAS CHILDREN
//******************************************
class function TProductCategoryRepository.HasChildren(
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT EXISTS ( ' +
      '  SELECT 1 ' +
      '  FROM master.product_categories ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND parent_category_id = :product_category_id ' +
      '    AND deleted_at IS NULL ' +
      ') AS has_children';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'product_category_id'
    ).AsLargeInt :=
      AProductCategoryID;

    LQuery.Open;

    Result :=
      LQuery.FieldByName(
        'has_children'
      ).AsBoolean;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;


//******************************************
//* IS DESCENDANT
//******************************************
class function TProductCategoryRepository.IsDescendant(
  const ATenantID: Int64;
  const AProductCategoryID: Int64;
  const APossibleDescendantID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := False;

  if (AProductCategoryID <= 0) or
     (APossibleDescendantID <= 0) then
  begin
    Exit;
  end;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'WITH RECURSIVE descendants AS ( ' +

      '  SELECT ' +
      '    product_category_id ' +
      '  FROM master.product_categories ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND parent_category_id = :product_category_id ' +
      '    AND deleted_at IS NULL ' +

      '  UNION ALL ' +

      '  SELECT ' +
      '    pc.product_category_id ' +
      '  FROM master.product_categories pc ' +
      '  INNER JOIN descendants d ' +
      '    ON pc.parent_category_id = d.product_category_id ' +
      '  WHERE pc.tenant_id = :tenant_id ' +
      '    AND pc.deleted_at IS NULL ' +

      ') ' +

      'SELECT EXISTS ( ' +
      '  SELECT 1 ' +
      '  FROM descendants ' +
      '  WHERE product_category_id = :possible_descendant_id ' +
      ') AS is_descendant';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'product_category_id'
    ).AsLargeInt :=
      AProductCategoryID;

    LQuery.ParamByName(
      'possible_descendant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'possible_descendant_id'
    ).AsLargeInt :=
      APossibleDescendantID;

    LQuery.Open;

    Result :=
      LQuery.FieldByName(
        'is_descendant'
      ).AsBoolean;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

//******************************************
//* HAS ANY CHILDREN
//******************************************
class function TProductCategoryRepository.HasAnyChildren(
  const ATenantID: Int64;
  const AProductCategoryID: Int64
): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT EXISTS ( ' +
      '  SELECT 1 ' +
      '  FROM master.product_categories ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND parent_category_id = :product_category_id ' +
      ') AS has_children';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'product_category_id'
    ).AsLargeInt :=
      AProductCategoryID;

    LQuery.Open;

    Result :=
      LQuery.FieldByName(
        'has_children'
      ).AsBoolean;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

//******************************************
//* GET ID BY UUID INCLUDING DELETED
//******************************************
class function TProductCategoryRepository.GetIdByUuidIncludingDeleted(
  const ATenantID: Int64;
  const AProductCategoryUuid: string
): Int64;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LUuid: string;
begin
  Result := 0;

  LUuid :=
    NormalizeUuid(
      AProductCategoryUuid
    );

  if LUuid = '' then
    Exit;

  LConnection :=
    TApiDatabase.NewConnection;

  LQuery :=
    TFDQuery.Create(nil);

  try
    LQuery.Connection :=
      LConnection;

    LQuery.SQL.Text :=
      'SELECT product_category_id ' +
      'FROM master.product_categories ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND product_category_uuid = ' +
      '      CAST(:product_category_uuid AS uuid)';

    LQuery.ParamByName(
      'tenant_id'
    ).DataType :=
      ftLargeint;

    LQuery.ParamByName(
      'tenant_id'
    ).AsLargeInt :=
      ATenantID;

    LQuery.ParamByName(
      'product_category_uuid'
    ).DataType :=
      ftString;

    LQuery.ParamByName(
      'product_category_uuid'
    ).AsString :=
      LUuid;

    LQuery.Open;

    if not LQuery.Eof then
    begin
      Result :=
        LQuery.FieldByName(
          'product_category_id'
        ).AsLargeInt;
    end;

  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

end.
