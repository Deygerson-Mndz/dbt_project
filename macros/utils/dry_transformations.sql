{% macro convert_currency(column_name, source_currency, target_currency='USD') %}
    {# 
        Lógica DRY para transformación de moneda.
        Se asume que hay una tabla de conversión o un tipo de factor estático para el ejemplo.
    #}
    CASE 
        WHEN {{ source_currency }} = '{{ target_currency }}' THEN cast({{ column_name }} as decimal(18,2))
        WHEN {{ source_currency }} = 'EUR' THEN cast({{ column_name }} * 1.10 as decimal(18,2))
        ELSE cast({{ column_name }} as decimal(18,2))
    END
{% endmacro %}

{% macro normalize_date(date_column) %}
    {# Ejemplo de macro DRY para estandarizar formatos de fecha #}
    date_trunc('day', cast({{ date_column }} as timestamp))
{% endmacro %}
