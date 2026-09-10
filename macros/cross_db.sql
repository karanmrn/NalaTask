{#
  Cross-adapter helpers. The project runs on DuckDB locally (synthetic seeds) and on
  Snowflake in production. Every dialect difference lives here, nowhere else.
  Types: use `decimal(p,s)` (valid on both) and `{{ dbt.type_timestamp() }}` in models.
#}

{% macro as_variant(expression) -%}
  {{ return(adapter.dispatch('as_variant', 'nala_analytics')(expression)) }}
{%- endmacro %}

{% macro default__as_variant(expression) -%}
  try_parse_json(to_varchar({{ expression }}))
{%- endmacro %}

{% macro duckdb__as_variant(expression) -%}
  try_cast({{ expression }} as json)
{%- endmacro %}


{% macro json_text(expression, path) -%}
  {{ return(adapter.dispatch('json_text', 'nala_analytics')(expression, path)) }}
{%- endmacro %}

{% macro default__json_text(expression, path) -%}
  cast(get_path({{ expression }}, '{{ path }}') as varchar)
{%- endmacro %}

{% macro duckdb__json_text(expression, path) -%}
  {%- set json_path = '$' ~ path if path.startswith('[') else '$.' ~ path -%}
  json_extract_string({{ expression }}, '{{ json_path }}')
{%- endmacro %}


{% macro array_has(value, array_expression) -%}
  {{ return(adapter.dispatch('array_has', 'nala_analytics')(value, array_expression)) }}
{%- endmacro %}

{% macro default__array_has(value, array_expression) -%}
  coalesce(array_contains(to_variant({{ value }}), cast({{ array_expression }} as array)), false)
{%- endmacro %}

{% macro duckdb__array_has(value, array_expression) -%}
  coalesce(list_contains(cast({{ array_expression }} as varchar[]), {{ value }}), false)
{%- endmacro %}


{% macro to_bool(expression) -%}
  {{ return(adapter.dispatch('to_bool', 'nala_analytics')(expression)) }}
{%- endmacro %}

{% macro default__to_bool(expression) -%}
  try_to_boolean({{ expression }})
{%- endmacro %}

{% macro duckdb__to_bool(expression) -%}
  try_cast({{ expression }} as boolean)
{%- endmacro %}


{% macro day_spine(start_date, day_count) -%}
  {{ return(adapter.dispatch('day_spine', 'nala_analytics')(start_date, day_count)) }}
{%- endmacro %}

{% macro default__day_spine(start_date, day_count) -%}
  select dateadd('day', row_number() over (order by seq4()) - 1, cast('{{ start_date }}' as date)) as date_day
  from table(generator(rowcount => {{ day_count }}))
{%- endmacro %}

{% macro duckdb__day_spine(start_date, day_count) -%}
  select cast(range_day as date) as date_day
  from range(cast('{{ start_date }}' as date), cast('{{ start_date }}' as date) + interval {{ day_count }} day, interval 1 day) as t(range_day)
{%- endmacro %}


{% macro ms_between(start_expression, end_expression) -%}
  {{ dbt.datediff(start_expression, end_expression, 'millisecond') }}
{%- endmacro %}
