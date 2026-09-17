unit uRoutes;

interface

procedure RegisterRoutes;

implementation

uses
  Horse,
  uEntityController,
  uTenantController,
  uUserController,
  uAuthController,
  uJwtMiddleware;

procedure RegisterRoutes;
begin
  //***************************************
  //* ENTITIES
  //***************************************
  THorse.Get(
    '/api/v1/entities',
    [JwtMiddleware],
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

  //***************************************
  //* TENANTS
  //***************************************
  THorse.Get(
    '/api/v1/tenants',
    [JwtMiddleware],
    TTenantController.List
  );

  THorse.Get(
    '/api/v1/tenants/:uuid',
    TTenantController.GetByUuid
  );

  THorse.Post(
    '/api/v1/tenants',
    TTenantController.Create
  );

  THorse.Put(
    '/api/v1/tenants/:uuid',
    TTenantController.Update
  );

  THorse.Delete(
    '/api/v1/tenants/:uuid',
    TTenantController.Delete
  );

  //***************************************
  //* Users
  //***************************************
  THorse.Get('/api/v1/users', TUserController.List);
  THorse.Get('/api/v1/users/:uuid', TUserController.GetByUuid);
  THorse.Post('/api/v1/users', TUserController.Create);
  THorse.Put('/api/v1/users/:uuid', TUserController.Update);
  THorse.Delete('/api/v1/users/:uuid', TUserController.Delete);

  //***************************************
  //* AUTHENTICATION
  //***************************************
  THorse.Post('/api/v1/auth/login', TAuthController.Login);
end;


end.
