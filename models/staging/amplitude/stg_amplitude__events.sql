-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(event_id as varchar) as event_id,
    cast(user_id as varchar) as user_id,
    cast(device_id as varchar) as device_id,
    cast(event_type as varchar) as event_type,
    cast(event_time as timestamp_ntz) as event_time,
    {{ as_variant('event_properties') }} as event_properties,
    {{ as_variant('user_properties') }} as user_properties,
    cast(platform as varchar) as platform,
    cast(os_name as varchar) as os_name,
    cast(country as varchar) as country,
    cast(city as varchar) as city,
    cast(app_version as varchar) as app_version,
    cast(session_id as number(38,0)) as session_id,
    cast(server_upload_time as timestamp_ntz) as server_upload_time
from {{ source('amplitude', 'events') }}
