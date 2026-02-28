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
    SELECT * FROM {{ source('core_banking', 'credit_bureau') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
logical AS (
    SELECT
        bureau_record_id,
        
        -- Enmascaramos el ID fiscal que viene del buró externo
        {{ mask_pii('tax_id') }} AS tax_id_hashed,
        
        credit_score,
        number_of_open_trades,
        total_outstanding_debt,
        delinquency_history,
        report_date
    FROM import
),

-- ============================================================================
-- 3. VALIDATION CTE
-- ============================================================================
validation AS (
    SELECT
        *,
        CASE 
            WHEN length(tax_id_hashed) = 0 THEN 'Missing Tax ID in Bureau'
            WHEN credit_score IS NULL OR credit_score < 0 THEN 'Invalid Credit Score'
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
