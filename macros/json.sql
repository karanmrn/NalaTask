{% macro as_variant(expression) -%}
try_parse_json(to_varchar({{ expression }}))
{%- endmacro %}

{% macro json_text(expression, path) -%}
cast(get_path({{ expression }}, '{{ path }}') as varchar)
{%- endmacro %}
