unit uRoutes;

interface

procedure RegisterRoutes;

implementation

uses
  Horse,
  uEntityController;

procedure RegisterRoutes;
begin
  THorse.Get(
    '/api/v1/entities',
    TEntityController.List
  );
end;

end.
