unit uAuthController;

interface

uses
  Horse;

type
  TAuthController = class
  public
    class procedure Login(
      Req: THorseRequest;
      Res: THorseResponse
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uAuthService;

class procedure TAuthController.Login(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJson: TJSONValue;
  LObject: TJSONObject;
  LLoginId: string;
  LPassword: string;
  LResult: string;
begin
  LJson := nil;

  try
    if Trim(Req.Body) = '' then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'O corpo da requisição é obrigatório.'
          )
          .ToJSON
      );
      Exit;
    end;

    LJson := TJSONObject.ParseJSONValue(
      Req.Body
    );

    if not Assigned(LJson) then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'JSON inválido.'
          )
          .ToJSON
      );
      Exit;
    end;

    if not (LJson is TJSONObject) then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'O corpo da requisição deve ser um objeto JSON.'
          )
          .ToJSON
      );
      Exit;
    end;

    LObject := TJSONObject(LJson);

    if LObject.GetValue('login_id') = nil then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'Login é obrigatório.'
          )
          .ToJSON
      );
      Exit;
    end;

    if LObject.GetValue('password') = nil then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'Senha é obrigatória.'
          )
          .ToJSON
      );
      Exit;
    end;

    LLoginId :=
      Trim(
        LObject.GetValue<string>('login_id')
      );

    LPassword :=
      LObject.GetValue<string>('password');

    if LLoginId = '' then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'Login é obrigatório.'
          )
          .ToJSON
      );
      Exit;
    end;

    if LPassword = '' then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            'Senha é obrigatória.'
          )
          .ToJSON
      );
      Exit;
    end;

    LResult :=
      TAuthService.Login(
        LLoginId,
        LPassword
      );

    Res.Status(200).Send(
      TJSONObject.Create
        .AddPair('success', TJSONBool.Create(True))
        .AddPair(
          'message',
          'Login realizado com sucesso.'
        )
        .AddPair(
          'user',
          TJSONObject.ParseJSONValue(LResult)
        )
        .ToJSON
    );

  except
    on E: Exception do
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair(
            'message',
            E.Message
          )
          .ToJSON
      );
    end;
  end;

  LJson.Free;
end;

end.
