{{
    config(
        materialized='ephemeral'
    )
}}

-- ============================================================================
-- BASE EPHEMERAL: centralizamos la validación para reutilizar en main y _rej
-- ============================================================================
WITH import AS (
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
    {% if is_incremental() %}
        -- Lógica de partición masiva: Se procesan solo nuevos días
        WHERE transaction_date >= (SELECT MAX(transaction_date) FROM {{ this }})
    {% endif %}
),

logical AS (
    SELECT
        transaction_id,
        customer_id,
        account_id,
        -- Jinja para lógica DRY de moneda (Convierte a USD)
        {{ convert_currency('amount', 'currency', 'USD') }} AS amount_usd,
        
        -- Jinja para normalización de fechas
        {{ normalize_date('transaction_date') }} AS normalized_transaction_date,
        
        -- Enmascaramiento PCI para PAN de tarjeta
        {{ mask_pii('card_number') }} AS card_number_hashed,
        
        transaction_type
    FROM import
),

validation AS (
    SELECT
        *,
        -- Reglas de Data Contracts de Calidad
        CASE 
            WHEN amount_usd IS NULL THEN 'Monto nulo'
            WHEN amount_usd <= 0 THEN 'Monto inválido (<= 0)'
            WHEN length(card_number_hashed) = 0 THEN 'PAN inválido'
            ELSE 'OK'
        END AS validation_reason
    FROM logical
)

SELECT * FROM validation
