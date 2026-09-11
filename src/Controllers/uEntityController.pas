unit uEntityController;

interface

uses
  Horse;

type
  TEntityController = class
  public
    class procedure List(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  uEntityService;

class procedure TEntityController.List(
  Req: THorseRequest;
  Res: THorseResponse
);
begin
  Res.ContentType('application/json');

  Res.Send(
    TEntityService.List
  );
end;

end.
