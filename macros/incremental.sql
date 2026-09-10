{#
  Incremental facts reprocess every source row whose `updated_at` falls inside a lookback
  window measured from the newest row already in the target. Late-arriving updates from the
  CDC replica (state changes on old transactions, retried attempts) are captured because the
  filter is on update time, never on creation time. `merge` on the natural key keeps one row
  per entity. Full refresh rebuilds from scratch: `dbt build --full-refresh`.
#}
{% macro incremental_lookback(updated_at_column) -%}
  {%- if is_incremental() -%}
    where {{ updated_at_column }} >= (
        select {{ dbt.dateadd('day', '-' ~ var('incremental_lookback_days', 3), 'coalesce(max(' ~ updated_at_column ~ '), cast(\'1900-01-01\' as ' ~ dbt.type_timestamp() ~ '))') }}
        from {{ this }}
    )
  {%- endif -%}
{%- endmacro %}
