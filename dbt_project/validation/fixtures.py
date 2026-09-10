"""Entirely synthetic inputs. No NALA data, realistic identities or live exchange rates."""
from datetime import datetime,timedelta

def fixtures():
    raw={}
    raw['users']=[dict(id='u'+str(i),status='ACTIVE',sender_country='GB',created='2026-09-01 08:00:00',allowed='2026-09-01 09:00:00') for i in range(1,6)]
    raw['users_account']=[dict(id='a1',owner_id='u1',type='PERSONAL',status='ACTIVE',created='2026-09-01 09:00:00',last_updated='2026-09-01 09:00:00')]
    tx=[('t1','COLLECTION_CONVERSION_DISBURSEMENT','COMPLETED','GBP',100),('t2','COLLECTION_CONVERSION_DISBURSEMENT','CREATED','GBP',50),('t3','DISBURSEMENT','COMPLETED','USD',100),('t4','DISBURSEMENT','COMPLETED','EUR',40),('t5','OUTGOING_PEER_TO_PEER','COMPLETED','GBP',20),('t6','INCOMING_PEER_TO_PEER','COMPLETED','GBP',200),('t7','COLLECTION','COMPLETED','GBP',100),('t8','DISBURSEMENT','COMPLETED','GBP',100)]
    raw['transactions_transaction']=[dict(id=i,user_id='u1',account_id='a1',type=t,state=s,sent_currency=c,sent_amount=a,received_currency='KES',received_amount=a*100,exchange_rate=100,source_amount=a,created_at='2026-09-01 09:00:00',updated_at='2026-09-01 10:00:00',purpose='REMITTANCE',summary={'original':{'source_amount':{'amount':a}}}) for i,t,s,c,a in tx]
    raw['transactions_collection']=[dict(id='c1',transaction_id='t1',account_id='a1',state='COMPLETED',amount=100,currency='GBP',created_at='2026-09-01 09:00:00',updated_at='2026-09-01 10:00:00')]
    raw['transactions_disbursement']=[dict(id='d1',transaction_id='t1',state='COMPLETED',amount=10000,currency='KES',provider_name='P_FINAL',created_at='2026-09-01 09:00:00',updated_at='2026-09-01 10:00:00')]
    base=datetime(2026,9,1,10)
    raw['disbursement_attempts']=[]
    for i,sec in enumerate([0,59.999,60,300,1800,3600,86400,86400.001]):
        raw['disbursement_attempts'].append(dict(id='band'+str(i),disbursement_id='d1',state='COMPLETED',provider_name='BANDS',selection_reason='PRIORITY_ORDER',created_at=base.isoformat(' ',timespec='milliseconds'),last_updated_at=(base+timedelta(seconds=sec)).isoformat(' ',timespec='milliseconds')))
    for i,state in enumerate(['COMPLETED','FAILED','WAITING_ON_PROVIDER']):
        raw['disbursement_attempts'].append(dict(id='p'+str(i),disbursement_id='d1',state=state,provider_name='P1',selection_reason='SMART_ROUTING',created_at=base.isoformat(' ',timespec='milliseconds'),last_updated_at=(base+timedelta(seconds=120)).isoformat(' ',timespec='milliseconds')))
    raw['rules']=[dict(id='r1',name='high_value',category='AML',version=1,created_at='2026-08-01 00:00:00',deleted_at='2026-08-31 00:00:00'),dict(id='r2',name='high_value',category='AML',version=2,created_at='2026-09-01 00:00:00')]
    raw['workflows']=[dict(id='wf1',name='screen',type='PRE_TRANSACTION',version=1,config={'nodes':[{'type':'RULE','config':{'rule_id':'r1'}}]})]
    raw['workflow_executions']=[
        dict(id='w1',workflow_id='wf1',result='FAIL',context={'transaction_id':'t1','user_id':'u1'},created_at='2026-09-01 09:55:00',actions=['HOLD_TRANSACTION']),
        dict(id='w2',workflow_id='wf1',result='PASS',context={'transaction_id':'t1','user_id':'u1'},created_at='2026-09-01 09:56:00',actions=['CREATE_TASK']),
        dict(id='w_future',workflow_id='wf1',result='FAIL',context={'transaction_id':'t1','user_id':'u1'},created_at='2026-09-01 10:05:00',actions=['CREATE_TASK']),
        dict(id='w_unique',workflow_id='wf1',result='FAIL',context={'user_id':'u2'},created_at='2026-09-01 09:59:00',actions=['BLOCK_USER']),
        dict(id='w_wrong_scope',workflow_id='wf1',result='FAIL',context={'user_id':'u2','transaction_id':'t2'},created_at='2026-09-01 09:58:00',actions=['HOLD_TRANSACTION'])]
    raw['rule_executions']=[dict(id='e1',rule_id='r1',workflow_execution_id='w1',result='FAIL',created_at='2026-09-01 09:55:00'),dict(id='e2',rule_id='r1',workflow_execution_id='w2',result='PASS',created_at='2026-09-01 09:56:00'),dict(id='e3',rule_id='r2',workflow_execution_id='w_unique',result='FAIL',created_at='2026-09-01 09:59:00')]
    raw['rule_execution_reviews']=[dict(id='v1',rule_execution_id='e1',review='FALSE_POSITIVE',reviewed_at='2026-09-01 10:55:00'),dict(id='v2',rule_execution_id='e1',review='INCONCLUSIVE',reviewed_at='2026-09-01 11:55:00'),dict(id='v3',rule_execution_id='e2',review='TRUE_POSITIVE',reviewed_at='2026-09-02 09:56:00')]
    raw['tasks_task']=[
        dict(id='task_ambiguous',service='fincrime',type='transaction_review',state='RESOLVED',resolution='APPROVED',associated_ids=['t1','ignored','u1']),
        dict(id='task_unique',service='fincrime',type='user_review',state='RESOLVED',resolution='REJECTED',associated_ids=['u2']),
        dict(id='task_unmatched',service='fincrime',type='user_review',state='OPEN',associated_ids=['u3']),
        dict(id='task_unsupported',service='fincrime',type='escalation',state='CANCELLED',associated_ids=['opaque']),
        dict(id='task_conflict',service='fincrime',type='transaction_review',state='OPEN',associated_ids=['t1','ignored','u2']),
        dict(id='task_support',service='support',type='user_review',state='OPEN',associated_ids=['u2'])]
    for r in raw['tasks_task']:r.update(created_at='2026-09-01 10:00:00',last_updated_at='2026-09-01 11:00:00')
    raw['daily_fx_rates']=[dict(rate_date='2026-09-01',currency='GBP',usd_per_unit=1.3,rate_source='SYNTHETIC_TEST_ONLY'),dict(rate_date='2026-09-01',currency='EUR',usd_per_unit=1.2,rate_source='SYNTHETIC_TEST_ONLY')]
    ev=[]
    def event(i,u,d,t,time,props=None,country='GB'):
        ev.append(dict(event_id=i,user_id=u,device_id=d,event_type=t,event_time='2026-09-01 '+time,event_properties=props or {},country=country,platform='iOS',server_upload_time='2026-09-02 05:00:00'))
    event('s0',None,'device1','sign_up.started','09:00:00')
    event('s0repeat',None,'device1','sign_up.started','09:05:00')
    event('s1','u1','device1','sign_up.completed','10:00:00',country='US')
    event('k0','u1','device1','kyc_step.completed','10:10:00')
    event('k1','u1','device1','kyc_step.completed','10:20:00',{'is_final_step':True})
    event('t0','u1','device1','transaction.completed','08:00:00')
    event('t1','u1','device1','transaction.completed','10:15:00')
    event('t2','u1','device1','transaction.completed','10:30:00')
    event('shared0',None,'shared','sign_up.started','09:00:00')
    event('shared1','u2','shared','app.opened','09:20:00')
    event('shared2','u3','shared','app.opened','09:30:00')
    event('u4s','u4','device4','sign_up.completed','09:00:00')
    event('u4t','u4','device4','transaction.completed','10:00:00')
    event('anon',None,'device_anon','sign_up.started','09:00:00')
    raw['events']=ev
    return raw
