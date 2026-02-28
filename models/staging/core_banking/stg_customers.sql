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
    SELECT * FROM {{ source('core_banking', 'customers') }}
),

-- ============================================================================
-- 2. LOGICAL CTE
-- ============================================================================
logical AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        date_of_birth,
        
        -- Seguridad PCI / Ley de Protección de Datos: Enmascaramos desde Staging
        {{ mask_pii('tax_id') }} AS tax_id_hashed,
        {{ mask_pii('email') }} AS email_hashed,
        {{ mask_pii('phone_number') }} AS phone_number_hashed,
        
        created_at AS customer_since
    FROM import
),

-- ============================================================================
-- 3. VALIDATION CTE
-- ============================================================================
validation AS (
    SELECT
        *,
        CASE 
            WHEN customer_id IS NULL THEN 'Missing Customer ID'
            WHEN length(tax_id_hashed) = 0 THEN 'Missing Tax ID'
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
