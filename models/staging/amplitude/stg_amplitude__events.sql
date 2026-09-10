-- Fivetran daily batch. `_fivetran_synced` is the connector load time used for freshness.
with source as (
    select * from {{ source('amplitude', 'events') }}
)
select
    cast(event_id as varchar) as event_id,
    cast(user_id as varchar) as user_id,
    cast(device_id as varchar) as device_id,
    cast(event_type as varchar) as event_type,
    cast(event_time as {{ dbt.type_timestamp() }}) as event_time,
    {{ as_variant('event_properties') }} as event_properties,
    {{ as_variant('user_properties') }} as user_properties,
    cast(platform as varchar) as platform,
    cast(os_name as varchar) as os_name,
    cast(country as varchar) as country,
    cast(city as varchar) as city,
    cast(app_version as varchar) as app_version,
    cast(session_id as decimal(38,0)) as session_id,
    cast(server_upload_time as {{ dbt.type_timestamp() }}) as server_upload_time,
    cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _loaded_at
from source
