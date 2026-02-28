{{
    config(
        materialized='table',
        tags=["gold", "customer_360", "ltv"]
    )
}}

-- ============================================================================
-- 1. IMPORT CTEs
-- ============================================================================
WITH customers AS (
    SELECT * FROM {{ ref('dim_customers') }}
),

transactions AS (
    SELECT * FROM {{ ref('fct_transactions') }}
),

accounts AS (
    SELECT * FROM {{ ref('dim_accounts') }}
),

-- ============================================================================
-- 2. OPERATIONAL LATENCY & TRANSACTIONAL FREQUENCY CTE
-- ============================================================================
tx_metrics AS (
    SELECT 
        customer_id,
        MIN(transaction_date) AS first_tx_date,
        MAX(transaction_date) AS last_tx_date,
        COUNT(transaction_id) AS total_transactions_lifetime,
        
        -- Macros Avanzadas: Promedio transaccional de los últimos 30 días
        -- {{ rolling_avg_window('amount_usd', 'transaction_date', 'customer_id', 30) }} AS avg_30d_amount
        SUM(CASE WHEN transaction_date >= current_date() - INTERVAL 30 DAYS THEN 1 ELSE 0 END) AS tx_count_30d
        
    FROM transactions
    GROUP BY customer_id
),

-- ============================================================================
-- 3. CROSS-SELLING GAP CTE
-- ============================================================================
-- Identificamos clientes con alto saldo pasivo pero nulo producto activo (Préstamo)
cross_sell_metrics AS (
    SELECT
        customer_id,
        SUM(CASE WHEN account_type IN ('SAVINGS', 'CHECKING') THEN current_balance ELSE 0 END) AS total_liquid_assets,
        -- Asumiendo una lógica donde contemos productos activos en otra dimensión, 
        -- aquí simplificamos basado en el estatus de las cuentas o usando transacciones.
        -- En la vida real cruzaríamos con dim_active_products.
        0 AS active_loans_count 
    FROM accounts
    GROUP BY customer_id
),

-- ============================================================================
-- 4. GOLD LTV AGGREGATION CTE
-- ============================================================================
customer_360 AS (
    SELECT
        c.customer_id,
        c.credit_score,
        
        -- Operational Latency: Días entre la creación del cliente y su primer movimiento
        datediff(t.first_tx_date, c.customer_since) AS days_to_activation_latency,
        
        -- Churn Prediction Feature: Caída drástica de transacciones vs. promedio histórico
        t.tx_count_30d,
        (t.total_transactions_lifetime / GREATEST(datediff(current_date(), c.customer_since), 1)) * 30 AS expected_monthly_tx,
        
        -- Cross-Selling Gap
        cs.total_liquid_assets,
        CASE WHEN cs.total_liquid_assets > 10000 AND cs.active_loans_count = 0 
             THEN 'HIGH_PROBABILITY' ELSE 'LOW' 
        END AS cross_sell_loan_propensity
        
    FROM customers c
    LEFT JOIN tx_metrics t ON c.customer_id = t.customer_id
    LEFT JOIN cross_sell_metrics cs ON c.customer_id = cs.customer_id
)

SELECT * FROM customer_360
