-- ============================================================
-- SCHEMA: core
-- TABLE: core.tenants
--
-- Tenants do ERP.
--
-- Regras:
--   1. Deve existir no máximo um tenant MASTER.
--   2. O tenant MASTER é o tenant central "SISTEMA DE ERP".
--   3. SuperUsers pertencem exclusivamente ao tenant MASTER.
--   4. Tenants normais representam empresas clientes do ERP.
--   5. Exclusão lógica através de deleted_at.
--   6. Alterações são registradas pelo mecanismo de auditoria.
-- ============================================================

CREATE TABLE IF NOT EXISTS core.tenants
(
    tenant_id bigint
        GENERATED ALWAYS AS IDENTITY
        (
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 9223372036854775807
            CACHE 1
        )
        NOT NULL,

    tenant_uuid uuid
        NOT NULL
        DEFAULT gen_random_uuid(),

    -- ========================================================
    -- Identificação
    -- ========================================================

    legal_name varchar(200)
        NOT NULL,

    trade_name varchar(150),

    tax_id varchar(20)
        NOT NULL,

    state_registration varchar(30),

    municipal_registration varchar(30),

    -- ========================================================
    -- Classificação do tenant
    -- ========================================================

    -- TRUE  = tenant MASTER do sistema
    -- FALSE = tenant normal
    --
    -- Deve existir no máximo um TRUE.
    -- A regra de unicidade é garantida por índice parcial.
    is_master boolean
        NOT NULL
        DEFAULT false,

    -- ========================================================
    -- Contatos
    -- ========================================================

    email varchar(150),

    phone varchar(20),

    mobile_phone varchar(20),

    website_url varchar(255),

    logo_url varchar(500),

    -- ========================================================
    -- Configurações regionais
    -- ========================================================

    timezone varchar(50)
        NOT NULL
        DEFAULT 'America/Sao_Paulo',

    currency_code char(3)
        NOT NULL
        DEFAULT 'BRL',

    locale_code varchar(10)
        NOT NULL
        DEFAULT 'pt-BR',

    -- ========================================================
    -- Status
    -- ========================================================

    status varchar(20)
        NOT NULL
        DEFAULT 'ACTIVE',

    -- ========================================================
    -- Auditoria / controle de ciclo de vida
    -- ========================================================

    created_at timestamptz
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamptz
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    deleted_at timestamptz,

    -- ========================================================
    -- Constraints
    -- ========================================================

    CONSTRAINT pk_tenants
        PRIMARY KEY (tenant_id),

    CONSTRAINT uq_tenants_tax_id
        UNIQUE (tax_id),

    CONSTRAINT uq_tenants_uuid
        UNIQUE (tenant_uuid),

    CONSTRAINT chk_tenants_status
        CHECK
        (
            status IN
            (
                'ACTIVE',
                'INACTIVE',
                'SUSPENDED'
            )
        )
);

-- ============================================================
-- Índice: garante que exista no máximo um MASTER.
--
-- PostgreSQL permite vários FALSE, mas somente um TRUE.
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_tenants_single_master
    ON core.tenants (is_master)
    WHERE is_master = TRUE;


-- ============================================================
-- Índices auxiliares
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_tenants_status
    ON core.tenants (status);

CREATE INDEX IF NOT EXISTS idx_tenants_deleted_at
    ON core.tenants (deleted_at);

CREATE INDEX IF NOT EXISTS idx_tenants_is_master
    ON core.tenants (is_master);


-- ============================================================
-- Ownership
-- ============================================================

ALTER TABLE core.tenants
    OWNER TO postgres;


-- ============================================================
-- Permissões
-- ============================================================

GRANT ALL ON TABLE core.tenants TO admin_erp;

GRANT ALL ON TABLE core.tenants TO postgres;


-- ============================================================
-- Auditoria
-- ============================================================

DROP TRIGGER IF EXISTS trg_audit_tenants
    ON core.tenants;

CREATE OR REPLACE TRIGGER trg_audit_tenants
    AFTER INSERT OR UPDATE OR DELETE
    ON core.tenants
    FOR EACH ROW
    EXECUTE FUNCTION core.audit_trigger('tenant_id');