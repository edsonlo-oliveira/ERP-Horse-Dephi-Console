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

  THorse.Get(
    '/api/v1/entities/:uuid',
    TEntityController.GetByUuid
  );

  THorse.Post(
    '/api/v1/entities',
    TEntityController.Create
  );

  THorse.Put(
    '/api/v1/entities/:uuid',
    TEntityController.Update
  );

  THorse.Delete(
    '/api/v1/entities/:uuid',
    TEntityController.Delete
  );

  THorse.Delete(
    '/api/v1/entities/:uuid/permanent',
    TEntityController.HardDelete
  );
end;

end.
