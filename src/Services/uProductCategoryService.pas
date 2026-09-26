unit uProductCategoryService;

interface

type
  TProductCategoryService = class
  private
    class function ResolveTenantID(
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      out AEffectiveTenantID: Int64;
      out AErrorMessage: string
    ): Boolean; static;

    class function ValidateCategoryName(
      const ACategoryName: string;
      out AErrorMessage: string
    ): Boolean; static;

    class function ValidateUuid(
      const AUuid: string
    ): Boolean; static;

    class function ResolveCategoryID(
      const ATenantID: Int64;
      const AProductCategoryUuid: string;
      out AProductCategoryID: Int64;
      out AErrorMessage: string
    ): Boolean; static;

    class function ResolveParentCategoryID(
      const ATenantID: Int64;
      const AParentCategoryUuid: string;
      out AParentCategoryID: Int64;
      out AErrorMessage: string
    ): Boolean; static;

  public
    class function List(
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      out AErrorMessage: string
    ): string; static;

    class function GetByUuid(
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AProductCategoryUuid: string;
      out AErrorMessage: string
    ): string; static;

    class function Create(
      const AUserID: Int64;
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ACategoryName: string;
      const AParentCategoryUuid: string;
      const AActive: Boolean;
      out AErrorMessage: string
    ): string; static;

    class function Update(
      const AUserID: Int64;
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AProductCategoryUuid: string;
      const ACategoryName: string;
      const AParentCategoryUuid: string;
      const AActive: Boolean;
      out AErrorMessage: string
    ): string; static;

    class function Delete(
      const AUserID: Int64;
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AProductCategoryUuid: string;
      out AErrorMessage: string
    ): Boolean; static;

    class function HardDelete(
      const AUserID: Int64;
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AProductCategoryUuid: string;
      out AErrorMessage: string
    ): Boolean; static;

    class function SetActive(
      const AUserID: Int64;
      const ASessionTenantID: Int64;
      const ARequestedTenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AProductCategoryUuid: string;
      const AActive: Boolean;
      out AErrorMessage: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  uProductCategoryRepository;


//******************************************
//* RESOLVE TENANT ID
//******************************************
class function TProductCategoryService.ResolveTenantID(
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  out AEffectiveTenantID: Int64;
  out AErrorMessage: string
): Boolean;
begin
  Result := False;

  AEffectiveTenantID := 0;
  AErrorMessage := '';

  //***************************************
  //* GLOBAL SUPER USER
  //***************************************
  if ASuperUser and
     SameText(
       Trim(AScope),
       'GLOBAL'
     ) then
  begin
    if ARequestedTenantID <= 0 then
    begin
      AErrorMessage :=
        'Informe o tenant para realizar esta operação.';

      Exit;
    end;

    AEffectiveTenantID :=
      ARequestedTenantID;

    Exit(True);
  end;

  //***************************************
  //* NORMAL TENANT USER
  //***************************************
  if ASessionTenantID <= 0 then
  begin
    AErrorMessage :=
      'Tenant da sessão inválido.';

    Exit;
  end;

  if (ARequestedTenantID > 0) and
     (ARequestedTenantID <> ASessionTenantID) then
  begin
    AErrorMessage :=
      'Não é permitido acessar dados de outro tenant.';

    Exit;
  end;

  AEffectiveTenantID :=
    ASessionTenantID;

  Result := True;
end;


//******************************************
//* VALIDATE CATEGORY NAME
//******************************************
class function TProductCategoryService.ValidateCategoryName(
  const ACategoryName: string;
  out AErrorMessage: string
): Boolean;
var
  LCategoryName: string;
begin
  Result := False;

  AErrorMessage := '';

  LCategoryName :=
    Trim(
      ACategoryName
    );

  if LCategoryName = '' then
  begin
    AErrorMessage :=
      'O nome da categoria é obrigatório.';

    Exit;
  end;

  if Length(LCategoryName) > 100 then
  begin
    AErrorMessage :=
      'O nome da categoria deve possuir no máximo 100 caracteres.';

    Exit;
  end;

  Result := True;
end;


//******************************************
//* VALIDATE UUID
//******************************************
class function TProductCategoryService.ValidateUuid(
  const AUuid: string
): Boolean;
var
  LUuid: string;
  LGuid: TGUID;
begin
  Result := False;

  LUuid :=
    Trim(
      AUuid
    );

  if LUuid = '' then
    Exit;

  if not LUuid.StartsWith('{') then
  begin
    LUuid :=
      '{' +
      LUuid +
      '}';
  end;

  try
    LGuid :=
      StringToGUID(
        LUuid
      );

    Result := True;

  except
    on E: EConvertError do
    begin
      Result := False;
    end;
  end;
end;


//******************************************
//* RESOLVE CATEGORY ID
//******************************************
class function TProductCategoryService.ResolveCategoryID(
  const ATenantID: Int64;
  const AProductCategoryUuid: string;
  out AProductCategoryID: Int64;
  out AErrorMessage: string
): Boolean;
begin
  Result := False;

  AProductCategoryID := 0;
  AErrorMessage := '';

  if Trim(AProductCategoryUuid) = '' then
  begin
    AErrorMessage :=
      'UUID da categoria não informado.';

    Exit;
  end;

  if not ValidateUuid(
    AProductCategoryUuid
  ) then
  begin
    AErrorMessage :=
      'UUID da categoria inválido.';

    Exit;
  end;

  AProductCategoryID :=
    TProductCategoryRepository.GetIdByUuid(
      ATenantID,
      AProductCategoryUuid
    );

  if AProductCategoryID <= 0 then
  begin
    AErrorMessage :=
      'Categoria não encontrada.';

    Exit;
  end;

  Result := True;
end;


//******************************************
//* RESOLVE PARENT CATEGORY ID
//******************************************
class function TProductCategoryService.ResolveParentCategoryID(
  const ATenantID: Int64;
  const AParentCategoryUuid: string;
  out AParentCategoryID: Int64;
  out AErrorMessage: string
): Boolean;
begin
  Result := False;

  AParentCategoryID := 0;
  AErrorMessage := '';

  //***************************************
  //* ROOT CATEGORY
  //***************************************
  if Trim(AParentCategoryUuid) = '' then
  begin
    Result := True;
    Exit;
  end;

  //***************************************
  //* VALIDATE UUID
  //***************************************
  if not ValidateUuid(
    AParentCategoryUuid
  ) then
  begin
    AErrorMessage :=
      'UUID da categoria pai inválido.';

    Exit;
  end;

  //***************************************
  //* RESOLVE INTERNAL ID
  //***************************************
  AParentCategoryID :=
    TProductCategoryRepository.GetIdByUuid(
      ATenantID,
      AParentCategoryUuid
    );

  if AParentCategoryID <= 0 then
  begin
    AErrorMessage :=
      'Categoria pai não encontrada.';

    Exit;
  end;

  Result := True;
end;


//******************************************
//* LIST
//******************************************
class function TProductCategoryService.List(
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  out AErrorMessage: string
): string;
var
  LEffectiveTenantID: Int64;
begin
  Result := '';

  AErrorMessage := '';

  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  Result :=
    TProductCategoryRepository.List(
      LEffectiveTenantID
    );
end;


//******************************************
//* GET BY UUID
//******************************************
class function TProductCategoryService.GetByUuid(
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AProductCategoryUuid: string;
  out AErrorMessage: string
): string;
var
  LEffectiveTenantID: Int64;
  LProductCategoryID: Int64;
begin
  Result := '';

  AErrorMessage := '';

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY
  //***************************************
  if not ResolveCategoryID(
    LEffectiveTenantID,
    AProductCategoryUuid,
    LProductCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* GET
  //***************************************
  Result :=
    TProductCategoryRepository.GetByUuid(
      LEffectiveTenantID,
      AProductCategoryUuid
    );
end;


//******************************************
//* CREATE
//******************************************
class function TProductCategoryService.Create(
  const AUserID: Int64;
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ACategoryName: string;
  const AParentCategoryUuid: string;
  const AActive: Boolean;
  out AErrorMessage: string
): string;
var
  LEffectiveTenantID: Int64;
  LParentCategoryID: Int64;
  LCategoryName: string;
begin
  Result := '';

  AErrorMessage := '';

  LCategoryName :=
    Trim(
      ACategoryName
    );

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY NAME
  //***************************************
  if not ValidateCategoryName(
    LCategoryName,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* PARENT CATEGORY
  //***************************************
  if not ResolveParentCategoryID(
    LEffectiveTenantID,
    AParentCategoryUuid,
    LParentCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* DUPLICATE NAME IN LEVEL
  //***************************************
  if TProductCategoryRepository.ExistsNameInLevel(
    LEffectiveTenantID,
    LCategoryName,
    LParentCategoryID
  ) then
  begin
    AErrorMessage :=
      'Já existe uma categoria com este nome neste nível.';

    Exit;
  end;

  //***************************************
  //* CREATE
  //***************************************
  Result :=
    TProductCategoryRepository.Create(
      AUserID,
      LEffectiveTenantID,
      LCategoryName,
      LParentCategoryID,
      AActive
    );
end;


//******************************************
//* UPDATE
//******************************************
class function TProductCategoryService.Update(
  const AUserID: Int64;
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AProductCategoryUuid: string;
  const ACategoryName: string;
  const AParentCategoryUuid: string;
  const AActive: Boolean;
  out AErrorMessage: string
): string;
var
  LEffectiveTenantID: Int64;
  LProductCategoryID: Int64;
  LParentCategoryID: Int64;
  LCategoryName: string;
begin
  Result := '';

  AErrorMessage := '';

  LCategoryName :=
    Trim(
      ACategoryName
    );

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY
  //***************************************
  if not ResolveCategoryID(
    LEffectiveTenantID,
    AProductCategoryUuid,
    LProductCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY NAME
  //***************************************
  if not ValidateCategoryName(
    LCategoryName,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* PARENT CATEGORY
  //***************************************
  if not ResolveParentCategoryID(
    LEffectiveTenantID,
    AParentCategoryUuid,
    LParentCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* PARENT = ITSELF
  //***************************************
  if (LParentCategoryID > 0) and
     (LParentCategoryID = LProductCategoryID) then
  begin
    AErrorMessage :=
      'Uma categoria não pode ser pai dela mesma.';

    Exit;
  end;

  //***************************************
  //* CIRCULAR HIERARCHY
  //***************************************
  if (LParentCategoryID > 0) and
     TProductCategoryRepository.IsDescendant(
       LEffectiveTenantID,
       LProductCategoryID,
       LParentCategoryID
     ) then
  begin
    AErrorMessage :=
      'A categoria não pode ser movida para uma de suas próprias subcategorias.';

    Exit;
  end;

  //***************************************
  //* DUPLICATE NAME IN LEVEL
  //***************************************
  if TProductCategoryRepository.ExistsNameInLevel(
    LEffectiveTenantID,
    LCategoryName,
    LParentCategoryID,
    LProductCategoryID
  ) then
  begin
    AErrorMessage :=
      'Já existe uma categoria com este nome neste nível.';

    Exit;
  end;

  //***************************************
  //* UPDATE
  //***************************************
  Result :=
    TProductCategoryRepository.Update(
      AUserID,
      LEffectiveTenantID,
      LProductCategoryID,
      LCategoryName,
      LParentCategoryID,
      AActive
    );
end;


//******************************************
//* DELETE
//******************************************
class function TProductCategoryService.Delete(
  const AUserID: Int64;
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AProductCategoryUuid: string;
  out AErrorMessage: string
): Boolean;
var
  LEffectiveTenantID: Int64;
  LProductCategoryID: Int64;
begin
  Result := False;

  AErrorMessage := '';

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY
  //***************************************
  if not ResolveCategoryID(
    LEffectiveTenantID,
    AProductCategoryUuid,
    LProductCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CHILDREN
  //***************************************
  if TProductCategoryRepository.HasChildren(
    LEffectiveTenantID,
    LProductCategoryID
  ) then
  begin
    AErrorMessage :=
      'A categoria não pode ser excluída porque possui subcategorias.';

    Exit;
  end;

  //***************************************
  //* DELETE
  //***************************************
  Result :=
    TProductCategoryRepository.Delete(
      AUserID,
      LEffectiveTenantID,
      LProductCategoryID
    );

  if not Result then
  begin
    AErrorMessage :=
      'Categoria não encontrada.';
  end;
end;


//******************************************
//* SET ACTIVE
//******************************************
class function TProductCategoryService.SetActive(
  const AUserID: Int64;
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AProductCategoryUuid: string;
  const AActive: Boolean;
  out AErrorMessage: string
): Boolean;
var
  LEffectiveTenantID: Int64;
  LProductCategoryID: Int64;
begin
  Result := False;

  AErrorMessage := '';

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* CATEGORY
  //***************************************
  if not ResolveCategoryID(
    LEffectiveTenantID,
    AProductCategoryUuid,
    LProductCategoryID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* SET ACTIVE
  //***************************************
  Result :=
    TProductCategoryRepository.SetActive(
      AUserID,
      LEffectiveTenantID,
      LProductCategoryID,
      AActive
    );

  if not Result then
  begin
    AErrorMessage :=
      'Categoria não encontrada.';
  end;
end;

//******************************************
//* HARD DELETE
//******************************************
class function TProductCategoryService.HardDelete(
  const AUserID: Int64;
  const ASessionTenantID: Int64;
  const ARequestedTenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AProductCategoryUuid: string;
  out AErrorMessage: string
): Boolean;
var
  LEffectiveTenantID: Int64;
  LProductCategoryID: Int64;
begin
  Result := False;

  AErrorMessage := '';

  //***************************************
  //* TENANT
  //***************************************
  if not ResolveTenantID(
    ASessionTenantID,
    ARequestedTenantID,
    ASuperUser,
    AScope,
    LEffectiveTenantID,
    AErrorMessage
  ) then
  begin
    Exit;
  end;

  //***************************************
  //* UUID
  //***************************************
  if Trim(AProductCategoryUuid) = '' then
  begin
    AErrorMessage :=
      'UUID da categoria não informado.';

    Exit;
  end;

  if not ValidateUuid(
    AProductCategoryUuid
  ) then
  begin
    AErrorMessage :=
      'UUID da categoria inválido.';

    Exit;
  end;

  //***************************************
  //* RESOLVE INTERNAL ID
  //* INCLUDING SOFT-DELETED RECORDS
  //***************************************
  LProductCategoryID :=
    TProductCategoryRepository.GetIdByUuidIncludingDeleted(
      LEffectiveTenantID,
      AProductCategoryUuid
    );

  if LProductCategoryID <= 0 then
  begin
    AErrorMessage :=
      'Categoria não encontrada.';

    Exit;
  end;

  //***************************************
  //* CHECK ANY CHILDREN
  //* INCLUDING SOFT-DELETED CHILDREN
  //***************************************
  if TProductCategoryRepository.HasAnyChildren(
    LEffectiveTenantID,
    LProductCategoryID
  ) then
  begin
    AErrorMessage :=
      'A categoria não pode ser excluída permanentemente porque possui subcategorias.';

    Exit;
  end;

  //***************************************
  //* HARD DELETE
  //***************************************
  Result :=
    TProductCategoryRepository.HardDelete(
      AUserID,
      LEffectiveTenantID,
      LProductCategoryID
    );

  if not Result then
  begin
    AErrorMessage :=
      'Categoria não encontrada.';
  end;
end;
end.
