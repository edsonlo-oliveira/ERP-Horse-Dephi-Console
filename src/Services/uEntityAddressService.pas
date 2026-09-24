unit uEntityAddressService;

interface

type
  TEntityAddressService = class
  private
    class function IsValidUuid(
      const AValue: string
    ): Boolean; static;

    class function IsValidAddressType(
      const AValue: string
    ): Boolean; static;

    class function NormalizeAddressType(
      const AValue: string
    ): string; static;

    class function ValidateAddressData(
      const AAddressType: string;
      const AAddressLine: string;
      const ACity: string;
      const AStateCode: string;
      out AErrorMessage: string
    ): Boolean; static;

  public
    class function List(
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      out AValidUuid: Boolean
    ): string;

    class function GetById(
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      const AEntityAddressID: Int64;
      out AValidUuid: Boolean
    ): string;

    class function Create(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      const AAddressType: string;
      const APostalCode: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const AIsPrimary: Boolean;
      out AValidUuid: Boolean;
      out AErrorMessage: string
    ): string;

    class function Update(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      const AEntityAddressID: Int64;
      const AAddressType: string;
      const APostalCode: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const AIsPrimary: Boolean;
      out AValidUuid: Boolean;
      out AErrorMessage: string
    ): string;

    class function Delete(
      const AUserID: Int64;
      const ATenantID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const AEntityUuid: string;
      const AEntityAddressID: Int64;
      out AValidUuid: Boolean;
      out AErrorMessage: string
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  uEntityAddressRepository;

//***********************************************
//* IS VALID UUID
//***********************************************
class function TEntityAddressService.IsValidUuid(
  const AValue: string
): Boolean;
var
  LValue: string;
begin
  LValue :=
    Trim(AValue);

  LValue :=
    StringReplace(
      LValue,
      '{',
      '',
      [rfReplaceAll]
    );

  LValue :=
    StringReplace(
      LValue,
      '}',
      '',
      [rfReplaceAll]
    );

  Result :=
    TRegEx.IsMatch(
      LValue,
      '^[0-9a-fA-F]{8}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{12}$'
    );
end;

//***********************************************
//* NORMALIZE ADDRESS TYPE
//***********************************************
class function TEntityAddressService.NormalizeAddressType(
  const AValue: string
): string;
begin
  Result :=
    UpperCase(
      Trim(AValue)
    );
end;

//***********************************************
//* IS VALID ADDRESS TYPE
//***********************************************
class function TEntityAddressService.IsValidAddressType(
  const AValue: string
): Boolean;
var
  LAddressType: string;
begin
  LAddressType :=
    NormalizeAddressType(
      AValue
    );

  Result :=
       (LAddressType = 'BUSINESS')
    or (LAddressType = 'BILLING')
    or (LAddressType = 'SHIPPING')
    or (LAddressType = 'OTHER');
end;

//***********************************************
//* VALIDATE ADDRESS DATA
//***********************************************
class function TEntityAddressService.ValidateAddressData(
  const AAddressType: string;
  const AAddressLine: string;
  const ACity: string;
  const AStateCode: string;
  out AErrorMessage: string
): Boolean;
var
  LStateCode: string;
begin
  Result := False;
  AErrorMessage := '';

  //***************************************
  //* ADDRESS TYPE
  //***************************************
  if Trim(AAddressType) = '' then
  begin
    AErrorMessage :=
      'Tipo do endereço não informado.';
    Exit;
  end;

  if not IsValidAddressType(
    AAddressType
  ) then
  begin
    AErrorMessage :=
      'Tipo de endereço inválido. ' +
      'Os tipos permitidos são BUSINESS, BILLING, SHIPPING e OTHER.';
    Exit;
  end;

  //***************************************
  //* ADDRESS LINE
  //***************************************
  if Trim(AAddressLine) = '' then
  begin
    AErrorMessage :=
      'Endereço não informado.';
    Exit;
  end;

  if Length(
    Trim(AAddressLine)
  ) > 200 then
  begin
    AErrorMessage :=
      'O endereço não pode possuir mais de 200 caracteres.';
    Exit;
  end;

  //***************************************
  //* CITY
  //***************************************
  if Trim(ACity) = '' then
  begin
    AErrorMessage :=
      'Cidade não informada.';
    Exit;
  end;

  if Length(
    Trim(ACity)
  ) > 100 then
  begin
    AErrorMessage :=
      'A cidade não pode possuir mais de 100 caracteres.';
    Exit;
  end;

  //***************************************
  //* STATE
  //***************************************
  LStateCode :=
    UpperCase(
      Trim(AStateCode)
    );

  if LStateCode = '' then
  begin
    AErrorMessage :=
      'UF não informada.';
    Exit;
  end;

  if Length(LStateCode) <> 2 then
  begin
    AErrorMessage :=
      'A UF deve possuir exatamente 2 caracteres.';
    Exit;
  end;

  Result := True;
end;

//***********************************************
//* LIST
//***********************************************
class function TEntityAddressService.List(
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  out AValidUuid: Boolean
): string;
var
  LGlobalScope: Boolean;
begin
  Result := '';

  AValidUuid :=
    IsValidUuid(
      AEntityUuid
    );

  if not AValidUuid then
    Exit;

  LGlobalScope :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );

  Result :=
    TEntityAddressRepository.List(
      ATenantID,
      LGlobalScope,
      Trim(AEntityUuid)
    );
end;

//***********************************************
//* GET BY ID
//***********************************************
class function TEntityAddressService.GetById(
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  const AEntityAddressID: Int64;
  out AValidUuid: Boolean
): string;
var
  LGlobalScope: Boolean;
begin
  Result := '';

  AValidUuid :=
    IsValidUuid(
      AEntityUuid
    );

  if not AValidUuid then
    Exit;

  if AEntityAddressID <= 0 then
    Exit;

  LGlobalScope :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );

  Result :=
    TEntityAddressRepository.GetById(
      ATenantID,
      LGlobalScope,
      Trim(AEntityUuid),
      AEntityAddressID
    );
end;

//***********************************************
//* CREATE
//***********************************************
class function TEntityAddressService.Create(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  const AAddressType: string;
  const APostalCode: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const AIsPrimary: Boolean;
  out AValidUuid: Boolean;
  out AErrorMessage: string
): string;
var
  LGlobalScope: Boolean;
  LAddressType: string;
  LStateCode: string;
begin
  Result := '';
  AErrorMessage := '';

  //***************************************
  //* UUID
  //***************************************
  AValidUuid :=
    IsValidUuid(
      AEntityUuid
    );

  if not AValidUuid then
    Exit;

  //***************************************
  //* VALIDATE
  //***************************************
  if not ValidateAddressData(
    AAddressType,
    AAddressLine,
    ACity,
    AStateCode,
    AErrorMessage
  ) then
    Exit;

  //***************************************
  //* OPTIONAL FIELD LENGTHS
  //***************************************
  if Length(Trim(APostalCode)) > 10 then
  begin
    AErrorMessage :=
      'O CEP não pode possuir mais de 10 caracteres.';
    Exit;
  end;

  if Length(Trim(AAddressNumber)) > 20 then
  begin
    AErrorMessage :=
      'O número do endereço não pode possuir mais de 20 caracteres.';
    Exit;
  end;

  if Length(Trim(AAddressComplement)) > 100 then
  begin
    AErrorMessage :=
      'O complemento não pode possuir mais de 100 caracteres.';
    Exit;
  end;

  if Length(Trim(ANeighborhood)) > 100 then
  begin
    AErrorMessage :=
      'O bairro não pode possuir mais de 100 caracteres.';
    Exit;
  end;

  LAddressType :=
    NormalizeAddressType(
      AAddressType
    );

  LStateCode :=
    UpperCase(
      Trim(AStateCode)
    );

  LGlobalScope :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );

  //***************************************
  //* CREATE
  //***************************************
  Result :=
    TEntityAddressRepository.Create(
      AUserID,
      ATenantID,
      LGlobalScope,
      Trim(AEntityUuid),
      LAddressType,
      Trim(APostalCode),
      Trim(AAddressLine),
      Trim(AAddressNumber),
      Trim(AAddressComplement),
      Trim(ANeighborhood),
      Trim(ACity),
      LStateCode,
      AIsPrimary
    );

  if Result = '' then
  begin
    AErrorMessage :=
      'Entidade não encontrada.';
  end;
end;

//***********************************************
//* UPDATE
//***********************************************
class function TEntityAddressService.Update(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  const AEntityAddressID: Int64;
  const AAddressType: string;
  const APostalCode: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const AIsPrimary: Boolean;
  out AValidUuid: Boolean;
  out AErrorMessage: string
): string;
var
  LGlobalScope: Boolean;
  LAddressType: string;
  LStateCode: string;
begin
  Result := '';
  AErrorMessage := '';

  //***************************************
  //* UUID
  //***************************************
  AValidUuid :=
    IsValidUuid(
      AEntityUuid
    );

  if not AValidUuid then
    Exit;

  //***************************************
  //* ADDRESS ID
  //***************************************
  if AEntityAddressID <= 0 then
  begin
    AErrorMessage :=
      'Identificador do endereço inválido.';
    Exit;
  end;

  //***************************************
  //* VALIDATE
  //***************************************
  if not ValidateAddressData(
    AAddressType,
    AAddressLine,
    ACity,
    AStateCode,
    AErrorMessage
  ) then
    Exit;

  //***************************************
  //* OPTIONAL FIELD LENGTHS
  //***************************************
  if Length(Trim(APostalCode)) > 10 then
  begin
    AErrorMessage :=
      'O CEP não pode possuir mais de 10 caracteres.';
    Exit;
  end;

  if Length(Trim(AAddressNumber)) > 20 then
  begin
    AErrorMessage :=
      'O número do endereço não pode possuir mais de 20 caracteres.';
    Exit;
  end;

  if Length(Trim(AAddressComplement)) > 100 then
  begin
    AErrorMessage :=
      'O complemento não pode possuir mais de 100 caracteres.';
    Exit;
  end;

  if Length(Trim(ANeighborhood)) > 100 then
  begin
    AErrorMessage :=
      'O bairro não pode possuir mais de 100 caracteres.';
    Exit;
  end;

  LAddressType :=
    NormalizeAddressType(
      AAddressType
    );

  LStateCode :=
    UpperCase(
      Trim(AStateCode)
    );

  LGlobalScope :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );

  //***************************************
  //* UPDATE
  //***************************************
  Result :=
    TEntityAddressRepository.Update(
      AUserID,
      ATenantID,
      LGlobalScope,
      Trim(AEntityUuid),
      AEntityAddressID,
      LAddressType,
      Trim(APostalCode),
      Trim(AAddressLine),
      Trim(AAddressNumber),
      Trim(AAddressComplement),
      Trim(ANeighborhood),
      Trim(ACity),
      LStateCode,
      AIsPrimary
    );

  if Result = '' then
  begin
    AErrorMessage :=
      'Endereço não encontrado.';
  end;
end;

//***********************************************
//* DELETE
//***********************************************
class function TEntityAddressService.Delete(
  const AUserID: Int64;
  const ATenantID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const AEntityUuid: string;
  const AEntityAddressID: Int64;
  out AValidUuid: Boolean;
  out AErrorMessage: string
): Boolean;
var
  LGlobalScope: Boolean;
begin
  Result := False;
  AErrorMessage := '';

  //***************************************
  //* UUID
  //***************************************
  AValidUuid :=
    IsValidUuid(
      AEntityUuid
    );

  if not AValidUuid then
    Exit;

  //***************************************
  //* ADDRESS ID
  //***************************************
  if AEntityAddressID <= 0 then
  begin
    AErrorMessage :=
      'Identificador do endereço inválido.';
    Exit;
  end;

  LGlobalScope :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );

  //***************************************
  //* DELETE
  //***************************************
  Result :=
    TEntityAddressRepository.Delete(
      AUserID,
      ATenantID,
      LGlobalScope,
      Trim(AEntityUuid),
      AEntityAddressID
    );

  if not Result then
  begin
    AErrorMessage :=
      'Endereço não encontrado.';
  end;
end;

end.
