unit uDatabaseUtils;

interface

uses
  FireDAC.Comp.Client;

type
  TDatabaseUtils = class
  public
    class procedure SetOptionalString(
      const AQuery: TFDQuery;
      const AParamName: string;
      const AValue: string
    );
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Param;

//***************************************
//* SET OPTIONAL STRING
//***************************************
class procedure TDatabaseUtils.SetOptionalString(
  const AQuery: TFDQuery;
  const AParamName: string;
  const AValue: string
);
var
  LParam: TFDParam;
begin
  LParam :=
    AQuery.ParamByName(
      AParamName
    );

  LParam.DataType :=
    ftString;

  if Trim(AValue) = '' then
    LParam.Clear
  else
    LParam.AsString :=
      Trim(AValue);
end;

end.
