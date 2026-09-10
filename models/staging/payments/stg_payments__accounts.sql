-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as account_id,
    cast(owner_id as varchar) as owner_user_id,
    cast(name as varchar) as account_name,
    cast(type as varchar) as account_type,
    cast(status as varchar) as account_status,
    {{ as_variant('features') }} as features,
    cast(created as timestamp_ntz) as created_at,
    cast(last_updated as timestamp_ntz) as updated_at,
    cast(profile_id as varchar) as profile_id,
    cast(limit_level as varchar) as limit_level,
    {{ as_variant('client_properties') }} as client_properties,
    cast(deleted as timestamp_ntz) as deleted_at
from {{ source('payments', 'users_account') }}
