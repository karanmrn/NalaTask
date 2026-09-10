-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('fincrime', 'rule_execution_reviews')) }}
)
select
    cast(id as varchar) as review_id,
    cast(rule_execution_id as varchar) as rule_execution_id,
    cast(reviewer_id as varchar) as reviewer_id,
    cast(review as varchar) as review_determination,
    cast(review_comment as varchar) as review_comment,
    cast(reviewed_at as {{ dbt.type_timestamp() }}) as reviewed_at,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
