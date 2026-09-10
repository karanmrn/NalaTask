-- Current-row source contract; do not silently deduplicate conflicting CDC rows.
select
    cast(id as varchar) as rule_id,
    cast(name as varchar) as rule_name,
    cast(title as varchar) as title,
    cast(description as varchar) as description,
    cast(type as varchar) as rule_type,
    cast(category as varchar) as rule_category,
    cast(team as varchar) as team,
    cast(condition as varchar) as condition,
    cast(version as number(38,0)) as rule_version,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at,
    cast(deleted_at as timestamp_ntz) as deleted_at
from {{ source('fincrime', 'rules') }}
