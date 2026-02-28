{% macro generate_bi_views(model) %}
    {# 
        Genera una vista homóloga con sufijo _v para la capa de consumo (Gold/Silver).
        Abstracción Total para herramientas de BI (PowerBI/Looker).
    #}
    {% set target_relation = api.Relation.create(
        database=model.database,
        schema=model.schema,
        identifier=model.identifier ~ '_v',
        type='view'
    ) %}
    
    {% set query %}
        CREATE OR REPLACE VIEW {{ target_relation }} AS
        SELECT * FROM {{ model }}
    {% endset %}
    
    {% do run_query(query) %}
    {{ log("BI View generated successfully: " ~ target_relation, info=True) }}
{% endmacro %}
