unit uEntityService;

interface

type
  TEntityService = class
  public
    class function List: string;
  end;

implementation

uses
  uEntityRepository;

class function TEntityService.List: string;
begin
  Result := TEntityRepository.List;
end;

end.
