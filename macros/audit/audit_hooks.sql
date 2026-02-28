{% macro audit_run_start() %}
    {% set query %}
        CREATE TABLE IF NOT EXISTS audit_logs.dbt_run_log (
            run_id STRING,
            start_time TIMESTAMP,
            end_time TIMESTAMP,
            status STRING
        );
        CREATE TABLE IF NOT EXISTS audit_logs.dbt_model_log (
            run_id STRING,
            model_name STRING,
            rows_processed BIGINT,
            rows_rejected BIGINT,
            execution_time TIMESTAMP
        );
    {% endset %}
    {% do run_query(query) %}
    
    {% set insert_start %}
        INSERT INTO audit_logs.dbt_run_log (run_id, start_time, status)
        VALUES ('{{ invocation_id }}', current_timestamp(), 'STARTED')
    {% endset %}
    {% do run_query(insert_start) %}
{% endmacro %}

{% macro audit_run_end() %}
    {% set update_end %}
        UPDATE audit_logs.dbt_run_log
        SET end_time = current_timestamp(), status = 'COMPLETED'
        WHERE run_id = '{{ invocation_id }}'
    {% endset %}
    {% do run_query(update_end) %}
{% endmacro %}

{% macro audit_model_execution(model) %}
    {# 
        Registra la finalización del modelo.
        Para capturar filas procesadas vs rechazadas en Databricks, se puede hacer 
        una query sobre los metadatos o las tablas de auditoría generadas por los modelos.
    #}
    {% set query %}
        INSERT INTO audit_logs.dbt_model_log (run_id, model_name, execution_time)
        VALUES ('{{ invocation_id }}', '{{ model.name }}', current_timestamp())
    {% endset %}
    {% do run_query(query) %}
    {{ log("Audited execution for: " ~ model.name, info=True) }}
{% endmacro %}
