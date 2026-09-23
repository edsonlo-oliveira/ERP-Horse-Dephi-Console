unit uServerLogger;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes;

type
  TServerLogger = class
  private
    class function GetLogDirectory: string; static;
    class function GetLogFileName: string; static;
    class procedure Write(
      const ALevel: string;
      const AMessage: string
    ); static;

  public
    class procedure Error(
      const AMessage: string
    ); static;

    class procedure Info(
      const AMessage: string
    ); static;
  end;

implementation

//***********************************************
//* GETLOGDIRECTORY
//***********************************************
class function TServerLogger.GetLogDirectory: string;
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
//* GETLOGFILENAME
//***********************************************
class function TServerLogger.GetLogFileName: string;
begin
  Result :=
    TPath.Combine(
      GetLogDirectory,
      'ERPServer-Application-' +
      FormatDateTime(
        'yyyy-mm-dd',
        Date
      ) +
      '.log'
    );
end;

//***********************************************
//* WRITE
//***********************************************
class procedure TServerLogger.Write(
  const ALevel: string;
  const AMessage: string
);
var
  LText: string;
begin
  LText :=
    FormatDateTime(
      'yyyy-mm-dd hh:nn:ss.zzz',
      Now
    ) +
    ' [' +
    ALevel +
    '] ' +
    AMessage;

  TFile.AppendAllText(
    GetLogFileName,
    LText +
    sLineBreak,
    TEncoding.UTF8
  );
end;

//***********************************************
//* ERROR
//***********************************************
class procedure TServerLogger.Error(
  const AMessage: string
);
begin
  Write(
    'ERROR',
    AMessage
  );
end;

//***********************************************
//* INFO
//***********************************************
class procedure TServerLogger.Info(
  const AMessage: string
);
begin
  Write(
    'INFO',
    AMessage
  );
end;

end.
