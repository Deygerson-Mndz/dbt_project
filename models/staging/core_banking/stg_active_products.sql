{{
    config(
        materialized='view',
        tags=["staging"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTE
-- ============================================================================
WITH import AS (
    SELECT * FROM {{ source('core_banking', 'active_products') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
logical AS (
    SELECT
        product_id,
        customer_id,
        product_type,     -- Ej. 'MORTGAGE', 'PERSONAL_LOAN'
        principal_amount,
        interest_rate,
        term_months,
        origination_date,
        status AS loan_status
    FROM import
),

-- ============================================================================
-- 3. VALIDATION CTE
-- ============================================================================
validation AS (
    SELECT
        *,
        CASE 
            WHEN product_id IS NULL THEN 'Missing Product ID'
            WHEN principal_amount < 0 THEN 'Negative Principal Amount'
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
