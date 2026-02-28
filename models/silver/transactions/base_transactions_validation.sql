{{
    config(
        materialized='ephemeral'
    )
}}

-- ============================================================================
-- BASE EPHEMERAL
-- Centraliza:
--   - Normalización fecha
--   - Enmascaramiento PCI
--   - Validación Data Contract
--   - Generación de hash determinista
--
-- SUPUESTO:
-- La moneda del sistema es exclusivamente USD.
-- ============================================================================

WITH source_data AS (

    SELECT 
        transaction_id,
        customer_id,
        account_id,
        amount,
        currency,
        transaction_date,
        card_number,
        transaction_type
    FROM {{ source('core_banking', 'transactions') }}

),

-- ============================================================================
-- 1. Transformaciones Lógicas
-- ============================================================================

logical AS (

    SELECT
        transaction_id,
        customer_id,
        account_id,

        -- Moneda oficial USD (no se realiza conversión)
        amount AS amount_usd,

        -- Normalización fecha
        {{ normalize_date('transaction_date') }} AS normalized_transaction_date,

        -- Fecha derivada para partición
        CAST({{ normalize_date('transaction_date') }} AS DATE) AS transaction_date_dt,

        -- Enmascaramiento PCI
        {{ mask_pii('card_number') }} AS card_number_hashed,

        transaction_type,
        currency

    FROM source_data

),

-- ============================================================================
-- 2. Validación (Data Contracts)
-- ============================================================================

validation AS (

    SELECT
        *,

        CASE 
            WHEN transaction_id IS NULL THEN 'Transaction ID nulo'
            WHEN customer_id IS NULL THEN 'Customer ID nulo'
            WHEN amount_usd IS NULL THEN 'Monto nulo'
            WHEN amount_usd <= 0 THEN 'Monto inválido (<= 0)'
            WHEN currency <> 'USD' THEN 'Moneda no permitida'
            WHEN length(card_number_hashed) = 0 THEN 'PAN inválido'
            ELSE 'OK'
        END AS validation_reason

    FROM logical

),

-- ============================================================================
-- 3. Hash determinista (clave para merge eficiente)
-- ============================================================================

final AS (

    SELECT
        *,
        sha2(concat_ws('|',
            coalesce(transaction_id,''),
            coalesce(customer_id,''),
            coalesce(account_id,''),
            cast(amount_usd as string),
            cast(normalized_transaction_date as string),
            coalesce(transaction_type,'')
        ), 256) AS record_hash

    FROM validation

)

SELECT * FROM final