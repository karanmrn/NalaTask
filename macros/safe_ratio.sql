{% macro safe_ratio(numerator, denominator) -%}
(cast({{ numerator }} as float) / nullif({{ denominator }}, 0))
{%- endmacro %}
