{#
  Models keep dbt's default `<target_schema>_<custom_schema>` naming.
  Seeds that emulate RAW landing tables (meta.raw_landing: true) use the custom schema
  verbatim so `source()` references resolve identically on DuckDB and Snowflake.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- if custom_schema_name is none -%}
    {{ target.schema }}
  {%- elif node.resource_type == 'seed' and node.config.get('meta', {}).get('raw_landing', false) -%}
    {{ custom_schema_name | trim }}
  {%- else -%}
    {{ target.schema }}_{{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
