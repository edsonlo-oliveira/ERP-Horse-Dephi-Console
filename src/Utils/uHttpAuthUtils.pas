unit uHttpAuthUtils;

interface

uses
  Horse;

function ExtractBearerToken(AReq: THorseRequest): string;

implementation

uses
  System.SysUtils;

function ExtractBearerToken(AReq: THorseRequest): string;
var
  LAuthorization: string;
begin
  Result := '';
  LAuthorization := Trim(AReq.Headers['Authorization']);

  if LAuthorization = '' then
    Exit;

  if not SameText(Copy(LAuthorization, 1, Length('Bearer ')), 'Bearer ') then
    Exit;

  Result := Trim(Copy(LAuthorization, Length('Bearer ') + 1, MaxInt));
end;

end.
