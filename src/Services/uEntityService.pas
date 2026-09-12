unit uEntityService;

interface

type
  TEntityService = class
  public
    class function List: string;

    class function GetByUuid(const AEntityUuid: string; out AValidUuid: Boolean): string;

    class function Create(
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      out AErrorMessage: string
    ): string;

    class function Update(
      const AEntityUuid: string;
      const AEntityType: string;
      const ATaxId: string;
      const ALegalName: string;
      const ATradeName: string;
      const AIsCustomer: Boolean;
      const AIsSupplier: Boolean;
      const AEmail: string;
      const APhone: string;
      const AMobilePhone: string;
      out AValidUuid: Boolean;
      out AErrorMessage: string
    ): string;

    class function Delete(const AEntityUuid: string; out AValidUuid: Boolean): Boolean;
    class function HardDelete(const AEntityUuid: string; out AValidUuid: Boolean; out AHasDependencies: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils,
  uEntityRepository;

class function TEntityService.List: string;
begin
  Result := TEntityRepository.List;
end;

class function TEntityService.GetByUuid(
  const AEntityUuid: string;
  out AValidUuid: Boolean
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;
begin
  AValidUuid := False;
  Result := '';

  NormalizedUuid := Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if (NormalizedUuid[1] <> '{') then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
      Exit;
  end;

  Result := TEntityRepository.GetByUuid(
    GUIDToString(UUID)
  );
end;

class function TEntityService.Create(
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  out AErrorMessage: string
): string;
var
  EntityType: string;
  LegalName: string;
begin
  Result := '';
  AErrorMessage := '';

  EntityType := UpperCase(Trim(AEntityType));
  LegalName := Trim(ALegalName);

  if (EntityType <> 'COMPANY') and
    (EntityType <> 'INDIVIDUAL') then
  begin
    AErrorMessage :=
      'entity_type deve ser COMPANY ou INDIVIDUAL.';
    Exit;
  end;

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  Result := TEntityRepository.Create(
    EntityType,
    Trim(ATaxId),
    LegalName,
    Trim(ATradeName),
    AIsCustomer,
    AIsSupplier,
    Trim(AEmail),
    Trim(APhone),
    Trim(AMobilePhone)
  );
end;

class function TEntityService.Update(
  const AEntityUuid: string;
  const AEntityType: string;
  const ATaxId: string;
  const ALegalName: string;
  const ATradeName: string;
  const AIsCustomer: Boolean;
  const AIsSupplier: Boolean;
  const AEmail: string;
  const APhone: string;
  const AMobilePhone: string;
  out AValidUuid: Boolean;
  out AErrorMessage: string
): string;
var
  UUID: TGUID;
  NormalizedUuid: string;
  EntityType: string;
  LegalName: string;
begin
  Result := '';
  AValidUuid := False;
  AErrorMessage := '';

  NormalizedUuid := Trim(AEntityUuid);

  if NormalizedUuid = '' then
  begin
    AErrorMessage := 'UUID da entidade não informado.';
    Exit;
  end;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
    begin
      AErrorMessage := 'UUID da entidade inválido.';
      Exit;
    end;
  end;

  EntityType := UpperCase(Trim(AEntityType));
  LegalName := Trim(ALegalName);

  if (EntityType <> 'COMPANY') and
     (EntityType <> 'INDIVIDUAL') then
  begin
    AErrorMessage :=
      'entity_type deve ser COMPANY ou INDIVIDUAL.';
    Exit;
  end;

  if LegalName = '' then
  begin
    AErrorMessage :=
      'legal_name é obrigatório.';
    Exit;
  end;

  Result := TEntityRepository.Update(
    GUIDToString(UUID),
    EntityType,
    Trim(ATaxId),
    LegalName,
    Trim(ATradeName),
    AIsCustomer,
    AIsSupplier,
    Trim(AEmail),
    Trim(APhone),
    Trim(AMobilePhone)
  );
end;

class function TEntityService.Delete(
  const AEntityUuid: string;
  out AValidUuid: Boolean
): Boolean;
var
  UUID: TGUID;
  NormalizedUuid: string;
begin
  Result := False;
  AValidUuid := False;

  NormalizedUuid := Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
      Exit;
  end;

  Result := TEntityRepository.Delete(
    GUIDToString(UUID)
  );
end;

class function TEntityService.HardDelete(
  const AEntityUuid: string;
  out AValidUuid: Boolean;
  out AHasDependencies: Boolean
): Boolean;
var
  UUID: TGUID;
  NormalizedUuid: string;
begin
  Result := False;
  AValidUuid := False;
  AHasDependencies := False;

  NormalizedUuid := Trim(AEntityUuid);

  if NormalizedUuid = '' then
    Exit;

  if NormalizedUuid[1] <> '{' then
    NormalizedUuid := '{' + NormalizedUuid + '}';

  try
    UUID := StringToGUID(NormalizedUuid);
    AValidUuid := True;
  except
    on E: EConvertError do
      Exit;
  end;

  Result := TEntityRepository.HardDelete(
    GUIDToString(UUID),
    AHasDependencies
  );
end;

end.
