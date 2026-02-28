{% macro mask_pii(column_name) %}
    {#
        Aplica un hash SHA-256 para enmascarar PII desde la capa Staging (Bronze/Silver).
        Cumplimiento estricto con el estándar bancario PCI-DSS.
        
        Args:
            column_name (string): El nombre de la columna que contiene PII (ej. card_number).
    #}
    sha2(cast({{ column_name }} as string), 256)
{% endmacro %}
