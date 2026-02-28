{{
    config(
        materialized='view',
        tags=["staging", "pci_compliant"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTE
-- ============================================================================
WITH import AS (
    SELECT * FROM {{ source('core_banking', 'transactions') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
logical AS (
    SELECT
        transaction_id,
        customer_id,
        account_id,
        amount,
        currency,
        transaction_date,
        transaction_type,
        
        -- Seguridad PCI: Enmascaramiento del número de tarjeta de crédito (PAN)
        {{ mask_pii('card_number') }} AS card_number_hashed
        
    FROM import
),

-- ============================================================================
-- 3. VALIDATION CTE
-- ============================================================================
validation AS (
    SELECT
        *,
        CASE 
            WHEN transaction_id IS NULL THEN 'Missing Transaction ID'
            ELSE 'OK'
        END AS validation_reason
    FROM logical
),

-- ============================================================================
-- 4. FINAL CTE
-- ============================================================================
final AS (
    SELECT * FROM validation
)

SELECT * FROM final
