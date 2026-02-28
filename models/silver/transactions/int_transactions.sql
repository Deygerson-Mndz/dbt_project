{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='transaction_id',
        partition_by=['transaction_date_dt'],
        cluster_by=['customer_id', 'transaction_date_dt'],
        on_schema_change='append_new_columns',
        tags=['silver', 'pci_compliant']
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
-- 2. SOLO REGISTROS VÁLIDOS
-- ============================================================================

valid_records AS (

    SELECT
        transaction_id,
        customer_id,
        account_id,
        amount_usd,
        normalized_transaction_date AS transaction_date,
        transaction_date_dt,
        transaction_type,
        card_number_hashed,
        record_hash,
        current_timestamp() AS loaded_at

    FROM base_validated
    WHERE validation_reason = 'OK'

)

-- ============================================================================
-- 3. INCREMENTAL FILTER INTELIGENTE
-- ============================================================================

SELECT *
FROM valid_records

{% if is_incremental() %}

WHERE transaction_date_dt >= (
    SELECT COALESCE(MAX(transaction_date_dt), DATE('1900-01-01'))
    FROM {{ this }}
)

{% endif %}