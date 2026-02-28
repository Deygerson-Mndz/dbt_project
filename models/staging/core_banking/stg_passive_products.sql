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
    SELECT * FROM {{ source('core_banking', 'passive_products') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
logical AS (
    SELECT
        account_id,
        customer_id,
        account_type,     -- Ej. 'SAVINGS', 'CHECKING'
        current_balance,
        currency,
        open_date,
        status AS account_status
    FROM import
),

-- ============================================================================
-- 3. VALIDATION CTE
-- ============================================================================
validation AS (
    SELECT
        *,
        CASE 
            WHEN account_id IS NULL THEN 'Missing Account ID'
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
