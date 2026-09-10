-- One row per rule version. is_current_version marks the newest non-deleted version of each name.
-- Facts join on rule_id (the version key) so history is never rewritten by a rule edit.

select
    rule_id,
    rule_name,
    title,
    rule_type,
    rule_category,
    team,
    rule_version,
    created_at,
    updated_at,
    deleted_at,
    deleted_at is null as is_active,
    row_number() over (
        partition by rule_name
        order by case when deleted_at is null then 0 else 1 end, rule_version desc
    ) = 1 as is_current_version
from {{ ref('stg_fincrime__rules') }}
