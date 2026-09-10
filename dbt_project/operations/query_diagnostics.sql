-- READ ONLY. Account Usage latency and role privileges apply.
select query_id, query_tag, warehouse_name,
       total_elapsed_time / 1000.0 as elapsed_seconds,
       execution_time / 1000.0 as execution_seconds,
       queued_overload_time / 1000.0 as queued_seconds,
       bytes_scanned, partitions_scanned, partitions_total,
       bytes_spilled_to_remote_storage
from snowflake.account_usage.query_history
where start_time >= dateadd('day', -1, current_timestamp())
  and query_tag = 'nala_assessment'
order by total_elapsed_time desc;
