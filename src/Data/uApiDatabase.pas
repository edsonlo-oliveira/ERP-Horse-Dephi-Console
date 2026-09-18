unit uApiDatabase;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Comp.Client,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef;

type
  TApiDatabase = class
  private
    const
      CONNECTION_DEF_NAME = 'ERP_API_POOL';

  private
    class var FDriverLink: TFDPhysPgDriverLink;

    class function ConfigFileName: string; static;
    class procedure CreateConnectionDefinition; static;

  public
    class procedure Initialize; static;
    class procedure Finalize; static;

    class function NewConnection: TFDConnection; static;
  end;

implementation

//***************************************
//* CONFIG FILE
//***************************************
class function TApiDatabase.ConfigFileName: string;
begin
  Result :=
    IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))
    ) +
    'ERPServer.ini';
end;


//***************************************
//* CREATE CONNECTION DEFINITION
//***************************************
class procedure TApiDatabase.CreateConnectionDefinition;
var
  Ini: TIniFile;
  Params: TStringList;
begin
  Ini := TIniFile.Create(ConfigFileName);
  Params := TStringList.Create;

  try

    //***************************************
    //* PostgreSQL Driver
    //***************************************
    FDriverLink := TFDPhysPgDriverLink.Create(nil);

    FDriverLink.VendorLib :=
      Ini.ReadString(
        'Database',
        'VendorLib',
        ''
      );


    //***************************************
    //* Connection parameters
    //***************************************
    Params.Values['Server'] :=
      Ini.ReadString(
        'Database',
        'Server',
        'localhost'
      );

    Params.Values['Port'] :=
      Ini.ReadString(
        'Database',
        'Port',
        '5432'
      );

    Params.Values['Database'] :=
      Ini.ReadString(
        'Database',
        'Database',
        ''
      );

    Params.Values['User_Name'] :=
      Ini.ReadString(
        'Database',
        'User_Name',
        ''
      );

    Params.Values['Password'] :=
      Ini.ReadString(
        'Database',
        'Password',
        ''
      );


    //***************************************
    //* Application identification
    //***************************************
    Params.Values['ApplicationName'] :=
      'ERPServer';


    //***************************************
    //* Connection Pool
    //***************************************
    Params.Values['Pooled'] :=
      'True';

    Params.Values['POOL_MaximumItems'] :=
      Ini.ReadString(
        'Database',
        'POOL_MaximumItems',
        '50'
      );

    Params.Values['POOL_ExpireTimeout'] :=
      Ini.ReadString(
        'Database',
        'POOL_ExpireTimeout',
        '90000'
      );

    Params.Values['POOL_CleanupTimeout'] :=
      Ini.ReadString(
        'Database',
        'POOL_CleanupTimeout',
        '30000'
      );


    //***************************************
    //* Creates a PRIVATE connection
    //* definition.
    //***************************************
    FDManager.AddConnectionDef(
      CONNECTION_DEF_NAME,
      'PG',
      Params,
      False
    );

  finally
    Params.Free;
    Ini.Free;
  end;
end;


//***************************************
//* INITIALIZE
//***************************************
class procedure TApiDatabase.Initialize;
begin

  if FDManager.Active then
    Exit;

  CreateConnectionDefinition;

  FDManager.Active := True;

end;


//***************************************
//* FINALIZE
//***************************************
class procedure TApiDatabase.Finalize;
begin

  if FDManager.Active then
  begin

    FDManager.CloseConnectionDef(
      CONNECTION_DEF_NAME
    );

    FDManager.Active := False;

  end;

  FreeAndNil(FDriverLink);

end;


//***************************************
//* NEW CONNECTION
//***************************************
class function TApiDatabase.NewConnection: TFDConnection;
begin

  if not FDManager.Active then
    Initialize;

  Result := TFDConnection.Create(nil);

  try

    Result.LoginPrompt := False;

    Result.ConnectionDefName :=
      CONNECTION_DEF_NAME;

    Result.Connected := True;

  except

    Result.Free;
    raise;

  end;

end;

end.
