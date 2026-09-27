# ERP BACKEND STANDARDS

**Projeto:** ERP Delphi  
**Backend:** Delphi + Horse + PostgreSQL  
**Status da documentação:** Setembro/2026

---

## 1. Objetivo deste documento

Este documento registra o padrão atual do backend do ERP e define como os próximos módulos deverão ser desenvolvidos.

A fonte de verdade continua sendo o código-fonte atual. Esta documentação serve como guia de arquitetura e desenvolvimento, e deve ser atualizada conforme novas regras forem confirmadas durante a implementação dos módulos no cliente FireMonkey.

Não devemos antecipar regras ou refatorações de módulos que ainda não chegaram à etapa de implementação no FMX.

---

## 2. Estratégia de desenvolvimento

O desenvolvimento seguirá o fluxo:

1. iniciar ou evoluir a interface do módulo no cliente FMX;
2. definir as regras funcionais necessárias para aquele módulo;
3. verificar se o backend correspondente já existe;
4. se existir, revisar e ajustar Controller, Service e Repository conforme as regras confirmadas;
5. se não existir, criar o backend seguindo os padrões documentados;
6. compilar e testar incrementalmente;
7. executar os testes funcionais juntamente com a implementação do módulo no cliente;
8. atualizar esta documentação quando uma nova regra se tornar padrão do projeto.

### Regra importante

Não fazer grandes refatorações preventivas em módulos ainda não utilizados pelo cliente.

Uma regra existente pode mudar quando a interface, permissões e fluxo real do módulo forem definidos.

---

## 3. Módulos implementados de ponta a ponta

Atualmente os módulos efetivamente implementados e utilizados dos dois lados são:

- **Entities**
- **Product Categories**

Esses módulos são as principais referências para novos cadastros operacionais.

O backend possui outras unidades já iniciadas ou implementadas, como Tenant e User, porém elas deverão ser revisadas novamente quando seus respectivos módulos forem implementados no FMX.

---

## 4. Arquitetura padrão do backend

Um módulo de negócio normalmente é dividido em três camadas:

```text
Controller
    ↓
Service
    ↓
Repository
    ↓
PostgreSQL
```

### Controller

Responsável por:

- receber a requisição HTTP;
- recuperar contexto JWT;
- ler parâmetros da URL, query string e JSON;
- validar estrutura básica da requisição;
- chamar o Service;
- definir o status HTTP;
- devolver JSON ao cliente.

O Controller não deve conter SQL nem regra complexa de negócio.

### Service

Responsável por:

- regras de negócio;
- regras de acesso entre tenants;
- validações funcionais;
- resolução do tenant efetivo;
- normalização de dados quando necessário;
- coordenação das operações do Repository.

### Repository

Responsável por:

- acesso ao PostgreSQL;
- SQL;
- parâmetros FireDAC;
- transações;
- retorno de dados;
- aplicação do contexto de auditoria antes de operações graváveis.

---

## 5. Multi-tenant

A regra conceitual do sistema é:

### SuperUser

- existe somente no tenant MASTER;
- possui alcance global;
- pode operar sobre diferentes tenants quando a operação permitir;
- o alcance global é determinado por `SuperUser`, e não pelo simples fato de o usuário estar no tenant MASTER.

### Usuário normal / Administrador de tenant

- pertence a um tenant;
- opera somente dentro do próprio tenant;
- permissões específicas serão definidas posteriormente.

### Tenant MASTER

O tenant MASTER determina onde um usuário `super_user = true` pode existir.

Ele não deve ser usado isoladamente como mecanismo de autorização global.

Resumo:

```text
SuperUser
→ controla alcance global

Tenant MASTER
→ controla onde SuperUser pode existir
```

---

## 6. JWT e contexto da requisição

Os Controllers protegidos devem trabalhar com o contexto JWT disponibilizado pela requisição.

O contexto atual contém informações como:

- UserID;
- UserUuid;
- TenantID;
- LoginID;
- SuperUser;
- Scope.

O padrão utilizado é recuperar esse contexto através de `TryGetJwtContext`.

A autenticação global continua sendo responsabilidade do middleware JWT.

---

## 7. Scope

O projeto utiliza os conceitos:

```text
GLOBAL
TENANT
```

Em módulos já existentes há verificações equivalentes a:

```delphi
ASuperUser and SameText(Trim(AScope), 'GLOBAL')
```

Esse conceito é válido, mas a lógica de resolução do tenant não deve ser duplicada desnecessariamente em todos os futuros módulos.

Quando novos módulos exigirem seleção explícita de tenant por SuperUser, utilizar o padrão já aplicado em Product Categories como referência.

---

## 8. Entities

O módulo Entity é referência principalmente para:

- paginação;
- pesquisa;
- ordenação;
- CRUD;
- ativação/inativação;
- soft delete;
- hard delete;
- tratamento de dependências;
- acesso GLOBAL/TENANT;
- integração com auditoria.

O Service recebe o contexto da sessão e converte SuperUser + Scope em alcance global quando apropriado.

O Repository mantém o filtro de tenant e `deleted_at` conforme a operação.

---

## 9. Product Categories

O módulo Product Categories é referência principalmente para:

- hierarquia;
- resolução do tenant efetivo;
- UUID;
- validação de nome;
- parent category;
- regras de descendência;
- impedir estruturas inválidas;
- soft delete;
- hard delete;
- ativação/inativação.

O Service possui helpers privados específicos do próprio domínio, como:

- resolução de tenant;
- validação de nome;
- validação de UUID;
- resolução do ID da categoria;
- resolução da categoria pai.

Esse padrão é considerado bom: lógica específica do domínio deve permanecer dentro do módulo.

---

## 10. Auditoria

O contexto de auditoria foi centralizado em `uAuditContext`.

Repositories que realizam alterações no banco devem configurar o contexto antes de operações auditáveis.

Não recriar localmente a lógica de configuração de auditoria em cada Repository.

---

## 11. Tratamento de erros

Controllers devem diferenciar, conforme aplicável:

- `400` — requisição inválida ou regra de negócio;
- `401` — autenticação/contexto não disponível;
- `403` — autenticado sem permissão;
- `404` — recurso não encontrado;
- `201` — criação realizada;
- `200` — consulta/alteração realizada;
- `500` — erro interno inesperado.

O padrão exato deve seguir a necessidade real de cada módulo.

---

## 12. Avaliação de duplicações atuais

Foi feita uma revisão comparativa dos módulos Entity e Product Categories.

### Services

**Situação:** suficientemente enxutos.

Os helpers encontrados são majoritariamente específicos do domínio e estão corretamente mantidos dentro de cada Service.

Não há benefício claro, neste momento, em criar uma classe base de Services.

### Repositories

**Situação:** suficientemente enxutos.

Existe repetição estrutural inevitável relacionada a:

- criação de queries;
- configuração de parâmetros;
- transações;
- contexto de auditoria;
- conversão de registros para JSON.

Grande parte dessa repetição é própria do SQL e do formato de cada entidade.

Criar agora um Repository genérico aumentaria a abstração e provavelmente dificultaria manutenção.

**Decisão:** não criar Repository base/genérico neste momento.

### Controllers

É onde existe a maior repetição real.

Padrões repetidos incluem:

- `TryGetJwtContext`;
- resposta de erro 401;
- criação de JSON `{ success, message }`;
- respostas 400/404/500;
- leitura e validação de UUID;
- em alguns módulos, leitura de `tenant_id`.

Product Categories já possui um helper privado `SendError`, mostrando que essa centralização é útil.

### Candidatos futuros a helper compartilhado

Sem implementação obrigatória agora:

#### `THttpResponseUtils`

Possível responsabilidade:

```text
SendError
SendSuccess
SendUnauthorized
SendForbidden
SendNotFound
```

#### `TRequestContextUtils`

Possível responsabilidade:

```text
obter JWT context
validar contexto
resolver operações comuns de tenant
```

#### `TTenantAccessUtils`

Possível responsabilidade futura:

```text
IsGlobalScope
ResolveEffectiveTenant
ValidateTenantAccess
```

Esses helpers só devem ser criados quando um terceiro módulo confirmar que a repetição realmente se mantém.

---

## 13. Decisão sobre refatoração agora

**Não haverá uma refatoração geral do backend neste momento.**

A arquitetura atual de Entity e Product Categories está suficientemente organizada para continuar o projeto.

A prioridade é evitar abstrações prematuras.

A partir do próximo módulo, sempre observar:

```text
Se o mesmo bloco aparecer pela terceira vez
→ avaliar helper compartilhado.

Se a regra pertencer somente ao domínio
→ manter no próprio Service/Repository.
```

---

## 14. User — status

O backend de User já possui implementação, mas não será considerado definitivamente fechado até o módulo FMX ser desenvolvido.

Já foi corrigida a distinção arquitetural entre:

```text
SuperUser = alcance global
Tenant MASTER = local permitido para existência de SuperUser
```

Também foi adicionada a regra:

```text
somente SuperUser pode criar outro SuperUser
```

### Pendências para a implementação do User no FMX

- testes funcionais completos;
- revisão das validações de Create e Update;
- definição das permissões de Administrador de tenant;
- definição das permissões de Usuário de tenant;
- revisão de regras específicas de alteração/exclusão de SuperUser;
- eventuais helpers internos somente se forem úteis naquele momento.

---

## 15. Tenant — próximo módulo

O próximo módulo a ser implementado no cliente será **Tenant**.

Ao iniciar o módulo Tenant no FMX, o fluxo será:

1. definir a interface;
2. revisar as regras funcionais;
3. revisar o backend Tenant já existente;
4. corrigir autorização;
5. validar regras do tenant MASTER;
6. definir CRUD permitido ao SuperUser;
7. revisar criação do administrador inicial;
8. testar API e FMX em conjunto;
9. atualizar esta documentação.

Nenhuma regra adicional do Tenant será considerada definitiva antes dessa revisão.

---

## 16. Referências para novos módulos

Para novos módulos operacionais:

### Usar Entity como referência quando houver

- pesquisa;
- paginação;
- ordenação;
- listagem grande;
- soft delete;
- hard delete;
- ativação/inativação.

### Usar Product Categories como referência quando houver

- tenant explicitamente selecionável por SuperUser;
- estruturas hierárquicas;
- validação de relacionamentos;
- resolução UUID → ID;
- regras específicas de dependência entre registros.

---

## 17. Regra de evolução da arquitetura

A arquitetura deve crescer conforme problemas reais surgirem.

Evitar:

- classes base sem necessidade comprovada;
- helpers genéricos para código utilizado uma única vez;
- antecipar permissões de módulos ainda não implementados;
- reescrever módulos funcionais apenas para uniformizar estilo;
- abstrair SQL específico apenas para reduzir linhas.

Preferir:

- código explícito;
- regras fáceis de localizar;
- Services com responsabilidade clara;
- Repositories específicos;
- helpers compartilhados apenas para repetição comprovada;
- evolução incremental com compilação e teste a cada etapa.

---

## 18. Estado atual

```text
FMX + Backend funcionando:
✓ Authentication/Login
✓ Entities
✓ Product Categories

Backend existente, mas será validado junto ao FMX:
◐ Tenant
◐ User

Próximo desenvolvimento:
→ Tenant
```

Esta documentação deve ser revisada ao final da implementação do módulo Tenant.
