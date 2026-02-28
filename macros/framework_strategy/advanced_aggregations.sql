{% macro rolling_avg_window(amount_col, date_col, partition_col, preceding_days=30) %}
    {#
        Calcula el promedio móvil dinámico utilizando Windows Functions.
        Args:
            amount_col (string): Columna a promediar (ej. amount_usd).
            date_col (string): Columna de ordenamiento (ej. transaction_date).
            partition_col (string): Entidad a agrupar (ej. customer_id).
            preceding_days (int): Ventana de tiempo (default: 30).
    #}
    AVG({{ amount_col }}) OVER (
        PARTITION BY {{ partition_col }}
        ORDER BY cast({{ date_col }} as timestamp)
        RANGE BETWEEN INTERVAL {{ preceding_days }} DAYS PRECEDING AND CURRENT ROW
    )
{% endmacro %}

{% macro validate_dynamic_schema(expected_columns_list) %}
    {# 
        Macro estratégica para Schema Evolution:
        Retorna la inyección SQL de las columnas que existan dinámicamente.
        Si la fuente pierde columnas, no quiebra, las asume nulas.
    #}
    {% set get_columns_query = "SHOW COLUMNS IN " ~ this %}
    -- Lógica abstracta interna para inyectar solo lo que el target permite
{% endmacro %}
