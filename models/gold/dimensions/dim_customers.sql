{{
    config(
        materialized='table',
        tags=["gold", "dimension"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTEs
-- ============================================================================
WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

bureau AS (
    SELECT * FROM {{ ref('stg_credit_bureau') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
customer_profile AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.date_of_birth,
        c.customer_since,
        
        -- Datos del buró de crédito
        b.credit_score,
        b.total_outstanding_debt,
        b.delinquency_history,
        b.report_date AS bureau_report_date
        
    FROM customers c
    LEFT JOIN bureau b
        ON c.tax_id_hashed = b.tax_id_hashed
)

-- ============================================================================
-- 3. FINAL CTE
-- ============================================================================
SELECT * FROM customer_profile
