{% macro latency_band(seconds_expression) -%}
case
    when {{ seconds_expression }} is null or {{ seconds_expression }} < 0 then 'UNKNOWN'
    when {{ seconds_expression }} < 60 then 'UNDER_1_MIN'
    when {{ seconds_expression }} < 300 then '1_TO_5_MIN'
    when {{ seconds_expression }} < 1800 then '5_TO_30_MIN'
    when {{ seconds_expression }} < 3600 then '30_MIN_TO_1_HOUR'
    when {{ seconds_expression }} <= 86400 then '1_TO_24_HOURS'
    else 'OVER_24_HOURS'
end
{%- endmacro %}
