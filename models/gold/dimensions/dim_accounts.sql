{{
    config(
        materialized='table',
        tags=["gold", "dimension"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTE
-- ============================================================================
WITH passive_products AS (
    SELECT * FROM {{ ref('stg_passive_products') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
account_dim AS (
    SELECT
        account_id,
        customer_id,
        account_type,
        currency,
        open_date,
        account_status,
        current_balance
    FROM passive_products
)

-- ============================================================================
-- 3. FINAL CTE
-- ============================================================================
SELECT * FROM account_dim
