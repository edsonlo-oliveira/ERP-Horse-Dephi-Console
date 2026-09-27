# Controle de Acesso — Perfis e Permissões (ERP Delphi)

Documento de referência do modelo de autorização baseado em **Perfis** (Profiles)
com permissões granulares por recurso/tela. Consolida as decisões tomadas e o
DDL completo do módulo `core` responsável por isso.

---

## 1. Contexto e decisões

- Existem 3 tipos de usuário no sistema: **SuperUser** (só no tenant master,
  acesso a todos os tenants, ignora toda a matriz de permissões), **Administrador
  de tenant** e **Usuário comum** — sendo que ADMIN e USER deixaram de ser uma
  flag fixa e passaram a ser resultado de **Perfis** com permissões configuráveis.
- Cada tela/funcionalidade do ERP (Estoque → Produtos, Categorias, Armazéns, etc.)
  é um **Resource** cadastrado no sistema, organizado em hierarquia
  (módulo → funcionalidade). Só o SuperUser cadastra/edita Resources.
- Cada **Profile** pertence a um tenant (ou é global — ver abaixo) e define, por
  Resource, quatro permissões: `can_view`, `can_create`, `can_edit`, `can_delete`.
- Um usuário tem **exatamente um** Profile (`core.users.profile_id`), não é
  many-to-many.
- A checagem de permissão é feita **em tempo real** (query no banco a cada
  request), não vai dentro do JWT. O JWT carrega só identidade/contexto
  (`user_id`, `tenant_id`, `super_user`).
- **Perfis de sistema** (`is_system_profile = true`, `tenant_id NULL`) existem
  para servir de padrão pronto (ex.: "Vendedor", "Financeiro Básico") e são
  **referenciados diretamente** por usuários de qualquer tenant — não são
  clonados por padrão. Vantagem: o SuperUser edita um perfil de sistema uma
  vez e a mudança vale para todo mundo que o usa, sem precisar propagar
  update para N tenants.
- Um tenant pode, opcionalmente, **clonar** um perfil de sistema para ter uma
  cópia própria e editável (`core.clone_profile_from_template`) — usado quando
  o Admin quer partir de um padrão e depois customizar.
- **Decisão fechada:** um Admin de tenant **não pode editar um perfil de
  sistema diretamente**. Para mudar qualquer permissão, ele precisa migrar o
  usuário para um perfil próprio do tenant (clonado ou criado do zero). Não
  existe copy-on-write automático/silencioso.
- Regra de tenant × perfil: um usuário só pode usar (a) um perfil de sistema
  (qualquer tenant) ou (b) um perfil que pertence exatamente ao seu próprio
  tenant. Isso é garantido por uma trigger de validação (não dá pra expressar
  com uma FK simples, porque teria que ser uma condição "OU").
- "Ser Administrador" deixou de ser uma coluna: é simplesmente ter
  `can_create/can_edit/can_delete = true` no Resource `Users` e no Resource
  `Profiles` dentro do próprio perfil.

### Em aberto (ainda não decidido)

- Se a regra "Admin não edita perfil de sistema" deve ser garantida também no
  banco (trigger em `core.profile_permissions`/`core.profiles` barrando UPDATE/
  DELETE quando `is_system_profile = true` e o executor não é SuperUser,
  usando a mesma variável de sessão `app.tenant_id`/`app.is_super_user` já
  usada para RLS), ou se fica só na camada de aplicação (Delphi Service).

---

## 2. Modelo de dados (visão geral)

```
core.tenants
    │ 1
    │
    │ N
core.users ────────────────┐
    │ N            profile_id (nullable)
    │                        │
    │                        ▼
    │                core.profiles  (tenant_id nullable; is_system_profile)
    │                        │ 1
    │                        │
    │                        │ N
    │                core.profile_permissions
    │                        │ N
    │                        │
    │                        │ 1
    │                core.resources (hierárquico via parent_resource_id)
```

- `core.profiles.tenant_id` **NULL** ⇒ perfil de sistema (global).
- `core.profiles.tenant_id` **preenchido** ⇒ perfil próprio daquele tenant.
- `core.resources` é hierárquico: um resource "Estoque" (módulo, `parent_resource_id
  NULL`) é pai de "Produtos", "Categorias", "Armazéns" (`parent_resource_id` = id
  do Estoque).

---

## 3. DDL completo

### 3.1 `core.resources` — catálogo de módulos/telas

```sql
CREATE TABLE IF NOT EXISTS core.resources
(
    resource_id        bigint NOT NULL GENERATED ALWAYS AS IDENTITY
                            (INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1),
    resource_uuid       uuid NOT NULL DEFAULT gen_random_uuid(),
    parent_resource_id  bigint,
    resource_key        character varying(120) COLLATE pg_catalog."default" NOT NULL, -- ex: 'inventory.products'
    display_name        character varying(120) COLLATE pg_catalog."default" NOT NULL,
    description         text,
    is_active           boolean NOT NULL DEFAULT true,
    created_at          timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          timestamp with time zone,
    CONSTRAINT pk_resources PRIMARY KEY (resource_id),
    CONSTRAINT uq_resources_uuid UNIQUE (resource_uuid),
    CONSTRAINT fk_resources_parent FOREIGN KEY (parent_resource_id)
        REFERENCES core.resources (resource_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE RESTRICT
);

-- resource_key único apenas entre registros vivos (padrão soft-delete)
CREATE UNIQUE INDEX IF NOT EXISTS uq_resources_key_active
    ON core.resources (resource_key)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_resources_parent
    ON core.resources (parent_resource_id);

CREATE OR REPLACE TRIGGER trg_audit_resources
    AFTER INSERT OR DELETE OR UPDATE
    ON core.resources
    FOR EACH ROW
    EXECUTE FUNCTION core.audit_trigger('resource_id');

GRANT ALL ON TABLE core.resources TO admin_erp;
GRANT ALL ON TABLE core.resources TO postgres;
```

### 3.2 `core.profiles` — perfis (de sistema ou de tenant)

```sql
CREATE TABLE IF NOT EXISTS core.profiles
(
    profile_id          bigint NOT NULL GENERATED ALWAYS AS IDENTITY
                             (INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1),
    profile_uuid         uuid NOT NULL DEFAULT gen_random_uuid(),
    tenant_id            bigint,                       -- NULL = perfil de sistema (global)
    name                 character varying(80) COLLATE pg_catalog."default" NOT NULL,
    description          text,
    is_system_profile    boolean NOT NULL DEFAULT false, -- true = mantido só pelo SuperUser, usável por qualquer tenant
    source_template_id   bigint,                        -- se foi clonado de um perfil de sistema, guarda a origem
    is_active            boolean NOT NULL DEFAULT true,
    created_at           timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at           timestamp with time zone,
    CONSTRAINT pk_profiles PRIMARY KEY (profile_id),
    CONSTRAINT uq_profiles_uuid UNIQUE (profile_uuid),
    CONSTRAINT fk_profiles_tenant FOREIGN KEY (tenant_id)
        REFERENCES core.tenants (tenant_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_profiles_source_template FOREIGN KEY (source_template_id)
        REFERENCES core.profiles (profile_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT chk_profiles_system_tenant_consistency CHECK (
        (is_system_profile = true  AND tenant_id IS NULL)
        OR
        (is_system_profile = false AND tenant_id IS NOT NULL)
    )
);

-- nome único por tenant, entre perfis vivos
CREATE UNIQUE INDEX IF NOT EXISTS uq_profiles_tenant_name_active
    ON core.profiles (tenant_id, name)
    WHERE deleted_at IS NULL AND is_system_profile = false;

-- nome único entre perfis de sistema vivos
CREATE UNIQUE INDEX IF NOT EXISTS uq_profiles_system_name_active
    ON core.profiles (name)
    WHERE deleted_at IS NULL AND is_system_profile = true;

CREATE INDEX IF NOT EXISTS ix_profiles_is_system
    ON core.profiles (is_system_profile)
    WHERE is_system_profile = true;

CREATE INDEX IF NOT EXISTS ix_profiles_source_template
    ON core.profiles (source_template_id)
    WHERE source_template_id IS NOT NULL;

CREATE OR REPLACE TRIGGER trg_audit_profiles
    AFTER INSERT OR DELETE OR UPDATE
    ON core.profiles
    FOR EACH ROW
    EXECUTE FUNCTION core.audit_trigger('profile_id');

GRANT ALL ON TABLE core.profiles TO admin_erp;
GRANT ALL ON TABLE core.profiles TO postgres;
```

### 3.3 `core.profile_permissions` — matriz de permissões

```sql
CREATE TABLE IF NOT EXISTS core.profile_permissions
(
    profile_id   bigint NOT NULL,
    resource_id  bigint NOT NULL,
    can_view     boolean NOT NULL DEFAULT false,
    can_create   boolean NOT NULL DEFAULT false,
    can_edit     boolean NOT NULL DEFAULT false,
    can_delete   boolean NOT NULL DEFAULT false,
    created_at   timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_profile_permissions PRIMARY KEY (profile_id, resource_id),
    CONSTRAINT fk_profile_permissions_profile FOREIGN KEY (profile_id)
        REFERENCES core.profiles (profile_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_profile_permissions_resource FOREIGN KEY (resource_id)
        REFERENCES core.resources (resource_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_profile_permissions_resource
    ON core.profile_permissions (resource_id);

CREATE OR REPLACE TRIGGER trg_audit_profile_permissions
    AFTER INSERT OR DELETE OR UPDATE
    ON core.profile_permissions
    FOR EACH ROW
    EXECUTE FUNCTION core.audit_trigger('profile_id');

GRANT ALL ON TABLE core.profile_permissions TO admin_erp;
GRANT ALL ON TABLE core.profile_permissions TO postgres;
```

### 3.4 `core.users` — vínculo com o perfil

```sql
ALTER TABLE core.users
    ADD COLUMN IF NOT EXISTS profile_id bigint;

ALTER TABLE core.users
    ADD CONSTRAINT fk_users_profile FOREIGN KEY (profile_id)
        REFERENCES core.profiles (profile_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION;

CREATE INDEX IF NOT EXISTS ix_users_profile_id
    ON core.users (profile_id);
```

#### Trigger de consistência tenant × perfil

Uma FK simples não impede um usuário de apontar para o perfil de outro
tenant. Como perfil de sistema (`tenant_id NULL`) precisa ser aceito por
qualquer tenant, e perfil de tenant só pode ser usado pelo próprio tenant,
essa regra "OU" é resolvida com uma trigger:

```sql
CREATE OR REPLACE FUNCTION core.fn_validate_user_profile_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_profile_tenant_id  bigint;
    v_is_system_profile  boolean;
BEGIN
    IF NEW.profile_id IS NULL THEN
        RETURN NEW; -- ex.: SuperUser sem perfil, ou usuário ainda não configurado
    END IF;

    SELECT tenant_id, is_system_profile
      INTO v_profile_tenant_id, v_is_system_profile
      FROM core.profiles
     WHERE profile_id = NEW.profile_id
       AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Perfil % não existe ou está inativo', NEW.profile_id;
    END IF;

    IF v_is_system_profile THEN
        RETURN NEW; -- perfil global: qualquer tenant pode usar
    END IF;

    IF v_profile_tenant_id IS DISTINCT FROM NEW.tenant_id THEN
        RAISE EXCEPTION
            'Perfil % pertence ao tenant %, não pode ser atribuído a usuário do tenant %',
            NEW.profile_id, v_profile_tenant_id, NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_user_profile_tenant ON core.users;

CREATE TRIGGER trg_validate_user_profile_tenant
    BEFORE INSERT OR UPDATE OF profile_id, tenant_id
    ON core.users
    FOR EACH ROW
    EXECUTE FUNCTION core.fn_validate_user_profile_tenant();
```

### 3.5 Função opcional: clonar um perfil de sistema

Usada quando um tenant quer partir de um perfil de sistema e depois
customizar de forma independente (o clone não tem mais nenhum vínculo vivo
com o original — só o `source_template_id` como rastro histórico).

```sql
CREATE OR REPLACE FUNCTION core.clone_profile_from_template(
    p_template_id bigint,
    p_tenant_id   bigint,
    p_new_name    character varying DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_profile_id  bigint;
    v_template_exists boolean;
BEGIN
    SELECT true INTO v_template_exists
      FROM core.profiles
     WHERE profile_id = p_template_id
       AND is_system_profile = true
       AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Perfil de sistema % não encontrado ou inativo', p_template_id;
    END IF;

    INSERT INTO core.profiles (tenant_id, name, description, is_system_profile, source_template_id)
    SELECT p_tenant_id, COALESCE(p_new_name, name), description, false, profile_id
      FROM core.profiles
     WHERE profile_id = p_template_id
    RETURNING profile_id INTO v_new_profile_id;

    INSERT INTO core.profile_permissions (profile_id, resource_id, can_view, can_create, can_edit, can_delete)
    SELECT v_new_profile_id, resource_id, can_view, can_create, can_edit, can_delete
      FROM core.profile_permissions
     WHERE profile_id = p_template_id;

    RETURN v_new_profile_id;
END;
$$;
```

---

## 4. Query de checagem de permissão

Usada pelo middleware/Service de autorização a cada request (exceto quando
`core.users.super_user = true`, que ignora essa checagem inteira):

```sql
SELECT pp.can_view, pp.can_create, pp.can_edit, pp.can_delete
  FROM core.users u
  JOIN core.profile_permissions pp ON pp.profile_id = u.profile_id
  JOIN core.resources r ON r.resource_id = pp.resource_id
 WHERE u.user_id = :user_id
   AND r.resource_key = :resource_key   -- ex: 'inventory.products'
   AND r.deleted_at IS NULL;
```

Essa query é a mesma independente de o perfil ser de sistema ou do tenant —
o service de autorização não precisa distinguir os dois casos.

---

## 5. Fluxos de uso

- **Onboarding de um tenant novo:** não precisa cadastrar nada em `profiles`
  necessariamente — os usuários já podem ser criados apontando direto para
  perfis de sistema existentes.
- **Admin quer ajustar uma permissão de um perfil de sistema:** não pode
  editar o perfil de sistema. Deve chamar `core.clone_profile_from_template`
  (ou criar um perfil do zero), migrar o(s) usuário(s) para o novo perfil, e
  então editar a cópia.
- **Admin cria um perfil totalmente novo:** insere direto em `core.profiles`
  com `tenant_id` do seu tenant e `is_system_profile = false`, depois popula
  `core.profile_permissions`.
- **SuperUser atualiza um perfil de sistema:** um `UPDATE` em
  `core.profile_permissions` já vale, em tempo real, para todos os tenants
  que usam aquele perfil por referência direta.
