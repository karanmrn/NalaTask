with window_events as (
    select event_id, user_id, device_id, event_type, event_time, event_properties, country, server_upload_time
    from {{ ref('stg_amplitude__events') }}
    where event_time >= dateadd('day', -{{ var('exploration_days', 90) }}, cast('{{ var("as_of_timestamp", run_started_at.strftime("%Y-%m-%d %H:%M:%S")) }}' as timestamp_ntz))
      and event_time < cast('{{ var("as_of_timestamp", run_started_at.strftime("%Y-%m-%d %H:%M:%S")) }}' as timestamp_ntz)
), devices as (
    select device_id, count(distinct user_id) as observed_users,
           case when count(distinct user_id) = 1 then min(user_id) end as unique_user_id
    from window_events group by device_id
), identified as (
    select e.*, coalesce(e.user_id, d.unique_user_id) as resolved_user_id,
        case when e.user_id is not null then 'EXPLICIT_USER'
             when d.observed_users = 1 then 'UNIQUE_DEVICE_INFERRED'
             when d.observed_users > 1 then 'SHARED_DEVICE_UNRESOLVED'
             else 'ANONYMOUS_DEVICE' end as identity_method
    from window_events e left join devices d on e.device_id = d.device_id
)
select event_id, resolved_user_id, device_id,
    case when resolved_user_id is not null then 'user:' || resolved_user_id else 'device:' || device_id end as funnel_entity_id,
    identity_method, event_type, event_time, country, server_upload_time,
    event_type = 'kyc_step.completed'
      and coalesce(try_to_boolean({{ json_text('event_properties', 'is_final_step') }}), false) as is_final_kyc_event
from identified
where event_type in ('sign_up.started', 'sign_up.completed', 'kyc_step.completed', 'transaction.completed')
