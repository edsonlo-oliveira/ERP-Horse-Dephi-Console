unit uJwtConfig;

interface

const
  JWT_ALGORITHM = 'HS256';
  JWT_ISSUER = 'ERPServer';
  JWT_EXPIRES_IN_SECONDS = 3600;

function GetAuthSecret: string;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  System.IOUtils;

function GetAuthSecret: string;
var
  LIni: TIniFile;
  LFileName: string;
begin
  LFileName :=
    TPath.Combine(
      ExtractFilePath(ParamStr(0)),
      'ERPServer.ini'
    );

  if not FileExists(LFileName) then
    raise Exception.Create(
      'Arquivo de configuração não encontrado.'
    );

  LIni := TIniFile.Create(LFileName);
  try
    Result :=
      Trim(
        LIni.ReadString(
          'AUTH',
          'Secret',
          ''
        )
      );

    if Result = '' then
      raise Exception.Create(
        'AUTH Secret não configurado.'
      );

  finally
    LIni.Free;
  end;
end;

end.
