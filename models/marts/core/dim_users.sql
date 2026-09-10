-- One row per user. Sender country and approval state for slicing any fact by user attributes.

select
    u.user_id,
    u.user_status,
    u.sender_country,
    u.registered_at,
    u.approved_at,
    u.approved_at is not null as is_kyc_approved,
    cast(u.registered_at as date) as registered_date,
    u.used_invitation_code_id is not null as used_invitation_code,
    {{ json_text('u.source', 'link') }} as acquisition_link,
    a.account_count,
    a.first_account_created_at
from {{ ref('stg_payments__users') }} as u
left join (
    select
        owner_user_id,
        count(*) as account_count,
        min(created_at) as first_account_created_at
    from {{ ref('stg_payments__accounts') }}
    where deleted_at is null
    group by owner_user_id
) as a on u.user_id = a.owner_user_id
