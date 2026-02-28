-- ============================================================================
-- Databricks Lakehouse - Initial Environment Setup DDL (Unity Catalog)
-- Ejecutar UNA SOLA VEZ por ambiente antes de dbt.
--
-- Este script prepara:
--   - Catálogo
--   - Schemas (bronze, silver, gold, audit_logs)
--   - Tablas RAW
--   - Tablas Silver/Gold requeridas por negocio
--   - Infraestructura de auditoría
--
-- IMPORTANTE:
-- El catálogo puede parametrizarse por ambiente:
--   lakehouse_dev
--   lakehouse_qa
--   lakehouse_prod
--
-- Se recomienda automatizar vía Job parameter / CI-CD.
-- ============================================================================

-- ============================================================
-- 0) Selección del catálogo del ambiente
-- ============================================================

-- USE CATALOG lakehouse_dev;  -- Desarrollo
-- USE CATALOG lakehouse_qa;   -- QA / Certificación
USE CATALOG lakehouse_prod;    -- Producción

-- NOTA:
-- Puede parametrizarse dinámicamente desde:
--   - Databricks Job
--   - dbutils.widgets
--   - GitHub Actions
--   - Terraform
-- ============================================================


-- ============================================================
-- 1) Schemas por capa
-- ============================================================

CREATE SCHEMA IF NOT EXISTS bronze
COMMENT 'Capa RAW para aterrizaje masivo de fuentes';

CREATE SCHEMA IF NOT EXISTS silver
COMMENT 'Capa Silver curada y enmascarada (PCI-DSS)';

CREATE SCHEMA IF NOT EXISTS gold
COMMENT 'Data Marts estratégicos (LTV, Churn, Advanced Analytics)';

CREATE SCHEMA IF NOT EXISTS audit_logs
COMMENT 'Observabilidad operativa y auditoría de ejecuciones dbt';


-- ============================================================
-- 2) Tablas de Auditoría (usadas por hooks dbt)
-- ============================================================

CREATE TABLE IF NOT EXISTS audit_logs.dbt_run_log (
    run_id          STRING,
    start_time      TIMESTAMP,
    end_time        TIMESTAMP,
    status          STRING,
    target_name     STRING,
    git_sha         STRING
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS audit_logs.dbt_model_log (
    run_id           STRING,
    model_name       STRING,
    rows_processed   BIGINT,
    rows_rejected    BIGINT,
    execution_time   TIMESTAMP,
    target_name      STRING,
    git_sha          STRING,
    status           STRING,
    error_message    STRING
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);


-- ============================================================
-- 3) Fuentes RAW (Bronze)
-- Simulación de Auto Loader / COPY INTO
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.customers (
    customer_id     STRING,
    first_name      STRING,
    last_name       STRING,
    date_of_birth   STRING,
    tax_id          STRING,
    email           STRING,
    phone_number    STRING,
    created_at      TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS bronze.active_products (
    product_id        STRING,
    customer_id       STRING,
    product_type      STRING,
    principal_amount  DOUBLE,
    interest_rate     DOUBLE,
    term_months       INT,
    origination_date  DATE,
    status            STRING
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS bronze.passive_products (
    account_id        STRING,
    customer_id       STRING,
    account_type      STRING,
    current_balance   DOUBLE,
    currency          STRING,
    open_date         DATE,
    status            STRING
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

-- IMPORTANTE:
-- NO particionar por TIMESTAMP (alta cardinalidad).
-- Se crea columna DATE derivada para partición eficiente.
CREATE TABLE IF NOT EXISTS bronze.transactions (
    transaction_id        STRING,
    customer_id           STRING,
    account_id            STRING,
    amount                DOUBLE,
    currency              STRING,
    transaction_date      TIMESTAMP,
    transaction_date_dt   DATE,
    transaction_type      STRING,
    card_number           STRING
)
USING DELTA
PARTITIONED BY (transaction_date_dt)
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS bronze.credit_bureau (
    bureau_record_id          STRING,
    tax_id                    STRING,
    credit_score              INT,
    number_of_open_trades     INT,
    total_outstanding_debt    DOUBLE,
    delinquency_history       STRING,
    report_date               DATE
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);


-- ============================================================
-- 4) STAGING VIEWS (Passthrough físico requerido por negocio)
-- ============================================================

CREATE OR REPLACE VIEW bronze.stg_customers_v        AS SELECT * FROM bronze.customers;
CREATE OR REPLACE VIEW bronze.stg_active_products_v  AS SELECT * FROM bronze.active_products;
CREATE OR REPLACE VIEW bronze.stg_passive_products_v AS SELECT * FROM bronze.passive_products;
CREATE OR REPLACE VIEW bronze.stg_transactions_v     AS SELECT * FROM bronze.transactions;
CREATE OR REPLACE VIEW bronze.stg_credit_bureau_v    AS SELECT * FROM bronze.credit_bureau;


-- ============================================================
-- 5) Silver (Curada / Enmascarada)
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.int_transactions (
    transaction_id        STRING,
    customer_id           STRING,
    account_id            STRING,
    amount_usd            DOUBLE,
    transaction_date      TIMESTAMP,
    transaction_date_dt   DATE,
    transaction_type      STRING,
    card_number_hashed    STRING,
    loaded_at             TIMESTAMP
)
USING DELTA
PARTITIONED BY (transaction_date_dt)
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS silver.int_transactions_rej (
    transaction_id        STRING,
    customer_id           STRING,
    rejection_reason      STRING,
    attempted_amount      DOUBLE,
    transaction_date      TIMESTAMP,
    transaction_date_dt   DATE,
    rejected_at           TIMESTAMP
)
USING DELTA
PARTITIONED BY (transaction_date_dt)
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);


-- ============================================================
-- 6) Gold (Data Marts Estratégicos)
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_customers (
    customer_id              STRING,
    first_name               STRING,
    last_name                STRING,
    date_of_birth            STRING,
    customer_since           TIMESTAMP,
    credit_score             INT,
    total_outstanding_debt   DOUBLE,
    delinquency_history      STRING,
    bureau_report_date       DATE
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS gold.dim_accounts (
    account_id        STRING,
    customer_id       STRING,
    account_type      STRING,
    currency          STRING,
    open_date         DATE,
    account_status    STRING,
    current_balance   DOUBLE
)
USING DELTA
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

CREATE TABLE IF NOT EXISTS gold.fct_transactions (
    transaction_id        STRING,
    transaction_date      TIMESTAMP,
    transaction_date_dt   DATE,
    customer_id           STRING,
    account_id            STRING,
    transaction_type      STRING,
    amount_usd            DOUBLE,
    is_high_value_tx      BOOLEAN
)
USING DELTA
PARTITIONED BY (transaction_date_dt)
TBLPROPERTIES (
    delta.autoOptimize.optimizeWrite = true,
    delta.autoOptimize.autoCompact   = true
);

-- Placeholder MV (dbt la reemplazará)
CREATE MATERIALIZED VIEW IF NOT EXISTS gold.dim_customer_360_value
COMMENT 'Pre-deployment placeholder; dbt will populate and refresh'
AS
SELECT 'Pre-deployment DDL placeholder - to be populated by dbt' AS status;


-- ============================================================
-- 7) Vistas lógicas de abstracción BI
-- ============================================================

CREATE OR REPLACE VIEW silver.int_transactions_v AS
SELECT * FROM silver.int_transactions;

CREATE OR REPLACE VIEW gold.dim_customers_v AS
SELECT * FROM gold.dim_customers;

CREATE OR REPLACE VIEW gold.dim_accounts_v AS
SELECT * FROM gold.dim_accounts;

CREATE OR REPLACE VIEW gold.fct_transactions_v AS
SELECT * FROM gold.fct_transactions;

-- ============================================================
-- Fin de Setup Completo.
-- Posteriormente ejecutar: dbt build
-- ============================================================