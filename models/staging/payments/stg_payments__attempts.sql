-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as attempt_id,
    cast(disbursement_id as varchar) as disbursement_id,
    cast(state as varchar) as attempt_state,
    cast(provider_name as varchar) as provider_name,
    cast(provider_id as varchar) as provider_id,
    cast(selection_reason as varchar) as selection_reason,
    cast(provider_error_category as varchar) as provider_error_category,
    cast(created_at as timestamp_ntz) as created_at,
    cast(last_updated_at as timestamp_ntz) as updated_at,
    cast(eta as timestamp_ntz) as eta,
    cast(max_eta as timestamp_ntz) as max_eta,
    cast(error as varchar) as error,
    cast(provider_error as varchar) as provider_error,
    cast(receipt_number as varchar) as receipt_number,
    cast(psp_account_id as varchar) as psp_account_id
from {{ source('payments', 'disbursement_attempts') }}
