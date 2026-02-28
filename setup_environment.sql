-- ============================================================================
-- Databricks Lakehouse - Initial Environment Setup DDL
-- Objetivo: Ejecutar una ÚNICA VEZ antes de iniciar dbt para preparar los 
-- catálogos, esquemas (databases) y las tablas físicas iniciales de aterrizaje 
-- (Bronze/RAW) y de auditoría.
-- ============================================================================

-- 1. Creación de la base de datos de aterrizaje e ingesta bruta (Bronze)
CREATE DATABASE IF NOT EXISTS lakehouse_prod.bronze
COMMENT 'Capa RAW para aterrizaje masivo de fuentes';

-- 2. Creación de las bases analíticas (Silver / Gold manejadas por dbt)
-- Aunque dbt puede crearlas al vuelo, aseguramos su existencia física
CREATE DATABASE IF NOT EXISTS lakehouse_prod.silver
COMMENT 'Capa Silver curada y enmascarada (PCI-DSS)';

CREATE DATABASE IF NOT EXISTS lakehouse_prod.gold
COMMENT 'Data Marts estratégicos (LTV, Churn, Models)';

CREATE DATABASE IF NOT EXISTS audit_logs
COMMENT 'Base dedicada para observabilidad operativa de dbt';

-- 3. Tabla de Auditoría Operativa (Requerida por los hooks de dbt_project.yml)
CREATE TABLE IF NOT EXISTS audit_logs.dbt_run_log (
    run_id STRING,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS audit_logs.dbt_model_log (
    run_id STRING,
    model_name STRING,
    rows_processed BIGINT,
    rows_rejected BIGINT,
    execution_time TIMESTAMP
) USING DELTA;

-- ============================================================================
-- 4. Creación de las 5 Fuentes Físicas Raw (Simulación de Auto Loader / COPY INTO)
-- Estas tablas sirven de base para el _sources.yml (core_banking) de dbt
-- ============================================================================

CREATE TABLE IF NOT EXISTS lakehouse_prod.bronze.customers (
    customer_id STRING,
    first_name STRING,
    last_name STRING,
    date_of_birth STRING,
    tax_id STRING,
    email STRING,
    phone_number STRING,
    created_at TIMESTAMP
) USING DELTA
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true', 'delta.autoOptimize.autoCompact' = 'true');

CREATE TABLE IF NOT EXISTS lakehouse_prod.bronze.active_products (
    product_id STRING,
    customer_id STRING,
    product_type STRING,
    principal_amount DOUBLE,
    interest_rate DOUBLE,
    term_months INT,
    origination_date DATE,
    status STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS lakehouse_prod.bronze.passive_products (
    account_id STRING,
    customer_id STRING,
    account_type STRING,
    current_balance DOUBLE,
    currency STRING,
    open_date DATE,
    status STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS lakehouse_prod.bronze.transactions (
    transaction_id STRING,
    customer_id STRING,
    account_id STRING,
    amount DOUBLE,
    currency STRING,
    transaction_date TIMESTAMP,
    transaction_type STRING,
    card_number STRING
) USING DELTA
PARTITIONED BY (transaction_date) -- En RAW se respeta el partition clásico como bucket de llegada
TBLPROPERTIES ('delta.autoOptimize.optimizeWrite' = 'true');

CREATE TABLE IF NOT EXISTS lakehouse_prod.bronze.credit_bureau (
    bureau_record_id STRING,
    tax_id STRING,
    credit_score INT,
    number_of_open_trades INT,
    total_outstanding_debt DOUBLE,
    delinquency_history STRING,
    report_date DATE
) USING DELTA;

-- Fin de Setup Mínimo Viable.

-- ============================================================================
-- 5. Creación de las Tablas e Infraestructura Silver y Gold
-- Aunque en un entorno dbt puro, dbt crea esto "al vuelo", por requerimiento 
-- del negocio se exige la pre-existencia del DDL físico para el producto de datos.
-- ============================================================================

-- STAGING (Vistas sobre Bronze)
CREATE OR REPLACE VIEW lakehouse_prod.bronze.stg_customers_v AS
    SELECT * FROM lakehouse_prod.bronze.customers;
CREATE OR REPLACE VIEW lakehouse_prod.bronze.stg_active_products_v AS
    SELECT * FROM lakehouse_prod.bronze.active_products;
CREATE OR REPLACE VIEW lakehouse_prod.bronze.stg_passive_products_v AS
    SELECT * FROM lakehouse_prod.bronze.passive_products;
CREATE OR REPLACE VIEW lakehouse_prod.bronze.stg_transactions_v AS
    SELECT * FROM lakehouse_prod.bronze.transactions;
CREATE OR REPLACE VIEW lakehouse_prod.bronze.stg_credit_bureau_v AS
    SELECT * FROM lakehouse_prod.bronze.credit_bureau;

-- SILVER (Curada y Enmascarada)
CREATE TABLE IF NOT EXISTS lakehouse_prod.silver.int_transactions (
    transaction_id STRING,
    customer_id STRING,
    account_id STRING,
    amount_usd DOUBLE,
    transaction_date TIMESTAMP,
    transaction_type STRING,
    card_number_hashed STRING,
    loaded_at TIMESTAMP
) USING DELTA
PARTITIONED BY (transaction_date);

CREATE TABLE IF NOT EXISTS lakehouse_prod.silver.int_transactions_rej (
    transaction_id STRING,
    customer_id STRING,
    rejection_reason STRING,
    attempted_amount DOUBLE,
    transaction_date TIMESTAMP,
    rejected_at TIMESTAMP
) USING DELTA
PARTITIONED BY (transaction_date);

-- GOLD (Data Marts Estratégicos y LTV)
CREATE TABLE IF NOT EXISTS lakehouse_prod.gold.dim_customers (
    customer_id STRING,
    first_name STRING,
    last_name STRING,
    date_of_birth STRING,
    customer_since TIMESTAMP,
    credit_score INT,
    total_outstanding_debt DOUBLE,
    delinquency_history STRING,
    bureau_report_date DATE
) USING DELTA;

CREATE TABLE IF NOT EXISTS lakehouse_prod.gold.dim_accounts (
    account_id STRING,
    customer_id STRING,
    account_type STRING,
    currency STRING,
    open_date DATE,
    account_status STRING,
    current_balance DOUBLE
) USING DELTA;

CREATE TABLE IF NOT EXISTS lakehouse_prod.gold.fct_transactions (
    transaction_id STRING,
    transaction_date TIMESTAMP,
    customer_id STRING,
    account_id STRING,
    transaction_type STRING,
    amount_usd DOUBLE,
    is_high_value_tx BOOLEAN
) USING DELTA
PARTITIONED BY (transaction_date);

-- Vistas Materializadas para Looker/Power BI (< 2s)
CREATE MATERIALIZED VIEW IF NOT EXISTS lakehouse_prod.gold.dim_customer_360_value AS 
SELECT 'Pre-deployment DDL placeholder - to be populated by dbt' AS status;

-- Vistas Lógicas autogeneradas (BI Abstraction)
CREATE OR REPLACE VIEW lakehouse_prod.silver.int_transactions_v AS SELECT * FROM lakehouse_prod.silver.int_transactions;
CREATE OR REPLACE VIEW lakehouse_prod.gold.dim_customers_v AS SELECT * FROM lakehouse_prod.gold.dim_customers;
CREATE OR REPLACE VIEW lakehouse_prod.gold.dim_accounts_v AS SELECT * FROM lakehouse_prod.gold.dim_accounts;
CREATE OR REPLACE VIEW lakehouse_prod.gold.fct_transactions_v AS SELECT * FROM lakehouse_prod.gold.fct_transactions;

-- Fin de Setup Completo. Posterior a esto, `dbt build` poblará las tablas.
