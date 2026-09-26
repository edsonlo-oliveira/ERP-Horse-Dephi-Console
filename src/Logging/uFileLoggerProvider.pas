unit uFileLoggerProvider;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Generics.Collections,
  Horse.Logger.Provider.Contract,
  Horse.Logger.Types;

type
  TFileLoggerProvider = class(
    TInterfacedObject,
    IHorseLoggerProvider
  )
  private
    class function IsSensitiveField(
      const AFieldName: string
    ): Boolean; static;

    class function SanitizeJsonValue(
      const AValue: TJSONValue;
      const AFieldName: string = ''
    ): TJSONValue; static;

    class function GetLogDirectory: string; static;
    class function GetLogFileName: string; static;

    class procedure WriteLog(
      const AText: string
    ); static;

  public
    procedure DoReceiveLogCache(
      ALogCache: THorseLoggerCache
    );
  end;

implementation

//***********************************************
//* IS SENSITIVE FIELD
//***********************************************
class function TFileLoggerProvider.IsSensitiveField(
  const AFieldName: string
): Boolean;
var
  LFieldName: string;
begin
  LFieldName :=
    LowerCase(
      Trim(AFieldName)
    );

  Result :=
    (LFieldName = 'password') or
    (LFieldName = 'senha') or
    (LFieldName = 'token') or
    (LFieldName = 'access_token') or
    (LFieldName = 'refresh_token') or
    (LFieldName = 'authorization') or
    (LFieldName = 'request_authorization') or
    (LFieldName = 'secret');
end;

//***********************************************
//* SANITIZE JSON VALUE
//***********************************************
class function TFileLoggerProvider.SanitizeJsonValue(
  const AValue: TJSONValue;
  const AFieldName: string
): TJSONValue;
var
  LObject: TJSONObject;
  LArray: TJSONArray;
  LPair: TJSONPair;
  I: Integer;
begin
  //***************************************
  //* SENSITIVE FIELD
  //***************************************
  if IsSensitiveField(
    AFieldName
  ) then
  begin
    Result :=
      TJSONString.Create(
        '[REDACTED]'
      );

    Exit;
  end;

  //***************************************
  //* NULL
  //***************************************
  if not Assigned(AValue) then
  begin
    Result :=
      TJSONNull.Create;

    Exit;
  end;

  //***************************************
  //* OBJECT
  //***************************************
  if AValue is TJSONObject then
  begin
    LObject :=
      TJSONObject.Create;

    for LPair in TJSONObject(AValue) do
    begin
      LObject.AddPair(
        LPair.JsonString.Value,
        SanitizeJsonValue(
          LPair.JsonValue,
          LPair.JsonString.Value
        )
      );
    end;

    Result :=
      LObject;

    Exit;
  end;

  //***************************************
  //* ARRAY
  //***************************************
  if AValue is TJSONArray then
  begin
    LArray :=
      TJSONArray.Create;

    for I := 0 to
      TJSONArray(AValue).Count - 1 do
    begin
      LArray.AddElement(
        SanitizeJsonValue(
          TJSONArray(AValue).Items[I]
        )
      );
    end;

    Result :=
      LArray;

    Exit;
  end;

  //***************************************
  //* BOOLEAN
  //***************************************
  if AValue is TJSONBool then
  begin
    Result :=
      TJSONBool.Create(
        TJSONBool(AValue).AsBoolean
      );

    Exit;
  end;

  //***************************************
  //* NUMBER
  //***************************************
  if AValue is TJSONNumber then
  begin
    Result :=
      TJSONNumber.Create(
        TJSONNumber(AValue).Value
      );

    Exit;
  end;

  //***************************************
  //* STRING / OTHER
  //***************************************
  Result :=
    TJSONString.Create(
      AValue.Value
    );
end;

//***********************************************
//* GET LOG DIRECTORY
//***********************************************
class function TFileLoggerProvider.GetLogDirectory: string;
begin
  Result :=
    TPath.Combine(
      ExtractFilePath(
        ParamStr(0)
      ),
      'logs'
    );

  if not TDirectory.Exists(
    Result
  ) then
  begin
    TDirectory.CreateDirectory(
      Result
    );
  end;
end;

//***********************************************
//* GET LOG FILE NAME
//***********************************************
class function TFileLoggerProvider.GetLogFileName: string;
begin
  Result :=
    TPath.Combine(
      GetLogDirectory,
      'ERPServer-' +
      FormatDateTime(
        'yyyy-mm-dd',
        Date
      ) +
      '.log'
    );
end;

//***********************************************
//* WRITE LOG
//***********************************************
class procedure TFileLoggerProvider.WriteLog(
  const AText: string
);
var
  LFileName: string;
begin
  LFileName :=
    GetLogFileName;

  TFile.AppendAllText(
    LFileName,
    AText +
    sLineBreak,
    TEncoding.UTF8
  );
end;

//***********************************************
//* RECEIVE LOG CACHE
//***********************************************
procedure TFileLoggerProvider.DoReceiveLogCache(
  ALogCache: THorseLoggerCache
);
var
  I: Integer;
  LSanitizedLog: TJSONValue;
begin
  if not Assigned(
    ALogCache
  ) then
    Exit;

  for I := 0 to
    ALogCache.Count - 1 do
  begin
    LSanitizedLog :=
      SanitizeJsonValue(
        ALogCache.Items[I]
      );

    try
      WriteLog(
        LSanitizedLog.ToJSON
      );
    finally
      LSanitizedLog.Free;
    end;
  end;
end;

end.
