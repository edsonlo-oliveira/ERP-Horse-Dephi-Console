unit uAuditContext;

interface

uses
  FireDAC.Comp.Client;

procedure SetAuditContext(
  const AConnection: TFDConnection;
  const AUserID: Int64;
  const ATenantID: Int64
);

implementation

uses
  System.SysUtils;

//***************************************
//* AUDIT CONTEXT
//***************************************
procedure SetAuditContext(
  const AConnection: TFDConnection;
  const AUserID: Int64;
  const ATenantID: Int64
);
var
  ContextQuery: TFDQuery;
begin
  ContextQuery :=
    TFDQuery.Create(nil);

  try
    ContextQuery.Connection :=
      AConnection;

    ContextQuery.SQL.Text :=
      'SELECT ' +
      'set_config(''app.user_id'', :user_id, true), ' +
      'set_config(''app.tenant_id'', :tenant_id, true)';

    ContextQuery.ParamByName(
      'user_id'
    ).AsString :=
      AUserID.ToString;

    ContextQuery.ParamByName(
      'tenant_id'
    ).AsString :=
      ATenantID.ToString;

    ContextQuery.Open;

  finally
    ContextQuery.Free;
  end;
end;

end.
