unit uApiDatabase;

interface

uses
  System.SysUtils,
  System.IniFiles,
  FireDAC.Comp.Client,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef;

type
  TApiDatabase = class
  private
    class var FConnection: TFDConnection;
    class var FDriverLink: TFDPhysPgDriverLink;

    class function ConfigFileName: string; static;
    class procedure CreateConnection; static;
  public
    class procedure Initialize; static;
    class procedure Finalize; static;
    class function Connection: TFDConnection; static;
  end;

implementation

class function TApiDatabase.ConfigFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(ParamStr(0))
  ) + 'ERPServer.ini';
end;

class procedure TApiDatabase.CreateConnection;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ConfigFileName);
  try
    FDriverLink := TFDPhysPgDriverLink.Create(nil);

    FDriverLink.VendorLib :=
      Ini.ReadString('Database', 'VendorLib', '');

    FConnection := TFDConnection.Create(nil);
    FConnection.LoginPrompt := False;

    FConnection.Params.Clear;
    FConnection.Params.DriverID := 'PG';

    FConnection.Params.Values['Server'] :=
      Ini.ReadString('Database', 'Server', 'localhost');

    FConnection.Params.Values['Port'] :=
      Ini.ReadString('Database', 'Port', '5432');

    FConnection.Params.Values['Database'] :=
      Ini.ReadString('Database', 'Database', '');

    FConnection.Params.Values['User_Name'] :=
      Ini.ReadString('Database', 'User_Name', '');

    FConnection.Params.Values['Password'] :=
      Ini.ReadString('Database', 'Password', '');

  finally
    Ini.Free;
  end;
end;

class procedure TApiDatabase.Initialize;
begin
  if Assigned(FConnection) then
    Exit;

  CreateConnection;
end;

class procedure TApiDatabase.Finalize;
begin
  FreeAndNil(FConnection);
  FreeAndNil(FDriverLink);
end;

class function TApiDatabase.Connection: TFDConnection;
begin
  if not Assigned(FConnection) then
    Initialize;

  Result := FConnection;
end;

end.
