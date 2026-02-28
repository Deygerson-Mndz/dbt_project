{{
    config(
        materialized='incremental',
        partition_by='transaction_date',
        incremental_strategy='insert_overwrite'
    )
}}

-- ============================================================================
-- 1. IMPORT CTE (bifurca fallos desde el mismo ephemeral base)
-- ============================================================================
WITH base_validated AS (
    SELECT * FROM {{ ref('base_transactions_validation') }}
),

-- ============================================================================
-- 2. FINAL CTE (Solo Rejecteds)
-- ============================================================================
final_rej AS (
    SELECT
        transaction_id,
        customer_id,
        -- Almacenamos el motivo del fallo y timestamp requerido
        validation_reason AS rejection_reason,
        amount_usd AS attempted_amount,
        normalized_transaction_date AS transaction_date,
        current_timestamp() AS rejected_at
    FROM base_validated
    WHERE validation_reason != 'OK'
)

SELECT * FROM final_rej
