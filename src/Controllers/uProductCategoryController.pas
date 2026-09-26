unit uProductCategoryController;

interface

uses
  Horse;

type
  TProductCategoryController = class
  private
    class function GetRequestedTenantID(
      const Req: THorseRequest
    ): Int64; static;

    class function GetCategoryUuid(
      const Req: THorseRequest;
      out ACategoryUuid: string
    ): Boolean; static;

    class procedure SendError(
      const Res: THorseResponse;
      const AStatusCode: Integer;
      const AMessage: string
    ); static;

  public
    class procedure List(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure GetByUuid(
      Req: THorseRequest;
      Res: THorseResponse
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
      Res: THorseResponse
    );

    class procedure HardDelete(
      Req: THorseRequest;
      Res: THorseResponse
    );

    class procedure SetActive(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    );
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  uProductCategoryService,
  uJwtService,
  uJwtRequestContext;


//******************************************
//* GET REQUESTED TENANT ID
//******************************************
class function TProductCategoryController.GetRequestedTenantID(
  const Req: THorseRequest
): Int64;
var
  LTenantValue: string;
begin
  Result := 0;

  LTenantValue :=
    Trim(
      Req.Query['tenant_id']
    );

  if LTenantValue = '' then
    Exit;

  TryStrToInt64(
    LTenantValue,
    Result
  );
end;


//******************************************
//* GET CATEGORY UUID
//******************************************
class function TProductCategoryController.GetCategoryUuid(
  const Req: THorseRequest;
  out ACategoryUuid: string
): Boolean;
begin
  ACategoryUuid :=
    Trim(
      Req.Params['uuid']
    );

  Result :=
    ACategoryUuid <> '';
end;


//******************************************
//* SEND ERROR
//******************************************
class procedure TProductCategoryController.SendError(
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
      TJSONFalse.Create
    );

    LJson.AddPair(
      'message',
      AMessage
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


//******************************************
//* LIST
//******************************************
class procedure TProductCategoryController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LRequestedTenantID: Int64;
  LErrorMessage: string;
  LResult: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  try
    //***************************************
    //* REQUESTED TENANT
    //***************************************
    LRequestedTenantID :=
      GetRequestedTenantID(
        Req
      );

    //***************************************
    //* SERVICE
    //***************************************
    LResult :=
      TProductCategoryService.List(
        LJwtContext.TenantID,
        LRequestedTenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LErrorMessage
      );

    //***************************************
    //* BUSINESS ERROR
    //***************************************
    if LErrorMessage <> '' then
    begin
      SendError(
        Res,
        400,
        LErrorMessage
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(
      200
    );

    Res.Send(
      LResult
    );

  except
    on E: Exception do
    begin
      SendError(
        Res,
        500,
        'Erro interno ao listar categorias: ' +
        E.Message
      );
    end;
  end;
end;


//******************************************
//* GET BY UUID
//******************************************
class procedure TProductCategoryController.GetByUuid(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LRequestedTenantID: Int64;
  LCategoryUuid: string;
  LErrorMessage: string;
  LResult: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if not GetCategoryUuid(
    Req,
    LCategoryUuid
  ) then
  begin
    SendError(
      Res,
      400,
      'UUID da categoria não informado.'
    );

    Exit;
  end;

  try
    //***************************************
    //* REQUESTED TENANT
    //***************************************
    LRequestedTenantID :=
      GetRequestedTenantID(
        Req
      );

    //***************************************
    //* SERVICE
    //***************************************
    LResult :=
      TProductCategoryService.GetByUuid(
        LJwtContext.TenantID,
        LRequestedTenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LCategoryUuid,
        LErrorMessage
      );

    //***************************************
    //* ERROR
    //***************************************
    if LErrorMessage <> '' then
    begin
      if SameText(
        LErrorMessage,
        'Categoria não encontrada.'
      ) then
      begin
        SendError(
          Res,
          404,
          LErrorMessage
        );
      end
      else
      begin
        SendError(
          Res,
          400,
          LErrorMessage
        );
      end;

      Exit;
    end;

    //***************************************
    //* NOT FOUND
    //***************************************
    if LResult = '' then
    begin
      SendError(
        Res,
        404,
        'Categoria não encontrada.'
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(
      200
    );

    Res.Send(
      LResult
    );

  except
    on E: Exception do
    begin
      SendError(
        Res,
        500,
        'Erro interno ao consultar categoria: ' +
        E.Message
      );
    end;
  end;
end;


//******************************************
//* CREATE
//******************************************
class procedure TProductCategoryController.Create(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LRequestedTenantID: Int64;
  LCategoryName: string;
  LParentCategoryUuid: string;
  LActive: Boolean;

  LErrorMessage: string;
  LResult: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  LJsonBody :=
    nil;

  LRequestedTenantID := 0;
  LCategoryName := '';
  LParentCategoryUuid := '';
  LActive := True;

  try
    try
      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* TENANT ID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'tenant_id'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not TryStrToInt64(
          LJsonValue.Value,
          LRequestedTenantID
        ) then
        begin
          SendError(
            Res,
            400,
            'O campo tenant_id deve ser numérico.'
          );

          Exit;
        end;
      end;

      //***************************************
      //* CATEGORY NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'category_name'
        );

      if not Assigned(LJsonValue) or
         (LJsonValue is TJSONNull) then
      begin
        SendError(
          Res,
          400,
          'O campo category_name é obrigatório.'
        );

        Exit;
      end;

      if not (LJsonValue is TJSONString) then
      begin
        SendError(
          Res,
          400,
          'O campo category_name deve ser texto.'
        );

        Exit;
      end;

      LCategoryName :=
        Trim(
          LJsonValue.Value
        );

      //***************************************
      //* PARENT CATEGORY UUID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'parent_category_uuid'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not (LJsonValue is TJSONString) then
        begin
          SendError(
            Res,
            400,
            'O campo parent_category_uuid deve ser texto ou null.'
          );

          Exit;
        end;

        LParentCategoryUuid :=
          Trim(
            LJsonValue.Value
          );
      end;

      //***************************************
      //* ACTIVE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'active'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not (LJsonValue is TJSONBool) then
        begin
          SendError(
            Res,
            400,
            'O campo active deve ser booleano.'
          );

          Exit;
        end;

        LActive :=
          TJSONBool(
            LJsonValue
          ).AsBoolean;
      end;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TProductCategoryService.Create(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LRequestedTenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LCategoryName,
          LParentCategoryUuid,
          LActive,
          LErrorMessage
        );

      //***************************************
      //* BUSINESS ERROR
      //***************************************
      if LErrorMessage <> '' then
      begin
        SendError(
          Res,
          400,
          LErrorMessage
        );

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      Res.Status(
        201
      );

      Res.Send(
        LResult
      );

    except
      on E: Exception do
      begin
        SendError(
          Res,
          500,
          'Erro interno ao criar categoria: ' +
          E.Message
        );
      end;
    end;

  finally
    LJsonBody.Free;
  end;
end;


//******************************************
//* UPDATE
//******************************************
class procedure TProductCategoryController.Update(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LCategoryUuid: string;
  LRequestedTenantID: Int64;

  LCategoryName: string;
  LParentCategoryUuid: string;
  LActive: Boolean;

  LErrorMessage: string;
  LResult: string;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if not GetCategoryUuid(
    Req,
    LCategoryUuid
  ) then
  begin
    SendError(
      Res,
      400,
      'UUID da categoria não informado.'
    );

    Exit;
  end;

  LJsonBody :=
    nil;

  LRequestedTenantID := 0;
  LCategoryName := '';
  LParentCategoryUuid := '';
//  LActive := True;

  try
    try
      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* TENANT ID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'tenant_id'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not TryStrToInt64(
          LJsonValue.Value,
          LRequestedTenantID
        ) then
        begin
          SendError(
            Res,
            400,
            'O campo tenant_id deve ser numérico.'
          );

          Exit;
        end;
      end;

      //***************************************
      //* CATEGORY NAME
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'category_name'
        );

      if not Assigned(LJsonValue) or
         (LJsonValue is TJSONNull) then
      begin
        SendError(
          Res,
          400,
          'O campo category_name é obrigatório.'
        );

        Exit;
      end;

      if not (LJsonValue is TJSONString) then
      begin
        SendError(
          Res,
          400,
          'O campo category_name deve ser texto.'
        );

        Exit;
      end;

      LCategoryName :=
        Trim(
          LJsonValue.Value
        );

      //***************************************
      //* PARENT CATEGORY UUID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'parent_category_uuid'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not (LJsonValue is TJSONString) then
        begin
          SendError(
            Res,
            400,
            'O campo parent_category_uuid deve ser texto ou null.'
          );

          Exit;
        end;

        LParentCategoryUuid :=
          Trim(
            LJsonValue.Value
          );
      end;

      //***************************************
      //* ACTIVE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'active'
        );

      if not Assigned(LJsonValue) or
         (LJsonValue is TJSONNull) then
      begin
        SendError(
          Res,
          400,
          'O campo active é obrigatório.'
        );

        Exit;
      end;

      if not (LJsonValue is TJSONBool) then
      begin
        SendError(
          Res,
          400,
          'O campo active deve ser booleano.'
        );

        Exit;
      end;

      LActive :=
        TJSONBool(
          LJsonValue
        ).AsBoolean;

      //***************************************
      //* SERVICE
      //***************************************
      LResult :=
        TProductCategoryService.Update(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LRequestedTenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LCategoryUuid,
          LCategoryName,
          LParentCategoryUuid,
          LActive,
          LErrorMessage
        );

      //***************************************
      //* ERROR
      //***************************************
      if LErrorMessage <> '' then
      begin
        if SameText(
          LErrorMessage,
          'Categoria não encontrada.'
        ) then
        begin
          SendError(
            Res,
            404,
            LErrorMessage
          );
        end
        else
        begin
          SendError(
            Res,
            400,
            LErrorMessage
          );
        end;

        Exit;
      end;

      //***************************************
      //* NOT FOUND
      //***************************************
      if LResult = '' then
      begin
        SendError(
          Res,
          404,
          'Categoria não encontrada.'
        );

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      Res.Status(
        200
      );

      Res.Send(
        LResult
      );

    except
      on E: Exception do
      begin
        SendError(
          Res,
          500,
          'Erro interno ao atualizar categoria: ' +
          E.Message
        );
      end;
    end;

  finally
    LJsonBody.Free;
  end;
end;


//******************************************
//* DELETE
//******************************************
class procedure TProductCategoryController.Delete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LCategoryUuid: string;
  LRequestedTenantID: Int64;
  LErrorMessage: string;
  LDeleted: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if not GetCategoryUuid(
    Req,
    LCategoryUuid
  ) then
  begin
    SendError(
      Res,
      400,
      'UUID da categoria não informado.'
    );

    Exit;
  end;

  try
    //***************************************
    //* TENANT
    //***************************************
    LRequestedTenantID :=
      GetRequestedTenantID(
        Req
      );

    //***************************************
    //* SERVICE
    //***************************************
    LDeleted :=
      TProductCategoryService.Delete(
        LJwtContext.UserID,
        LJwtContext.TenantID,
        LRequestedTenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LCategoryUuid,
        LErrorMessage
      );

    //***************************************
    //* ERROR
    //***************************************
    if LErrorMessage <> '' then
    begin
      if SameText(
        LErrorMessage,
        'Categoria não encontrada.'
      ) then
      begin
        SendError(
          Res,
          404,
          LErrorMessage
        );
      end
      else if SameText(
        LErrorMessage,
        'A categoria não pode ser excluída porque possui subcategorias.'
      ) then
      begin
        SendError(
          Res,
          409,
          LErrorMessage
        );
      end
      else
      begin
        SendError(
          Res,
          400,
          LErrorMessage
        );
      end;

      Exit;
    end;

    //***************************************
    //* NOT DELETED
    //***************************************
    if not LDeleted then
    begin
      SendError(
        Res,
        404,
        'Categoria não encontrada.'
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(
      204
    );

    Res.Send(
      ''
    );

  except
    on E: Exception do
    begin
      SendError(
        Res,
        500,
        'Erro interno ao excluir categoria: ' +
        E.Message
      );
    end;
  end;
end;


//******************************************
//* SET ACTIVE
//******************************************
class procedure TProductCategoryController.SetActive(
  Req: THorseRequest;
  Res: THorseResponse;
  Next: TProc
);
var
  LJwtContext: TJwtContext;
  LJsonBody: TJSONObject;
  LJsonValue: TJSONValue;

  LCategoryUuid: string;
  LRequestedTenantID: Int64;
  LActive: Boolean;

  LErrorMessage: string;
  LUpdated: Boolean;

  LResponseJson: TJSONObject;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if not GetCategoryUuid(
    Req,
    LCategoryUuid
  ) then
  begin
    SendError(
      Res,
      400,
      'UUID da categoria não informado.'
    );

    Exit;
  end;

  LJsonBody :=
    nil;

  LRequestedTenantID := 0;
//  LActive := False;

  try
    try
      //***************************************
      //* BODY
      //***************************************
      LJsonBody :=
        TJSONObject.ParseJSONValue(
          Req.Body
        ) as TJSONObject;

      if not Assigned(LJsonBody) then
      begin
        SendError(
          Res,
          400,
          'JSON inválido.'
        );

        Exit;
      end;

      //***************************************
      //* TENANT ID
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'tenant_id'
        );

      if Assigned(LJsonValue) and
         not (LJsonValue is TJSONNull) then
      begin
        if not TryStrToInt64(
          LJsonValue.Value,
          LRequestedTenantID
        ) then
        begin
          SendError(
            Res,
            400,
            'O campo tenant_id deve ser numérico.'
          );

          Exit;
        end;
      end;

      //***************************************
      //* ACTIVE
      //***************************************
      LJsonValue :=
        LJsonBody.GetValue(
          'active'
        );

      if not Assigned(LJsonValue) or
         (LJsonValue is TJSONNull) then
      begin
        SendError(
          Res,
          400,
          'O campo active é obrigatório.'
        );

        Exit;
      end;

      if not (LJsonValue is TJSONBool) then
      begin
        SendError(
          Res,
          400,
          'O campo active deve ser booleano.'
        );

        Exit;
      end;

      LActive :=
        TJSONBool(
          LJsonValue
        ).AsBoolean;

      //***************************************
      //* SERVICE
      //***************************************
      LUpdated :=
        TProductCategoryService.SetActive(
          LJwtContext.UserID,
          LJwtContext.TenantID,
          LRequestedTenantID,
          LJwtContext.SuperUser,
          LJwtContext.Scope,
          LCategoryUuid,
          LActive,
          LErrorMessage
        );

      //***************************************
      //* ERROR
      //***************************************
      if LErrorMessage <> '' then
      begin
        if SameText(
          LErrorMessage,
          'Categoria não encontrada.'
        ) then
        begin
          SendError(
            Res,
            404,
            LErrorMessage
          );
        end
        else
        begin
          SendError(
            Res,
            400,
            LErrorMessage
          );
        end;

        Exit;
      end;

      //***************************************
      //* NOT UPDATED
      //***************************************
      if not LUpdated then
      begin
        SendError(
          Res,
          404,
          'Categoria não encontrada.'
        );

        Exit;
      end;

      //***************************************
      //* SUCCESS
      //***************************************
      LResponseJson :=
        TJSONObject.Create;

      try
        LResponseJson.AddPair(
          'success',
          TJSONTrue.Create
        );

        LResponseJson.AddPair(
          'active',
          TJSONBool.Create(
            LActive
          )
        );

        Res.Status(
          200
        );

        Res.Send(
          LResponseJson.ToJSON
        );

      finally
        LResponseJson.Free;
      end;

    except
      on E: Exception do
      begin
        SendError(
          Res,
          500,
          'Erro interno ao alterar status da categoria: ' +
          E.Message
        );
      end;
    end;

  finally
    LJsonBody.Free;
  end;
end;

//******************************************
//* HARD DELETE
//******************************************
class procedure TProductCategoryController.HardDelete(
  Req: THorseRequest;
  Res: THorseResponse
);
var
  LJwtContext: TJwtContext;
  LCategoryUuid: string;
  LRequestedTenantID: Int64;
  LErrorMessage: string;
  LDeleted: Boolean;
begin
  Res.ContentType(
    'application/json; charset=utf-8'
  );

  //***************************************
  //* JWT CONTEXT
  //***************************************
  if not TryGetJwtContext(
    Req,
    LJwtContext
  ) then
  begin
    SendError(
      Res,
      401,
      'Contexto de autenticação não encontrado.'
    );

    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if not GetCategoryUuid(
    Req,
    LCategoryUuid
  ) then
  begin
    SendError(
      Res,
      400,
      'UUID da categoria não informado.'
    );

    Exit;
  end;

  try
    //***************************************
    //* TENANT
    //***************************************
    LRequestedTenantID :=
      GetRequestedTenantID(
        Req
      );

    //***************************************
    //* SERVICE
    //***************************************
    LDeleted :=
      TProductCategoryService.HardDelete(
        LJwtContext.UserID,
        LJwtContext.TenantID,
        LRequestedTenantID,
        LJwtContext.SuperUser,
        LJwtContext.Scope,
        LCategoryUuid,
        LErrorMessage
      );

    //***************************************
    //* ERROR
    //***************************************
    if LErrorMessage <> '' then
    begin
      if SameText(
        LErrorMessage,
        'Categoria não encontrada.'
      ) then
      begin
        SendError(
          Res,
          404,
          LErrorMessage
        );
      end
      else if SameText(
        LErrorMessage,
        'A categoria não pode ser excluída permanentemente porque possui subcategorias.'
      ) then
      begin
        SendError(
          Res,
          409,
          LErrorMessage
        );
      end
      else
      begin
        SendError(
          Res,
          400,
          LErrorMessage
        );
      end;

      Exit;
    end;

    //***************************************
    //* NOT DELETED
    //***************************************
    if not LDeleted then
    begin
      SendError(
        Res,
        404,
        'Categoria não encontrada.'
      );

      Exit;
    end;

    //***************************************
    //* SUCCESS
    //***************************************
    Res.Status(
      204
    );

    Res.Send(
      ''
    );

  except
    on E: Exception do
    begin
      SendError(
        Res,
        500,
        'Erro interno ao excluir categoria permanentemente: ' +
        E.Message
      );
    end;
  end;
end;

end.
