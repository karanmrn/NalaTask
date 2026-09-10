{#
  StreamServe CDC handling.

  Assumption (stated in docs/01_architecture.md): StreamServe lands an append-only change log.
  Every row change in Postgres becomes a new row in RAW with three metadata columns:
    _cdc_operation  INSERT | UPDATE | DELETE
    _cdc_lsn        monotonically increasing Postgres log sequence number
    _cdc_loaded_at  timestamp the row landed in Snowflake

  Staging collapses the log to one current row per primary key and drops deleted keys.
  If the connector is instead configured to merge into a current-state table, set
  `cdc_landing_mode: current_state` and the macro becomes a pass-through.
#}

{% macro cdc_current_rows(source_relation, key='id') -%}
  {%- if var('cdc_landing_mode', 'change_log') == 'change_log' -%}
    select * exclude (_cdc_rank)
    from (
        select
            *,
            row_number() over (partition by {{ key }} order by _cdc_lsn desc, _cdc_loaded_at desc) as _cdc_rank
        from {{ source_relation }}
    )
    where _cdc_rank = 1
      and _cdc_operation <> 'DELETE'
  {%- else -%}
    select *, cast(null as varchar) as _cdc_operation, cast(null as bigint) as _cdc_lsn,
           cast(null as {{ dbt.type_timestamp() }}) as _cdc_loaded_at
    from {{ source_relation }}
  {%- endif -%}
{%- endmacro %}
