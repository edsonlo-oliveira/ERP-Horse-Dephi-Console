#core.inactive_reasons

## INSERT
BEGIN;

SELECT
    set_config('app.user_id', '2', true),
    set_config('app.tenant_id', '1', true);

INSERT INTO core.inactive_reasons
(
    domain,
    code,
    description
)
VALUES
(
    'USER',
    'BLOCKED',
    'Bloqueado'
);

COMMIT;
