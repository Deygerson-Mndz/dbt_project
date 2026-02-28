{{
    config(
        materialized='incremental',
        partition_by='transaction_date',
        incremental_strategy='insert_overwrite',
        unique_key='transaction_id',
        tags=["gold", "fact"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTE
-- ============================================================================
WITH transactions AS (
    -- Importamos SOLO las transacciones válidas desde la capa Silver
    SELECT * FROM {{ ref('int_transactions') }}
    {% if is_incremental() %}
        WHERE transaction_date >= (SELECT MAX(transaction_date) FROM {{ this }})
    {% endif %}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
enriched_transactions AS (
    SELECT
        t.transaction_id,
        t.transaction_date,
        t.customer_id,
        t.account_id,
        t.transaction_type,
        t.amount_usd,
        
        -- Dimension Keys (si tuviéramos surrogate keys, se cruzarían aquí)
        -- En este modelo Lakehouse utilizamos los natural keys.
        
        -- Métricas derivadas preparadas para PowerBI / Looker
        CASE WHEN t.amount_usd > 10000 THEN TRUE ELSE FALSE END AS is_high_value_tx
    FROM transactions t
)

-- ============================================================================
-- 3. FINAL CTE
-- ============================================================================
SELECT * FROM enriched_transactions
