unit uUserController;

interface

uses
  Horse;

type
  TUserController = class
  public
    class procedure List(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );

    class procedure GetByUuid(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );

    class procedure Create(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );

    class procedure Update(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );

    class procedure Delete(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uUserService,
  uJwtService,
  uJwtRequestContext;


//***************************************
//* LIST
//***************************************
class procedure TUserController.List(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LJson: string;
  LJwtContext: TJwtContext;
begin
  try
    if not TryGetJwtContext(
      Req,
      LJwtContext
    ) then
    begin
      Res.Status(401).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'Contexto de autenticação não encontrado.'
          )
          .ToJSON
      );

      Exit;
    end;

    LJson :=
      TUserService.List(
        LJwtContext.TenantID,
        LJwtContext.SuperUser
      );

    Res.Status(200).Send(
      LJson
    );

  except
    on E: Exception do
    begin
      Res.Status(500).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            E.Message
          )
          .ToJSON
      );
    end;
  end;
end;


//***************************************
//* GETBYUUID
//***************************************
class procedure TUserController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LUuid: string;
  LJson: string;
  LJwtContext: TJwtContext;
begin
  try
    LUuid :=
      Trim(
        Req.Params['uuid']
      );

    if LUuid = '' then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'UUID do usuário é obrigatório.'
          )
          .ToJSON
      );

      Exit;
    end;

    if not TryGetJwtContext(
      Req,
      LJwtContext
    ) then
    begin
      Res.Status(401).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'Contexto de autenticação não encontrado.'
          )
          .ToJSON
      );

      Exit;
    end;

    LJson :=
      TUserService.GetByUuid(
        LUuid,
        LJwtContext.TenantID,
        LJwtContext.SuperUser
      );

    if LJson = '' then
    begin
      Res.Status(404).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'Usuário não encontrado.'
          )
          .ToJSON
      );

      Exit;
    end;

    Res.Status(200).Send(
      LJson
    );

  except
    on E: Exception do
    begin
      Res.Status(500).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            E.Message
          )
          .ToJSON
      );
    end;
  end;
end;


//***************************************
//* CREATE
//***************************************
class procedure TUserController.Create(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LJson: TJSONValue;
  LObject: TJSONObject;

  LTargetTenantId: Int64;
  LLoginId: string;
  LFirstName: string;
  LMiddleName: string;
  LLastName: string;
  LEmail: string;
  LPassword: string;
  LStatus: string;
  LSuperUser: Boolean;

  LJwtContext: TJwtContext;

  LResult: string;
begin
  LJson := nil;

  try
    try
      LJson :=
        TJSONObject.ParseJSONValue(
          Req.Body
        );

      if not Assigned(LJson) then
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
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
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'O corpo da requisição deve ser um objeto JSON.'
            )
            .ToJSON
        );

        Exit;
      end;

      if not TryGetJwtContext(
        Req,
        LJwtContext
      ) then
      begin
        Res.Status(401).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'Contexto de autenticação não encontrado.'
            )
            .ToJSON
        );

        Exit;
      end;

      LObject :=
        TJSONObject(LJson);

      LTargetTenantId :=
        LObject.GetValue<Int64>(
          'tenant_id'
        );

      LLoginId :=
        LObject.GetValue<string>(
          'login_id'
        );

      LFirstName :=
        LObject.GetValue<string>(
          'first_name'
        );

      LMiddleName :=
        LObject.GetValue<string>(
          'middle_name'
        );

      LLastName :=
        LObject.GetValue<string>(
          'last_name'
        );

      LEmail :=
        LObject.GetValue<string>(
          'email'
        );

      LPassword :=
        LObject.GetValue<string>(
          'password'
        );

      LStatus :=
        LObject.GetValue<string>(
          'status'
        );

      LSuperUser :=
        LObject.GetValue<Boolean>(
          'super_user'
        );

      LResult :=
        TUserService.Create(
          LJwtContext.TenantID,
          LTargetTenantId,
          LLoginId,
          LFirstName,
          LMiddleName,
          LLastName,
          LEmail,
          LPassword,
          LStatus,
          LSuperUser,
          LJwtContext.SuperUser
        );

      if LResult = '' then
      begin
        Res.Status(500).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'Não foi possível criar o usuário.'
            )
            .ToJSON
        );

        Exit;
      end;

      Res.Status(201).Send(
        LResult
      );

    except
      on E: EConvertError do
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              E.Message
            )
            .ToJSON
        );
      end;

      on E: Exception do
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              E.Message
            )
            .ToJSON
        );
      end;
    end;

  finally
    LJson.Free;
  end;
end;


//***************************************
//* UPDATE
//***************************************
class procedure TUserController.Update(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LUuid: string;

  LJson: TJSONValue;
  LObject: TJSONObject;

  LLoginId: string;
  LFirstName: string;
  LMiddleName: string;
  LLastName: string;
  LEmail: string;
  LPassword: string;
  LStatus: string;
  LSuperUser: Boolean;

  LJwtContext: TJwtContext;

  LResult: string;
begin
  LJson := nil;

  try
    try
      LUuid :=
        Trim(
          Req.Params['uuid']
        );

      if LUuid = '' then
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'UUID do usuário é obrigatório.'
            )
            .ToJSON
        );

        Exit;
      end;

      LJson :=
        TJSONObject.ParseJSONValue(
          Req.Body
        );

      if not Assigned(LJson) then
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
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
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'O corpo da requisição deve ser um objeto JSON.'
            )
            .ToJSON
        );

        Exit;
      end;

      if not TryGetJwtContext(
        Req,
        LJwtContext
      ) then
      begin
        Res.Status(401).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'Contexto de autenticação não encontrado.'
            )
            .ToJSON
        );

        Exit;
      end;

      LObject :=
        TJSONObject(LJson);

      LLoginId :=
        LObject.GetValue<string>(
          'login_id'
        );

      LFirstName :=
        LObject.GetValue<string>(
          'first_name'
        );

      LMiddleName :=
        LObject.GetValue<string>(
          'middle_name'
        );

      LLastName :=
        LObject.GetValue<string>(
          'last_name'
        );

      LEmail :=
        LObject.GetValue<string>(
          'email'
        );

      LPassword := '';

      if LObject.GetValue('password') <> nil then
      begin
        LPassword :=
          LObject.GetValue<string>(
            'password'
          );
      end;

      LStatus :=
        LObject.GetValue<string>(
          'status'
        );

      LSuperUser :=
        LObject.GetValue<Boolean>(
          'super_user'
        );

      LResult :=
        TUserService.Update(
          LJwtContext.TenantID,
          LUuid,
          LLoginId,
          LFirstName,
          LMiddleName,
          LLastName,
          LEmail,
          LPassword,
          LStatus,
          LSuperUser,
          LJwtContext.SuperUser
        );

      if LResult = '' then
      begin
        Res.Status(404).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              'Usuário não encontrado.'
            )
            .ToJSON
        );

        Exit;
      end;

      Res.Status(200).Send(
        LResult
      );

    except
      on E: EConvertError do
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              E.Message
            )
            .ToJSON
        );
      end;

      on E: Exception do
      begin
        Res.Status(400).Send(
          TJSONObject.Create
            .AddPair(
              'success',
              TJSONBool.Create(False)
            )
            .AddPair(
              'message',
              E.Message
            )
            .ToJSON
        );
      end;
    end;

  finally
    LJson.Free;
  end;
end;


//***************************************
//* DELETE
//***************************************
class procedure TUserController.Delete(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LUuid: string;
  LDeleted: Boolean;

  LJwtContext: TJwtContext;
begin
  try
    LUuid :=
      Trim(
        Req.Params['uuid']
      );

    if LUuid = '' then
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'UUID do usuário é obrigatório.'
          )
          .ToJSON
      );

      Exit;
    end;

    if not TryGetJwtContext(
      Req,
      LJwtContext
    ) then
    begin
      Res.Status(401).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'Contexto de autenticação não encontrado.'
          )
          .ToJSON
      );

      Exit;
    end;

    LDeleted :=
      TUserService.Delete(
        LJwtContext.TenantID,
        LUuid,
        LJwtContext.SuperUser
      );

    if not LDeleted then
    begin
      Res.Status(404).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            'Usuário não encontrado.'
          )
          .ToJSON
      );

      Exit;
    end;

    Res.Status(200).Send(
      TJSONObject.Create
        .AddPair(
          'success',
          TJSONBool.Create(True)
        )
        .AddPair(
          'message',
          'Usuário excluído com sucesso.'
        )
        .ToJSON
    );

  except
    on E: Exception do
    begin
      Res.Status(400).Send(
        TJSONObject.Create
          .AddPair(
            'success',
            TJSONBool.Create(False)
          )
          .AddPair(
            'message',
            E.Message
          )
          .ToJSON
      );
    end;
  end;
end;

end.
