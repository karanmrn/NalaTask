with starts as (
    select
        funnel_entity_id,
        min(case when event_type = 'sign_up.started' then event_time end) as signup_started_at,
        min(resolved_user_id) as user_id
    from {{ ref('int_onboarding_events') }}
    group by funnel_entity_id
),

signups_ranked as (
    select
        e.funnel_entity_id,
        e.event_time,
        e.country,
        row_number() over (partition by e.funnel_entity_id order by e.event_time, e.event_id) as rn
    from {{ ref('int_onboarding_events') }} as e
    inner join starts as s on e.funnel_entity_id = s.funnel_entity_id
    where
        e.event_type = 'sign_up.completed'
        and (s.signup_started_at is null or e.event_time >= s.signup_started_at)
),

signups as (
    select
        s.funnel_entity_id,
        s.user_id,
        s.signup_started_at,
        r.event_time as signup_completed_at,
        r.country as signup_country
    from starts as s left join signups_ranked as r on s.funnel_entity_id = r.funnel_entity_id and r.rn = 1
    where s.signup_started_at is not null or r.event_time is not null
),

kyc as (
    select
        s.funnel_entity_id,
        min(e.event_time) as kyc_completed_at
    from signups as s left join {{ ref('int_onboarding_events') }} as e
        on
            s.funnel_entity_id = e.funnel_entity_id and e.is_final_kyc_event
            and s.signup_completed_at <= e.event_time
    group by s.funnel_entity_id
),

tx as (
    select
        s.funnel_entity_id,
        min(case when e.event_time >= s.signup_completed_at then e.event_time end) as first_transaction_completed_at,
        min(case when e.event_time >= k.kyc_completed_at then e.event_time end) as funnel_transaction_completed_at
    from signups as s inner join kyc as k on s.funnel_entity_id = k.funnel_entity_id
    left join {{ ref('int_onboarding_events') }} as e
        on
            s.funnel_entity_id = e.funnel_entity_id
            and e.event_type = 'transaction.completed'
    group by s.funnel_entity_id
)

select
    s.funnel_entity_id,
    s.user_id,
    s.signup_country,
    s.signup_started_at,
    s.signup_completed_at,
    k.kyc_completed_at,
    t.first_transaction_completed_at,
    t.funnel_transaction_completed_at,
    cast(coalesce(s.signup_started_at, s.signup_completed_at) as date) as cohort_date,
    case when s.signup_started_at is not null then 1 else 0 end as started_count,
    case when s.signup_started_at is not null and s.signup_completed_at is not null then 1 else 0 end as ordered_signup_count,
    case when s.signup_started_at is not null and k.kyc_completed_at is not null then 1 else 0 end as ordered_kyc_count,
    case when s.signup_started_at is not null and t.funnel_transaction_completed_at is not null then 1 else 0 end as ordered_transaction_count,
    case when s.user_id is not null then datediff('millisecond', s.signup_completed_at, t.first_transaction_completed_at) / 3600000.0 end as signup_to_first_transaction_hours,
    datediff('millisecond', s.signup_started_at, s.signup_completed_at) / 3600000.0 as start_to_signup_hours,
    datediff('millisecond', s.signup_completed_at, k.kyc_completed_at) / 3600000.0 as signup_to_kyc_hours,
    datediff('millisecond', k.kyc_completed_at, t.funnel_transaction_completed_at) / 3600000.0 as kyc_to_transaction_hours,
    {{ var('exploration_days', 90) }} as observation_window_days
from signups as s inner join kyc as k on s.funnel_entity_id = k.funnel_entity_id
inner join tx as t on s.funnel_entity_id = t.funnel_entity_id
