{#- A model's schema is exactly the layer schema it names (stg, core, pres), never dbt's default
    "<target schema>_<custom schema>", so dbt builds only into schemas MIG-0000 created. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}{{ target.schema }}{%- else -%}{{ custom_schema_name | trim }}{%- endif -%}
{%- endmacro %}
