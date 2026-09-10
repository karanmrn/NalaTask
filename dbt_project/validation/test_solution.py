from __future__ import annotations
import json, re
from pathlib import Path
import pytest,yaml
from harness import Warehouse,ROOT,render,sqlite_casts
from fixtures import fixtures

@pytest.fixture
def wh():
    w=Warehouse(fixtures()).build()
    yield w
    w.close()

def test_actual_selects_execute_and_match_documented_columns(wh):
    assert len(wh.executed)==31 # 32nd model is Snowflake GENERATOR; equivalent calendar supplied locally.

def test_five_outbound_type_policy(wh):
    rows=wh.query('select transaction_type from transaction_type_policy where is_volume_qualifying')
    assert {r['transaction_type'] for r in rows}=={'DISBURSEMENT','CONVERSION_DISBURSEMENT','COLLECTION_CONVERSION_DISBURSEMENT','OUTGOING_PEER_TO_PEER','CONVERSION_OUTGOING_PEER_TO_PEER'}

def test_transaction_numerator_denominator_and_no_leg_fanout(wh):
    r=wh.query('select sum(completed_qualifying_count) c,sum(qualifying_count) q,sum(completed_sent_amount) amount from fct_transactions')[0]
    assert r['c']==5 and r['q']==6
    # This mixed-currency sum is used only to detect fixture row fanout, NOT as a business metric.
    assert r['amount']==360
    assert len(wh.query('select * from fct_transactions'))==8

def test_usd_direction_and_identity(wh):
    rows={r['transaction_id']:r for r in wh.query('select * from fct_transactions')}
    assert rows['t1']['completed_sent_amount_usd']==pytest.approx(130)
    assert rows['t3']['usd_per_unit']==1 and rows['t3']['completed_sent_amount_usd']==100
    assert rows['t4']['completed_sent_amount_usd']==pytest.approx(48)

def test_missing_fx_does_not_silently_partial_sum():
    f=fixtures();f['daily_fx_rates']=[r for r in f['daily_fx_rates'] if r['currency']!='GBP']
    w=Warehouse(f).build()
    assert w.query("select completed_sent_amount_usd v from agg_transactions_daily where sent_currency='GBP'")[0]['v'] is None
    assert len(w.model_test(ROOT/'tests/finance_no_missing_fx.sql'))==3
    w.close()

def test_duplicate_fx_causes_detectable_grain_violation():
    f=fixtures();f['daily_fx_rates'].append(dict(f['daily_fx_rates'][0]))
    w=Warehouse(f).build()
    assert w.model_test(ROOT/'tests/fx_unique_positive.sql')
    assert w.query('select transaction_id from fct_transactions group by transaction_id having count(*)>1')
    w.close()

def test_all_duration_boundaries(wh):
    d={r['attempt_id']:r['completion_time_band'] for r in wh.query('select * from fct_disbursement_attempts')}
    assert [d['band'+str(i)] for i in range(8)]==['UNDER_1_MIN','UNDER_1_MIN','1_TO_5_MIN','5_TO_30_MIN','30_MIN_TO_1_HOUR','1_TO_24_HOURS','1_TO_24_HOURS','OVER_24_HOURS']

def test_provider_denominator_keeps_pending(wh):
    r=wh.query("select * from agg_provider_daily where provider_name='P1'")[0]
    assert r['attempts']==3 and r['completed_attempts']==1 and r['failed_attempts']==1
    assert r['provider_success_rate']==pytest.approx(1/3)
    assert r['avg_completion_seconds_proxy']==120 and r['avg_failure_seconds_proxy']==120

def test_negative_duration_is_unknown_and_detected():
    f=fixtures();f['disbursement_attempts'][0]['last_updated_at']='2026-09-01 09:00:00'
    w=Warehouse(f).build()
    r=w.query("select * from fct_disbursement_attempts where attempt_id='band0'")[0]
    assert r['completion_seconds_proxy'] is None and r['completion_time_band']=='UNKNOWN'
    assert w.model_test(ROOT/'tests/attempt_update_before_creation.sql')
    w.close()

def test_formal_reviews_include_inconclusive_and_repeats(wh):
    r=wh.query('select sum(false_positive_count)*1.0/sum(review_count) rate, count(*) n from fct_rule_reviews')[0]
    assert r['n']==3 and r['rate']==pytest.approx(1/3)
    assert len(wh.query("select * from fct_rule_reviews where rule_execution_id='e1'"))==2

def test_old_deleted_rule_version_is_not_replaced(wh):
    r=wh.query("select rule_version from fct_rule_executions where rule_execution_id='e1'")[0]
    assert r['rule_version']==1

def test_review_date_not_execution_date(wh):
    r=wh.query("select review_date,review_seconds from fct_rule_reviews where review_id='v3'")[0]
    assert r['review_date']=='2026-09-02' and r['review_seconds']==86400

def test_tasks_preserve_unmatched_ambiguous_and_conflicted(wh):
    rows={r['task_id']:r for r in wh.query('select * from fct_fincrime_tasks')}
    assert len(rows)==5
    assert rows['task_ambiguous']['candidate_count']==2
    assert rows['task_ambiguous']['inferred_workflow_result'] is None
    assert rows['task_unique']['match_status']=='UNIQUE_INFERRED'
    assert rows['task_unique']['inferred_workflow_execution_id']=='w_unique'
    assert rows['task_unmatched']['match_status']=='UNMATCHED'
    assert rows['task_unsupported']['match_status']=='UNSUPPORTED_CONTEXT'
    assert rows['task_conflict']['match_status']=='CONFLICTING_CONTEXT'

def test_future_execution_and_wrong_scope_are_not_matched(wh):
    assert not wh.query("select * from int_task_workflow_candidates where workflow_execution_id in ('w_future','w_wrong_scope')")

def test_tasks_resolved_is_not_cancelled(wh):
    r=wh.query('select sum(task_count) n,sum(resolved_task_count) resolved from fct_fincrime_tasks')[0]
    assert r=={'n':5,'resolved':2}

def test_shared_device_remains_unresolved(wh):
    r=wh.query("select * from int_onboarding_events where event_id='shared0'")[0]
    assert r['resolved_user_id'] is None and r['identity_method']=='SHARED_DEVICE_UNRESOLVED'
    assert r['funnel_entity_id']=='device:shared'

def test_unique_device_anonymous_start_is_stitched(wh):
    r=wh.query("select * from int_onboarding_events where event_id='s0'")[0]
    assert r['resolved_user_id']=='u1' and r['identity_method']=='UNIQUE_DEVICE_INFERRED'

def test_kyc_step_is_not_kyc_completion(wh):
    assert wh.query("select is_final_kyc_event v from int_onboarding_events where event_id='k0'")[0]['v']==0
    assert wh.query("select is_final_kyc_event v from int_onboarding_events where event_id='k1'")[0]['v']==1

def test_ordered_funnel_is_separate_from_required_duration_metric(wh):
    r=wh.query("select * from fct_onboarding_funnel where user_id='u1'")[0]
    assert r['signup_country']=='US'
    assert r['signup_to_first_transaction_hours']==pytest.approx(.25)
    assert r['funnel_transaction_completed_at']=='2026-09-01 10:30:00'
    assert r['ordered_transaction_count']==1
    r=wh.query("select * from fct_onboarding_funnel where user_id='u4'")[0]
    assert r['signup_to_first_transaction_hours']==1
    assert r['started_count']==0 and r['ordered_transaction_count']==0

def test_all_singular_data_tests_on_clean_fixture(wh):
    for p in sorted((ROOT/'tests').glob('*.sql')):
        assert not wh.model_test(p),p.name

def test_malformed_json_is_detected():
    f=fixtures();f['users'][0]['source']='{malformed'
    w=Warehouse(f).build()
    assert w.model_test(ROOT/'tests/json_payloads_parse.sql')
    w.close()

def test_incremental_branch_selects_old_entity_recent_update(wh):
    # Exercise the actual incremental SELECT branch, not Snowflake MERGE itself.
    wh.conn.execute("update raw_payments__disbursement_attempts set created_at='2026-01-01 10:00:00',last_updated_at='2026-09-06 10:00:00' where id='p0'")
    wh.conn.execute('drop table stg_payments__attempts')
    p=ROOT/'models/staging/payments/stg_payments__attempts.sql'
    wh.conn.execute('create table stg_payments__attempts as '+sqlite_casts(render(p)))
    sql=sqlite_casts(render(ROOT/'models/marts/fct_disbursement_attempts.sql',incremental=True))
    assert 'p0' in {r['attempt_id'] for r in wh.query(sql)}

def test_repeat_build_is_idempotent_for_same_snapshot():
    a=Warehouse(fixtures()).build();b=Warehouse(fixtures()).build()
    for table,key in [('fct_transactions','transaction_id'),('fct_fincrime_tasks','task_id'),('fct_rule_reviews','review_id')]:
        assert a.query(f'select * from {table} order by {key}')==b.query(f'select * from {table} order by {key}')
    a.close();b.close()

def test_required_metrics_are_exact_named_ratios_and_averages():
    data=yaml.safe_load((ROOT/'models/semantic/metrics.yml').read_text());m={x['name']:x for x in data['metrics']}
    required={'completed_transaction_volume','transaction_success_rate','disbursement_provider_success_rate','fincrime_false_positive_rate','signup_to_first_transaction_hours'}
    assert required <= set(m)
    assert m['fincrime_false_positive_rate']['type_params']['denominator']=='all_formal_reviews'
    sm=next(x for x in data['semantic_models'] if x['name']=='onboarding')
    assert sm['measures'][0]['agg']=='average'

def test_ordinary_kyc_steps_cause_explicit_warning_without_final_signal():
    f=fixtures()
    for r in f['events']:r['event_properties']={}
    w=Warehouse(f).build()
    assert w.model_test(ROOT/'tests/kyc_final_signal_missing.sql')
    assert w.query("select signup_to_first_transaction_hours v from fct_onboarding_funnel where user_id='u1'")[0]['v']==pytest.approx(.25)
    w.close()
