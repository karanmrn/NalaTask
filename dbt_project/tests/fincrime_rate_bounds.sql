{{ config(severity='error', tags=['fincrime']) }}
select activity_date from {{ ref('agg_fincrime_daily') }} where false_positive_rate < 0 or false_positive_rate > 1 or false_positives > reviews
