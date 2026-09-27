unit uHttpResponseUtils;

interface

uses
  System.SysUtils,
  Horse;

type
  THttpResponseUtils = class
  public
    class procedure SendError(
      const Res: THorseResponse;
      const AStatusCode: Integer;
      const AMessage: string
    ); static;

    class procedure SendSuccess(
      const Res: THorseResponse;
      const AStatusCode: Integer;
      const AMessage: string
    ); static;

    class procedure HandleDatabaseError(
      const Res: THorseResponse;
      const E: Exception
    ); static;
  end;

implementation

uses
  System.JSON,
  uDatabaseErrorHandler,
  uServerLogger;


//***********************************************
//* SEND ERROR
//***********************************************
class procedure THttpResponseUtils.SendError(
  const Res: THorseResponse;
  const AStatusCode: Integer;
  const AMessage: string
);
var
  LJson: TJSONObject;
begin
  LJson :=
    TJSONObject.Create;

  try
    LJson.AddPair(
      'success',
      TJSONBool.Create(False)
    );

    LJson.AddPair(
      'message',
      AMessage
    );

    Res.ContentType(
      'application/json; charset=utf-8'
    );

    Res.Status(
      AStatusCode
    );

    Res.Send(
      LJson.ToJSON
    );

  finally
    LJson.Free;
  end;
end;


//***********************************************
//* SEND SUCCESS
//***********************************************
class procedure THttpResponseUtils.SendSuccess(
  const Res: THorseResponse;
  const AStatusCode: Integer;
  const AMessage: string
);
var
  LJson: TJSONObject;
begin
  LJson :=
    TJSONObject.Create;

  try
    LJson.AddPair(
      'success',
      TJSONBool.Create(True)
    );

    LJson.AddPair(
      'message',
      AMessage
    );

    Res.ContentType(
      'application/json; charset=utf-8'
    );

    Res.Status(
      AStatusCode
    );

    Res.Send(
      LJson.ToJSON
    );

  finally
    LJson.Free;
  end;
end;


//***********************************************
//* HANDLE DATABASE ERROR
//***********************************************
class procedure THttpResponseUtils.HandleDatabaseError(
  const Res: THorseResponse;
  const E: Exception
);
var
  LErrorInfo: TDatabaseErrorInfo;
begin
  //***************************************
  //* HANDLE ERROR
  //***************************************
  LErrorInfo :=
    TDatabaseErrorHandler.Handle(
      E
    );

  //***************************************
  //* SERVER LOG
  //***************************************
  TServerLogger.Error(
    LErrorInfo.Details
  );

  //***************************************
  //* HTTP RESPONSE
  //***************************************
  SendError(
    Res,
    LErrorInfo.HttpStatus,
    LErrorInfo.UserMessage
  );
end;

end.
