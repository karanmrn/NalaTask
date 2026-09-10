-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as workflow_id,
    cast(name as varchar) as workflow_name,
    cast(title as varchar) as title,
    cast(type as varchar) as workflow_type,
    {{ as_variant('config') }} as config,
    cast(version as number(38,0)) as workflow_version,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at,
    cast(deleted_at as timestamp_ntz) as deleted_at
from {{ source('fincrime', 'workflows') }}
