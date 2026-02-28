-- tests/assert_no_orphan_transactions.sql
-- ============================================================================
-- INTEGRIDAD REFERENCIAL (Orphan Records)
-- Valida que la capa Silver validada (int_transactions) no tenga transacciones
-- atadas a customer_ids que ya no existen o nunca existieron en el maestro.
-- ============================================================================

WITH transactions AS (
    SELECT transaction_id, customer_id 
    FROM {{ ref('int_transactions') }}
),

customers AS (
    SELECT customer_id 
    FROM {{ ref('stg_customers') }}
)

SELECT 
    t.transaction_id,
    t.customer_id
FROM transactions t
LEFT JOIN customers c 
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL
