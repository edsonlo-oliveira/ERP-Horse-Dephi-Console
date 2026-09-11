unit uEntityRepository;

interface

type
  TEntityRepository = class
  public
    class function List: string;
  end;

implementation

class function TEntityRepository.List: string;
begin
  Result :=
    '[' +
      '{"entity_id":1,"entity_type":"COMPANY","legal_name":"Empresa Exemplo Ltda","trade_name":"Empresa Exemplo","is_customer":true,"is_supplier":false},' +
      '{"entity_id":2,"entity_type":"COMPANY","legal_name":"Fornecedor Exemplo Ltda","trade_name":"Fornecedor Exemplo","is_customer":false,"is_supplier":true},' +
      '{"entity_id":3,"entity_type":"INDIVIDUAL","legal_name":"João da Silva","trade_name":null,"is_customer":true,"is_supplier":true}' +
    ']';
end;

end.
