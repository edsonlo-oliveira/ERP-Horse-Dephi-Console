unit uUserRepository;

interface

type
  TUserRepository = class
  public
    class function Create(
      const ATenantId: Int64;
      const ALoginId: string;
      const AFirstName: string;
      const AMiddleName: string;
      const ALastName: string;
      const AEmail: string;
      const APasswordHash: string;
      const AStatus: string;
      const ASuperUser: Boolean
    ): string;

    class function Update(
      const AUserUuid: string;
      const ATenantId: Int64;
      const ALoginId: string;
      const AFirstName: string;
      const AMiddleName: string;
      const ALastName: string;
      const AEmail: string;
      const APasswordHash: string;
      const AStatus: string;
      const ASuperUser: Boolean
    ): string;

    class function List(
      const ATenantId: Int64
    ): string;

    class function GetByUuid(
      const AUserUuid: string;
      const ATenantId: Int64
    ): string;

    class function Delete(
      const AUserUuid: string;
      const ATenantId: Int64
    ): Boolean;

    class function LoginExists(
      const ALoginId: string;
      const AUserUuid: string
    ): Boolean;

    class function EmailExists(
      const ATenantId: Int64;
      const AEmail: string;
      const AUserUuid: string
    ): Boolean;

    class function SuperUserExists(
      const ATenantId: Int64;
      const AUserUuid: string
    ): Boolean;

    class function FindByLogin(
      const ALoginId: string
    ): string;
    end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uApiDatabase;

//***************************************
//* USERTOJSON
//***************************************
function UserToJson(AQuery: TFDQuery): TJSONObject;
var
  LValue: TJSONValue;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'user_id',
    TJSONNumber.Create(AQuery.FieldByName('user_id').AsLargeInt)
  );

  Result.AddPair(
    'user_uuid',
    AQuery.FieldByName('user_uuid').AsString
  );

  Result.AddPair(
    'tenant_id',
    TJSONNumber.Create(AQuery.FieldByName('tenant_id').AsLargeInt)
  );

  Result.AddPair(
    'login_id',
    AQuery.FieldByName('login_id').AsString
  );

  Result.AddPair(
    'first_name',
    AQuery.FieldByName('first_name').AsString
  );

  if AQuery.FieldByName('middle_name').IsNull then
    Result.AddPair('middle_name', TJSONNull.Create)
  else
    Result.AddPair(
      'middle_name',
      AQuery.FieldByName('middle_name').AsString
    );

  Result.AddPair(
    'last_name',
    AQuery.FieldByName('last_name').AsString
  );

  Result.AddPair(
    'email',
    AQuery.FieldByName('email').AsString
  );

  Result.AddPair(
    'status',
    AQuery.FieldByName('status').AsString
  );

  Result.AddPair(
    'super_user',
    TJSONBool.Create(AQuery.FieldByName('super_user').AsBoolean)
  );

  if AQuery.FieldByName('last_login_at').IsNull then
    Result.AddPair('last_login_at', TJSONNull.Create)
  else
    Result.AddPair(
      'last_login_at',
      AQuery.FieldByName('last_login_at').AsString
    );

  if AQuery.FieldByName('created_at').IsNull then
    Result.AddPair('created_at', TJSONNull.Create)
  else
    Result.AddPair(
      'created_at',
      AQuery.FieldByName('created_at').AsString
    );

  if AQuery.FieldByName('updated_at').IsNull then
    Result.AddPair('updated_at', TJSONNull.Create)
  else
    Result.AddPair(
      'updated_at',
      AQuery.FieldByName('updated_at').AsString
    );

  if AQuery.FieldByName('deleted_at').IsNull then
    Result.AddPair('deleted_at', TJSONNull.Create)
  else
    Result.AddPair(
      'deleted_at',
      AQuery.FieldByName('deleted_at').AsString
    );

  LValue := nil;
end;

//***************************************
//* LIST
//***************************************
class function TUserRepository.List(
  const ATenantId: Int64
): string;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '  user_id, ' +
      '  user_uuid::text AS user_uuid, ' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  first_name, ' +
      '  middle_name, ' +
      '  last_name, ' +
      '  email, ' +
      '  status, ' +
      '  super_user, ' +
      '  last_login_at, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at ' +
      'FROM core.users ' +
      'WHERE tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL ' +
      'ORDER BY first_name, last_name, login_id';

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.Open;

    LArray := TJSONArray.Create;
    try
      while not LQuery.Eof do
      begin
        LArray.AddElement(UserToJson(LQuery));
        LQuery.Next;
      end;

      Result := LArray.ToJSON;
    finally
      LArray.Free;
    end;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* GETBYUUID
//***************************************
class function TUserRepository.GetByUuid(
  const AUserUuid: string;
  const ATenantId: Int64
): string;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LUserUuid: string;
  LJson: TJSONObject;
begin
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '  user_id, ' +
      '  user_uuid::text AS user_uuid, ' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  first_name, ' +
      '  middle_name, ' +
      '  last_name, ' +
      '  email, ' +
      '  status, ' +
      '  super_user, ' +
      '  last_login_at, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at ' +
      'FROM core.users ' +
      'WHERE user_uuid = CAST(:user_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL';

    LQuery.ParamByName('user_uuid').DataType := ftString;
    LQuery.ParamByName('user_uuid').AsString := LUserUuid;

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.Open;

    if LQuery.Eof then
      Exit('');

    LJson := UserToJson(LQuery);
    try
      Result := LJson.ToJSON;
    finally
      LJson.Free;
    end;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* CREATE
//***************************************
class function TUserRepository.Create(
  const ATenantId: Int64;
  const ALoginId: string;
  const AFirstName: string;
  const AMiddleName: string;
  const ALastName: string;
  const AEmail: string;
  const APasswordHash: string;
  const AStatus: string;
  const ASuperUser: Boolean
): string;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LMiddleName: string;
begin
  LMiddleName := Trim(AMiddleName);

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'INSERT INTO core.users (' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  first_name, ' +
      '  middle_name, ' +
      '  last_name, ' +
      '  email, ' +
      '  password_hash, ' +
      '  status, ' +
      '  super_user' +
      ') VALUES (' +
      '  :tenant_id, ' +
      '  :login_id, ' +
      '  :first_name, ' +
      '  :middle_name, ' +
      '  :last_name, ' +
      '  :email, ' +
      '  :password_hash, ' +
      '  :status, ' +
      '  :super_user' +
      ') ' +
      'RETURNING ' +
      '  user_id, ' +
      '  user_uuid::text AS user_uuid, ' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  first_name, ' +
      '  middle_name, ' +
      '  last_name, ' +
      '  email, ' +
      '  status, ' +
      '  super_user, ' +
      '  last_login_at, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at';

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.ParamByName('login_id').DataType := ftString;
    LQuery.ParamByName('login_id').AsString := Trim(ALoginId);

    LQuery.ParamByName('first_name').DataType := ftString;
    LQuery.ParamByName('first_name').AsString := Trim(AFirstName);

    LQuery.ParamByName('middle_name').DataType := ftString;

    if LMiddleName = '' then
      LQuery.ParamByName('middle_name').Clear
    else
      LQuery.ParamByName('middle_name').AsString := LMiddleName;

    LQuery.ParamByName('last_name').DataType := ftString;
    LQuery.ParamByName('last_name').AsString := Trim(ALastName);

    LQuery.ParamByName('email').DataType := ftString;
    LQuery.ParamByName('email').AsString := LowerCase(Trim(AEmail));

    LQuery.ParamByName('password_hash').DataType := ftString;
    LQuery.ParamByName('password_hash').AsString := APasswordHash;

    LQuery.ParamByName('status').DataType := ftString;
    LQuery.ParamByName('status').AsString := UpperCase(Trim(AStatus));

    LQuery.ParamByName('super_user').DataType := ftBoolean;
    LQuery.ParamByName('super_user').AsBoolean := ASuperUser;

    LQuery.Open;

    if LQuery.Eof then
      Exit('');

    LJson := UserToJson(LQuery);
    try
      Result := LJson.ToJSON;
    finally
      LJson.Free;
    end;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* UPDATE
//***************************************
class function TUserRepository.Update(
  const AUserUuid: string;
  const ATenantId: Int64;
  const ALoginId: string;
  const AFirstName: string;
  const AMiddleName: string;
  const ALastName: string;
  const AEmail: string;
  const APasswordHash: string;
  const AStatus: string;
  const ASuperUser: Boolean
): string;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LUserUuid: string;
  LMiddleName: string;
begin
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  LMiddleName := Trim(AMiddleName);

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'UPDATE core.users SET ' +
      '  login_id = :login_id, ' +
      '  first_name = :first_name, ' +
      '  middle_name = :middle_name, ' +
      '  last_name = :last_name, ' +
      '  email = :email, ' +
      '  password_hash = CASE ' +
      '    WHEN :password_hash = '''' THEN password_hash ' +
      '    ELSE :password_hash ' +
      '  END, ' +
      '  status = :status, ' +
      '  super_user = :super_user, ' +
      '  updated_at = CURRENT_TIMESTAMP ' +
      'WHERE user_uuid = CAST(:user_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL ' +
      'RETURNING ' +
      '  user_id, ' +
      '  user_uuid::text AS user_uuid, ' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  first_name, ' +
      '  middle_name, ' +
      '  last_name, ' +
      '  email, ' +
      '  status, ' +
      '  super_user, ' +
      '  last_login_at, ' +
      '  created_at, ' +
      '  updated_at, ' +
      '  deleted_at';

    LQuery.ParamByName('login_id').DataType := ftString;
    LQuery.ParamByName('login_id').AsString := Trim(ALoginId);

    LQuery.ParamByName('first_name').DataType := ftString;
    LQuery.ParamByName('first_name').AsString := Trim(AFirstName);

    LQuery.ParamByName('middle_name').DataType := ftString;

    if LMiddleName = '' then
      LQuery.ParamByName('middle_name').Clear
    else
      LQuery.ParamByName('middle_name').AsString := LMiddleName;

    LQuery.ParamByName('last_name').DataType := ftString;
    LQuery.ParamByName('last_name').AsString := Trim(ALastName);

    LQuery.ParamByName('email').DataType := ftString;
    LQuery.ParamByName('email').AsString := LowerCase(Trim(AEmail));

    LQuery.ParamByName('password_hash').DataType := ftString;
    LQuery.ParamByName('password_hash').AsString := APasswordHash;

    LQuery.ParamByName('status').DataType := ftString;
    LQuery.ParamByName('status').AsString := UpperCase(Trim(AStatus));

    LQuery.ParamByName('super_user').DataType := ftBoolean;
    LQuery.ParamByName('super_user').AsBoolean := ASuperUser;

    LQuery.ParamByName('user_uuid').DataType := ftString;
    LQuery.ParamByName('user_uuid').AsString := LUserUuid;

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.Open;

    if LQuery.Eof then
      Exit('');

    LJson := UserToJson(LQuery);
    try
      Result := LJson.ToJSON;
    finally
      LJson.Free;
    end;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* DELETE
//***************************************
class function TUserRepository.Delete(
  const AUserUuid: string;
  const ATenantId: Int64
): Boolean;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LUserUuid: string;
begin
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'UPDATE core.users SET ' +
      '  status = ''INACTIVE'', ' +
      '  deleted_at = CURRENT_TIMESTAMP, ' +
      '  updated_at = CURRENT_TIMESTAMP ' +
      'WHERE user_uuid = CAST(:user_uuid AS uuid) ' +
      '  AND tenant_id = :tenant_id ' +
      '  AND deleted_at IS NULL';

    LQuery.ParamByName('user_uuid').DataType := ftString;
    LQuery.ParamByName('user_uuid').AsString := LUserUuid;

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.ExecSQL;

    Result := LQuery.RowsAffected > 0;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* LOGINEXISTS
//***************************************
class function TUserRepository.LoginExists(
  const ALoginId: string;
  const AUserUuid: string
): Boolean;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LLoginId: string;
  LUserUuid: string;
begin
  LLoginId := Trim(ALoginId);
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.users ' +
      '  WHERE login_id = :login_id ' +
      '    AND (' +
      '      :exclude_uuid = '''' ' +
      '      OR user_uuid <> CAST(:exclude_uuid AS uuid)' +
      '    )' +
      ') AS login_exists';

    LQuery.ParamByName('login_id').DataType := ftString;
    LQuery.ParamByName('login_id').AsString := LLoginId;

    LQuery.ParamByName('exclude_uuid').DataType := ftString;
    LQuery.ParamByName('exclude_uuid').AsString := LUserUuid;

    LQuery.Open;

    Result := LQuery.FieldByName('login_exists').AsBoolean;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* EMAILEXISTS
//***************************************
class function TUserRepository.EmailExists(
  const ATenantId: Int64;
  const AEmail: string;
  const AUserUuid: string
): Boolean;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LEmail: string;
  LUserUuid: string;
begin
  LEmail := LowerCase(Trim(AEmail));
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.users ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND email = :email ' +
      '    AND (' +
      '      :exclude_uuid = '''' ' +
      '      OR user_uuid <> CAST(:exclude_uuid AS uuid)' +
      '    )' +
      ') AS email_exists';

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.ParamByName('email').DataType := ftString;
    LQuery.ParamByName('email').AsString := LEmail;

    LQuery.ParamByName('exclude_uuid').DataType := ftString;
    LQuery.ParamByName('exclude_uuid').AsString := LUserUuid;

    LQuery.Open;

    Result := LQuery.FieldByName('email_exists').AsBoolean;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* SUPERUSEREXISTS
//***************************************
class function TUserRepository.SuperUserExists(
  const ATenantId: Int64;
  const AUserUuid: string
): Boolean;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LUserUuid: string;
begin
  LUserUuid := Trim(AUserUuid);

  LUserUuid := StringReplace(
    LUserUuid,
    '{',
    '',
    [rfReplaceAll]
  );

  LUserUuid := StringReplace(
    LUserUuid,
    '}',
    '',
    [rfReplaceAll]
  );

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT EXISTS (' +
      '  SELECT 1 ' +
      '  FROM core.users ' +
      '  WHERE tenant_id = :tenant_id ' +
      '    AND super_user = TRUE ' +
      '    AND status = ''ACTIVE'' ' +
      '    AND deleted_at IS NULL ' +
      '    AND (' +
      '      :exclude_uuid = '''' ' +
      '      OR user_uuid <> CAST(:exclude_uuid AS uuid)' +
      '    )' +
      ') AS super_user_exists';

    LQuery.ParamByName('tenant_id').DataType := ftLargeint;
    LQuery.ParamByName('tenant_id').AsLargeInt := ATenantId;

    LQuery.ParamByName('exclude_uuid').DataType := ftString;
    LQuery.ParamByName('exclude_uuid').AsString := LUserUuid;

    LQuery.Open;

    Result := LQuery.FieldByName('super_user_exists').AsBoolean;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

//***************************************
//* FINDBYLOGIN
//***************************************
class function TUserRepository.FindByLogin(
  const ALoginId: string
): string;
var
  Connection: TFDConnection;
  LQuery: TFDQuery;
  LJson: TJSONObject;
begin
  Result := '';

  Connection := TApiDatabase.NewConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := Connection;

    LQuery.SQL.Text :=
      'SELECT ' +
      '  user_id, ' +
      '  user_uuid, ' +
      '  tenant_id, ' +
      '  login_id, ' +
      '  password_hash, ' +
      '  status, ' +
      '  super_user ' +
      'FROM core.users ' +
      'WHERE login_id = :login_id ' +
      '  AND deleted_at IS NULL';

    LQuery.ParamByName('login_id').DataType :=
      ftString;

    LQuery.ParamByName('login_id').AsString :=
      Trim(ALoginId);

    LQuery.Open;

    if LQuery.Eof then
      Exit;

    LJson := TJSONObject.Create;
    try
      LJson.AddPair(
        'user_id',
        TJSONNumber.Create(
          LQuery.FieldByName('user_id').AsLargeInt
        )
      );

      LJson.AddPair(
        'user_uuid',
        LQuery.FieldByName('user_uuid').AsString
      );

      LJson.AddPair(
        'tenant_id',
        TJSONNumber.Create(
          LQuery.FieldByName('tenant_id').AsLargeInt
        )
      );

      LJson.AddPair(
        'login_id',
        LQuery.FieldByName('login_id').AsString
      );

      LJson.AddPair(
        'password_hash',
        LQuery.FieldByName('password_hash').AsString
      );

      LJson.AddPair(
        'status',
        LQuery.FieldByName('status').AsString
      );

      LJson.AddPair(
        'super_user',
        TJSONBool.Create(
          LQuery.FieldByName('super_user').AsBoolean
        )
      );

      Result := LJson.ToJSON;

    finally
      LJson.Free;
    end;

  finally
    LQuery.Free;
    Connection.Free;
  end;
end;

end.
