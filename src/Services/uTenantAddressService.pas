unit uTenantAddressService;

interface

type
  TTenantAddressService = class
  private
    class function HasGlobalAccess(
      const ASuperUser: Boolean;
      const AScope: string
    ): Boolean; static;

    class function IsValidUuid(
      const AUuid: string
    ): Boolean; static;

    class function IsValidAddressType(
      const AAddressType: string
    ): Boolean; static;

    class function ValidateAddressData(
      const AAddressType: string;
      const AAddressLine: string;
      const ACity: string;
      const AStateCode: string;
      const ACountryCode: string;
      out AErrorMessage: string
    ): Boolean; static;

  public
    class function List(
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidTenantUuid: Boolean
    ): string;

    class function GetByUuid(
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const AAddressUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidTenantUuid: Boolean;
      out AValidAddressUuid: Boolean
    ): string;

    class function Create(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const AAddressType: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const APostalCode: string;
      const ACountryCode: string;
      const AIsPrimary: Boolean;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidTenantUuid: Boolean
    ): string;

    class function Update(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const AAddressUuid: string;
      const AAddressType: string;
      const AAddressLine: string;
      const AAddressNumber: string;
      const AAddressComplement: string;
      const ANeighborhood: string;
      const ACity: string;
      const AStateCode: string;
      const APostalCode: string;
      const ACountryCode: string;
      const AIsPrimary: Boolean;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidTenantUuid: Boolean;
      out AValidAddressUuid: Boolean
    ): string;

    class function Delete(
      const AUserID: Int64;
      const ASuperUser: Boolean;
      const AScope: string;
      const ATenantUuid: string;
      const AAddressUuid: string;
      out AErrorMessage: string;
      out AForbidden: Boolean;
      out AValidTenantUuid: Boolean;
      out AValidAddressUuid: Boolean
    ): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  uTenantRepository,
  uTenantAddressRepository;


//***************************************
//* HAS GLOBAL ACCESS
//***************************************
class function TTenantAddressService.HasGlobalAccess(
  const ASuperUser: Boolean;
  const AScope: string
): Boolean;
begin
  Result :=
    ASuperUser and
    SameText(
      Trim(AScope),
      'GLOBAL'
    );
end;


//***************************************
//* IS VALID UUID
//***************************************
class function TTenantAddressService.IsValidUuid(
  const AUuid: string
): Boolean;
begin
  Result :=
    TRegEx.IsMatch(
      Trim(AUuid),
      '^[0-9a-fA-F]{8}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{4}-' +
      '[0-9a-fA-F]{12}$'
    );
end;


//***************************************
//* IS VALID ADDRESS TYPE
//***************************************
class function TTenantAddressService.IsValidAddressType(
  const AAddressType: string
): Boolean;
var
  LAddressType: string;
begin
  LAddressType :=
    UpperCase(
      Trim(
        AAddressType
      )
    );

  Result :=
    (LAddressType = 'BUSINESS') or
    (LAddressType = 'BILLING') or
    (LAddressType = 'SHIPPING') or
    (LAddressType = 'FISCAL') or
    (LAddressType = 'OTHER');
end;


//***************************************
//* VALIDATE ADDRESS DATA
//***************************************
class function TTenantAddressService.ValidateAddressData(
  const AAddressType: string;
  const AAddressLine: string;
  const ACity: string;
  const AStateCode: string;
  const ACountryCode: string;
  out AErrorMessage: string
): Boolean;
var
  LCountryCode: string;
begin
  Result := False;
  AErrorMessage := '';

  //***************************************
  //* ADDRESS TYPE
  //***************************************
  if Trim(
    AAddressType
  ) = '' then
  begin
    AErrorMessage :=
      'Tipo do endereço é obrigatório.';

    Exit;
  end;

  if not IsValidAddressType(
    AAddressType
  ) then
  begin
    AErrorMessage :=
      'Tipo do endereço inválido.';

    Exit;
  end;

  //***************************************
  //* ADDRESS LINE
  //***************************************
  if Trim(
    AAddressLine
  ) = '' then
  begin
    AErrorMessage :=
      'Logradouro é obrigatório.';

    Exit;
  end;

  //***************************************
  //* CITY
  //***************************************
  if Trim(
    ACity
  ) = '' then
  begin
    AErrorMessage :=
      'Cidade é obrigatória.';

    Exit;
  end;

  //***************************************
  //* STATE CODE
  //***************************************
  if Trim(
    AStateCode
  ) = '' then
  begin
    AErrorMessage :=
      'UF é obrigatória.';

    Exit;
  end;

  if Length(
    Trim(
      AStateCode
    )
  ) <> 2 then
  begin
    AErrorMessage :=
      'UF deve possuir 2 caracteres.';

    Exit;
  end;

  //***************************************
  //* COUNTRY CODE
  //***************************************
  LCountryCode :=
    Trim(
      ACountryCode
    );

  if LCountryCode = '' then
    LCountryCode := 'BR';

  if Length(
    LCountryCode
  ) <> 2 then
  begin
    AErrorMessage :=
      'Código do país deve possuir 2 caracteres.';

    Exit;
  end;

  Result := True;
end;


//***************************************
//* LIST
//***************************************
class function TTenantAddressService.List(
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidTenantUuid: Boolean
): string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* TENANT UUID
  //***************************************
  AValidTenantUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidTenantUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTHORIZATION
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;

    AErrorMessage :=
      'Usuário não possui permissão para consultar endereços de tenants.';

    Exit;
  end;

  //***************************************
  //* TENANT EXISTS
  //***************************************
  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TTenantAddressRepository.List(
      ATenantUuid
    );
end;


//***************************************
//* GET BY UUID
//***************************************
class function TTenantAddressService.GetByUuid(
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const AAddressUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidTenantUuid: Boolean;
  out AValidAddressUuid: Boolean
): string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* TENANT UUID
  //***************************************
  AValidTenantUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidTenantUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* ADDRESS UUID
  //***************************************
  AValidAddressUuid :=
    IsValidUuid(
      AAddressUuid
    );

  if not AValidAddressUuid then
  begin
    AErrorMessage :=
      'UUID do endereço inválido.';

    Exit;
  end;

  //***************************************
  //* AUTHORIZATION
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;

    AErrorMessage :=
      'Usuário não possui permissão para consultar endereços de tenants.';

    Exit;
  end;

  //***************************************
  //* TENANT EXISTS
  //***************************************
  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TTenantAddressRepository.GetByUuid(
      ATenantUuid,
      AAddressUuid
    );

  if Result = '' then
  begin
    AErrorMessage :=
      'Endereço do tenant não encontrado.';
  end;
end;


//***************************************
//* CREATE
//***************************************
class function TTenantAddressService.Create(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const AAddressType: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const APostalCode: string;
  const ACountryCode: string;
  const AIsPrimary: Boolean;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidTenantUuid: Boolean
): string;
var
  LCountryCode: string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* TENANT UUID
  //***************************************
  AValidTenantUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidTenantUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* AUTHORIZATION
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;

    AErrorMessage :=
      'Usuário não possui permissão para incluir endereços de tenants.';

    Exit;
  end;

  //***************************************
  //* TENANT EXISTS
  //***************************************
  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* COUNTRY CODE
  //***************************************
  LCountryCode :=
    UpperCase(
      Trim(
        ACountryCode
      )
    );

  if LCountryCode = '' then
    LCountryCode := 'BR';

  //***************************************
  //* VALIDATION
  //***************************************
  if not ValidateAddressData(
    AAddressType,
    AAddressLine,
    ACity,
    AStateCode,
    LCountryCode,
    AErrorMessage
  ) then
    Exit;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TTenantAddressRepository.Create(
      AUserID,
      ATenantUuid,
      UpperCase(
        Trim(
          AAddressType
        )
      ),
      Trim(
        AAddressLine
      ),
      Trim(
        AAddressNumber
      ),
      Trim(
        AAddressComplement
      ),
      Trim(
        ANeighborhood
      ),
      Trim(
        ACity
      ),
      UpperCase(
        Trim(
          AStateCode
        )
      ),
      Trim(
        APostalCode
      ),
      LCountryCode,
      AIsPrimary
    );

  if Result = '' then
  begin
    AErrorMessage :=
      'Não foi possível incluir o endereço do tenant.';
  end;
end;


//***************************************
//* UPDATE
//***************************************
class function TTenantAddressService.Update(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const AAddressUuid: string;
  const AAddressType: string;
  const AAddressLine: string;
  const AAddressNumber: string;
  const AAddressComplement: string;
  const ANeighborhood: string;
  const ACity: string;
  const AStateCode: string;
  const APostalCode: string;
  const ACountryCode: string;
  const AIsPrimary: Boolean;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidTenantUuid: Boolean;
  out AValidAddressUuid: Boolean
): string;
var
  LCountryCode: string;
begin
  Result := '';
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* TENANT UUID
  //***************************************
  AValidTenantUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidTenantUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* ADDRESS UUID
  //***************************************
  AValidAddressUuid :=
    IsValidUuid(
      AAddressUuid
    );

  if not AValidAddressUuid then
  begin
    AErrorMessage :=
      'UUID do endereço inválido.';

    Exit;
  end;

  //***************************************
  //* AUTHORIZATION
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;

    AErrorMessage :=
      'Usuário não possui permissão para alterar endereços de tenants.';

    Exit;
  end;

  //***************************************
  //* TENANT EXISTS
  //***************************************
  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* ADDRESS EXISTS
  //***************************************
  if not TTenantAddressRepository.Exists(
    ATenantUuid,
    AAddressUuid
  ) then
  begin
    AErrorMessage :=
      'Endereço do tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* COUNTRY CODE
  //***************************************
  LCountryCode :=
    UpperCase(
      Trim(
        ACountryCode
      )
    );

  if LCountryCode = '' then
    LCountryCode := 'BR';

  //***************************************
  //* VALIDATION
  //***************************************
  if not ValidateAddressData(
    AAddressType,
    AAddressLine,
    ACity,
    AStateCode,
    LCountryCode,
    AErrorMessage
  ) then
    Exit;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TTenantAddressRepository.Update(
      AUserID,
      ATenantUuid,
      AAddressUuid,
      UpperCase(
        Trim(
          AAddressType
        )
      ),
      Trim(
        AAddressLine
      ),
      Trim(
        AAddressNumber
      ),
      Trim(
        AAddressComplement
      ),
      Trim(
        ANeighborhood
      ),
      Trim(
        ACity
      ),
      UpperCase(
        Trim(
          AStateCode
        )
      ),
      Trim(
        APostalCode
      ),
      LCountryCode,
      AIsPrimary
    );

  if Result = '' then
  begin
    AErrorMessage :=
      'Não foi possível alterar o endereço do tenant.';
  end;
end;


//***************************************
//* DELETE
//***************************************
class function TTenantAddressService.Delete(
  const AUserID: Int64;
  const ASuperUser: Boolean;
  const AScope: string;
  const ATenantUuid: string;
  const AAddressUuid: string;
  out AErrorMessage: string;
  out AForbidden: Boolean;
  out AValidTenantUuid: Boolean;
  out AValidAddressUuid: Boolean
): Boolean;
begin
  Result := False;
  AErrorMessage := '';
  AForbidden := False;

  //***************************************
  //* TENANT UUID
  //***************************************
  AValidTenantUuid :=
    IsValidUuid(
      ATenantUuid
    );

  if not AValidTenantUuid then
  begin
    AErrorMessage :=
      'UUID do tenant inválido.';

    Exit;
  end;

  //***************************************
  //* ADDRESS UUID
  //***************************************
  AValidAddressUuid :=
    IsValidUuid(
      AAddressUuid
    );

  if not AValidAddressUuid then
  begin
    AErrorMessage :=
      'UUID do endereço inválido.';

    Exit;
  end;

  //***************************************
  //* AUTHORIZATION
  //***************************************
  if not HasGlobalAccess(
    ASuperUser,
    AScope
  ) then
  begin
    AForbidden := True;

    AErrorMessage :=
      'Usuário não possui permissão para excluir endereços de tenants.';

    Exit;
  end;

  //***************************************
  //* TENANT EXISTS
  //***************************************
  if not TTenantRepository.Exists(
    ATenantUuid,
    False
  ) then
  begin
    AErrorMessage :=
      'Tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* ADDRESS EXISTS
  //***************************************
  if not TTenantAddressRepository.Exists(
    ATenantUuid,
    AAddressUuid
  ) then
  begin
    AErrorMessage :=
      'Endereço do tenant não encontrado.';

    Exit;
  end;

  //***************************************
  //* REPOSITORY
  //***************************************
  Result :=
    TTenantAddressRepository.Delete(
      AUserID,
      ATenantUuid,
      AAddressUuid
    );

  if not Result then
  begin
    AErrorMessage :=
      'Não foi possível excluir o endereço do tenant.';
  end;
end;

end.
