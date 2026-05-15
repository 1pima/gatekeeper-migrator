-- 1. Создание схем
CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS vault;
CREATE SCHEMA IF NOT EXISTS risk;
CREATE SCHEMA IF NOT EXISTS processing;
CREATE SCHEMA IF NOT EXISTS clearing;

-- ==========================================
-- SCHEMA: identity
-- ==========================================
CREATE TABLE IF NOT EXISTS identity.organization (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bin VARCHAR(12),
    name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS identity.role (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS identity.user (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    organization_id BIGINT NOT NULL,
    CONSTRAINT fk_user_organization FOREIGN KEY (organization_id) REFERENCES identity.organization(id)
);
CREATE INDEX IF NOT EXISTS idx_user_organization_id ON identity.user(organization_id);

CREATE TABLE IF NOT EXISTS identity.users_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT,
    role_id BIGINT,
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES identity.user(id),
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES identity.role(id)
);
CREATE INDEX IF NOT EXISTS idx_users_roles_user_id ON identity.users_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_users_roles_role_id ON identity.users_roles(role_id);

-- ==========================================
-- SCHEMA: catalog
-- ==========================================
CREATE TABLE IF NOT EXISTS catalog.mcc (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_name VARCHAR(255) NOT NULL
);

-- ==========================================
-- SCHEMA: vault
-- ==========================================
CREATE TABLE IF NOT EXISTS vault.card (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pan TEXT NOT NULL,
    exp_date TEXT NOT NULL,
    encrypted_dek_key TEXT NOT NULL,
    hash TEXT NOT NULL,
    mask TEXT NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    description TEXT,
    user_id BIGINT NOT NULL,
    CONSTRAINT fk_card_user FOREIGN KEY (user_id) REFERENCES identity.user(id)
);
CREATE INDEX IF NOT EXISTS idx_card_user_id ON vault.card(user_id);
CREATE INDEX IF NOT EXISTS idx_card_hash ON vault.card(hash);

CREATE TABLE IF NOT EXISTS vault.token (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dpan TEXT NOT NULL,
    exp_date TEXT NOT NULL,
    encrypted_dek_key TEXT NOT NULL,
    hash TEXT NOT NULL,
    mask TEXT NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    description TEXT,
    user_id BIGINT NOT NULL,
    card_id BIGINT NOT NULL,
    CONSTRAINT fk_token_user FOREIGN KEY (user_id) REFERENCES identity.user(id),
    -- ИСПРАВЛЕН БАГ: теперь ссылка идет на vault.card(id), а не identity.user(id)
    CONSTRAINT fk_token_card FOREIGN KEY (card_id) REFERENCES vault.card(id)
);
CREATE INDEX IF NOT EXISTS idx_token_user_id ON vault.token(user_id);
CREATE INDEX IF NOT EXISTS idx_token_card_id ON vault.token(card_id);
CREATE INDEX IF NOT EXISTS idx_token_hash ON vault.token(hash);

-- ==========================================
-- SCHEMA: risk
-- ==========================================
CREATE TABLE IF NOT EXISTS risk.limits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    amount NUMERIC(15, 2) NOT NULL,
    date_start TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    date_end TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    period_type INTEGER NOT NULL,
    mcc_id BIGINT NOT NULL,
    token_id BIGINT NOT NULL,
    CONSTRAINT fk_limits_mcc FOREIGN KEY (mcc_id) REFERENCES catalog.mcc(id),
    CONSTRAINT fk_limits_token FOREIGN KEY (token_id) REFERENCES vault.token(id)
);
CREATE INDEX IF NOT EXISTS idx_limits_mcc_id ON risk.limits(mcc_id);
CREATE INDEX IF NOT EXISTS idx_limits_token_id ON risk.limits(token_id);

CREATE TABLE IF NOT EXISTS risk.accumulator (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    current_amount NUMERIC(15, 2) NOT NULL,
    current_count BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reset_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    token_id BIGINT NOT NULL,
    CONSTRAINT fk_accumulator_token FOREIGN KEY (token_id) REFERENCES vault.token(id)
);
CREATE INDEX IF NOT EXISTS idx_accumulator_token_id ON risk.accumulator(token_id);

-- ==========================================
-- SCHEMA: processing
-- ==========================================
CREATE TABLE IF NOT EXISTS processing.transaction (
    -- ИЗМЕНЕНИЕ: Тип UUID. Генерируется на уровне приложения, поэтому без DEFAULT
    id UUID PRIMARY KEY,
    reference TEXT NOT NULL,
    ext_id TEXT NOT NULL,
    type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    authorized_at TIMESTAMPTZ,
    transaction_amount NUMERIC(15, 2) NOT NULL,
    transaction_currency INTEGER NOT NULL,
    settlement_amount NUMERIC(15, 2) NOT NULL,
    settlement_currency INTEGER NOT NULL,
    bank_data JSONB DEFAULT '{}'::jsonb,
    add_info JSONB DEFAULT '{}'::jsonb,
    token_id BIGINT NOT NULL,
    mcc_id BIGINT NOT NULL,
    CONSTRAINT fk_transaction_token FOREIGN KEY (token_id) REFERENCES vault.token(id),
    CONSTRAINT fk_transaction_mcc FOREIGN KEY (mcc_id) REFERENCES catalog.mcc(id)
);
CREATE INDEX IF NOT EXISTS idx_transaction_reference ON processing.transaction(reference);
CREATE INDEX IF NOT EXISTS idx_transaction_ext_id ON processing.transaction(ext_id);
CREATE INDEX IF NOT EXISTS idx_transaction_token_id ON processing.transaction(token_id);
CREATE INDEX IF NOT EXISTS idx_transaction_created_at ON processing.transaction(created_at);

CREATE TABLE IF NOT EXISTS processing.status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    is_actual BOOLEAN DEFAULT TRUE,
    status INTEGER NOT NULL,
    code TEXT,
    message TEXT,
    description TEXT,
    transaction_id UUID NOT NULL,
    CONSTRAINT fk_sh_transaction FOREIGN KEY (transaction_id) REFERENCES processing.transaction(id)
);
CREATE INDEX IF NOT EXISTS idx_sh_transaction_id ON processing.status_history(transaction_id);
CREATE INDEX IF NOT EXISTS idx_sh_is_actual ON processing.status_history(transaction_id) WHERE is_actual = TRUE;

-- ==========================================
-- SCHEMA: clearing
-- ==========================================
CREATE TABLE IF NOT EXISTS clearing.fin_doc (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    add_info JSONB DEFAULT '{}'::jsonb
);
