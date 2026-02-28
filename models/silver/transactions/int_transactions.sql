{{
    config(
        materialized='incremental',
        partition_by='transaction_date',
        incremental_strategy='insert_overwrite',
        unique_key='transaction_id'
    )
}}

-- ============================================================================
-- 1. IMPORT CTE (desde modelo ephemeral base para mantener todo DRY)
-- ============================================================================
WITH base_validated AS (
    SELECT * FROM {{ ref('base_transactions_validation') }}
),

-- ============================================================================
-- 2. FINAL CTE (Ingesta a Principal - Solo registros "limpios")
-- ============================================================================
final AS (
    SELECT
        transaction_id,
        customer_id,
        account_id,
        amount_usd,
        normalized_transaction_date AS transaction_date,
        transaction_type,
        card_number_hashed,
        current_timestamp() AS loaded_at
    FROM base_validated
    WHERE validation_reason = 'OK'
)

SELECT * FROM final
