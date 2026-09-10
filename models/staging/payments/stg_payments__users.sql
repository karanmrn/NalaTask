-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as user_id,
    cast(status as varchar) as user_status,
    {{ as_variant('source') }} as source,
    cast(sender_country as varchar) as sender_country,
    cast(created as timestamp_ntz) as registered_at,
    cast(allowed as timestamp_ntz) as approved_at,
    {{ as_variant('client_properties') }} as client_properties,
    cast(used_invitation_code_id as varchar) as used_invitation_code_id,
    cast(profile_picture as varchar) as profile_picture,
    {{ as_variant('usage') }} as usage
from {{ source('payments', 'users') }}
