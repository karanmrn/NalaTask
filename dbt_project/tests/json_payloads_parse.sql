{{ config(tags=['source_contract']) }}
select 'payments.users.source' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'users') }} where source is not null and {{ as_variant('source') }} is null
union all
select 'payments.users.client_properties' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'users') }} where client_properties is not null and {{ as_variant('client_properties') }} is null
union all
select 'payments.users.usage' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'users') }} where usage is not null and {{ as_variant('usage') }} is null
union all
select 'payments.users_account.features' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'users_account') }} where features is not null and {{ as_variant('features') }} is null
union all
select 'payments.users_account.client_properties' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'users_account') }} where client_properties is not null and {{ as_variant('client_properties') }} is null
union all
select 'payments.transactions_transaction.summary' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'transactions_transaction') }} where summary is not null and {{ as_variant('summary') }} is null
union all
select 'payments.transactions_transaction.metadata' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'transactions_transaction') }} where metadata is not null and {{ as_variant('metadata') }} is null
union all
select 'payments.tasks_task.associated_ids' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'tasks_task') }} where associated_ids is not null and {{ as_variant('associated_ids') }} is null
union all
select 'payments.tasks_task.content' as source_field, cast(id as varchar) as record_id from {{ source('payments', 'tasks_task') }} where content is not null and {{ as_variant('content') }} is null
union all
select 'fincrime.workflows.config' as source_field, cast(id as varchar) as record_id from {{ source('fincrime', 'workflows') }} where config is not null and {{ as_variant('config') }} is null
union all
select 'fincrime.workflow_executions.context' as source_field, cast(id as varchar) as record_id from {{ source('fincrime', 'workflow_executions') }} where context is not null and {{ as_variant('context') }} is null
union all
select 'fincrime.workflow_executions.actions' as source_field, cast(id as varchar) as record_id from {{ source('fincrime', 'workflow_executions') }} where actions is not null and {{ as_variant('actions') }} is null
union all
select 'fincrime.rule_executions.context' as source_field, cast(id as varchar) as record_id from {{ source('fincrime', 'rule_executions') }} where context is not null and {{ as_variant('context') }} is null
union all
select 'amplitude.events.event_properties' as source_field, cast(event_id as varchar) as record_id from {{ source('amplitude', 'events') }} where event_properties is not null and {{ as_variant('event_properties') }} is null
union all
select 'amplitude.events.user_properties' as source_field, cast(event_id as varchar) as record_id from {{ source('amplitude', 'events') }} where user_properties is not null and {{ as_variant('user_properties') }} is null
