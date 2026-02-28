-- tests/assert_idempotency_fct_transactions.sql
-- ============================================================================
-- ESTABILIDAD OPERATIVA E IDEMPOTENCIA
-- Si ejecutamos el pipeline Gold 3 veces para el mismo día, 
-- no deben existir duplicados en la fact table si la clave es única.
-- ============================================================================

WITH transaction_counts AS (
    SELECT 
        transaction_id,
        COUNT(*) AS occurrence_count
    FROM {{ ref('fct_transactions') }}
    GROUP BY transaction_id
)

SELECT * 
FROM transaction_counts 
WHERE occurrence_count > 1
