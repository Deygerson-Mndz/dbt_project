{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        partition_by=['transaction_date_dt'],
        on_schema_change='append_new_columns',
        tags=['silver','rejected']
    )
}}

-- ============================================================================
-- 1. IMPORT DESDE BASE EPHEMERAL
-- ============================================================================

WITH base_validated AS (

    SELECT *
    FROM {{ ref('base_transactions_validation') }}

),

-- ============================================================================
-- 2. SOLO REGISTROS RECHAZADOS
-- ============================================================================

rejected AS (

    SELECT
        transaction_id,
        customer_id,
        validation_reason AS rejection_reason,
        amount_usd AS attempted_amount,
        normalized_transaction_date AS transaction_date,
        transaction_date_dt,
        current_timestamp() AS rejected_at

    FROM base_validated
    WHERE validation_reason != 'OK'

)

-- ============================================================================
-- 3. INCREMENTAL FILTER (evita reprocesar histórico)
-- ============================================================================

SELECT *
FROM rejected

{% if is_incremental() %}

WHERE transaction_date_dt >= (
    SELECT COALESCE(MAX(transaction_date_dt), DATE('1900-01-01'))
    FROM {{ this }}
)

{% endif %}
