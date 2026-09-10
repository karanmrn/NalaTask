-- StreamServe CDC log collapsed to one current row per key; deletes removed. See macros/cdc.sql.
with source as (
    {{ cdc_current_rows(source('payments', 'transactions_transaction')) }}
)

select
    cast(id as varchar) as transaction_id,
    cast(user_id as varchar) as user_id,
    cast(account_id as varchar) as account_id,
    cast(type as varchar) as transaction_type,
    cast(state as varchar) as transaction_state,
    cast(sent_amount as decimal(38, 8)) as sent_amount,
    cast(sent_currency as varchar) as sent_currency,
    cast(received_amount as decimal(38, 8)) as received_amount,
    cast(received_currency as varchar) as received_currency,
    cast(exchange_rate as decimal(38, 12)) as exchange_rate,
    cast(source_amount as decimal(38, 8)) as source_amount,
    cast(recipient_id as varchar) as recipient_id,
    cast(recipient_account_id as varchar) as recipient_account_id,
    cast(workflow_id as varchar) as workflow_id,
    cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
    cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
    cast(expires_at as {{ dbt.type_timestamp() }}) as expires_at,
    cast(memo as varchar) as memo,
    cast(purpose as varchar) as purpose,
    cast(from_wallet_id as varchar) as from_wallet_id,
    cast(to_wallet_id as varchar) as to_wallet_id,
    {{ as_variant('summary') }} as summary,
    {{ as_variant('metadata') }} as metadata,
    cast(fee_label as varchar) as fee_label,
    cast(fee_kind as varchar) as fee_kind,
    cast(_cdc_loaded_at as {{ dbt.type_timestamp() }}) as _loaded_at
from source
