"""Offline execution of the repository's SELECT SQL over synthetic SQLite fixtures.

This is NOT dbt compilation, Snowflake execution, precision validation, MERGE
validation, or MetricFlow query compilation. The small compatibility layer only
adapts SQL scalar functions and casts. Model joins/filters/aggregations are the
actual repository SQL, not a separate Python implementation of the business logic.
"""
from __future__ import annotations
import csv, datetime as dt, json, re, sqlite3
from pathlib import Path
from typing import Any
from jinja2 import Environment, StrictUndefined
ROOT=Path(__file__).resolve().parents[1]
ASOF='2026-09-07 12:00:00'

def getpath(value: Any, path: str) -> Any:
    if value is None:return None
    try:
        x=json.loads(value) if isinstance(value,str) else value
        for token in re.findall(r'[^.\[\]]+',path):
            x=x[int(token)] if isinstance(x,list) else x.get(token)
            if x is None:return None
        if isinstance(x,(list,dict)):return json.dumps(x)
        if isinstance(x,bool):return 'true' if x else 'false'
        return x
    except (ValueError,TypeError,IndexError,KeyError):return None

def parsed(value):
    if value is None:return None
    try:return json.dumps(json.loads(str(value)))
    except (ValueError,TypeError):return None

def timestamp(x):
    return dt.datetime.fromisoformat(str(x).replace('Z','+00:00')).replace(tzinfo=None)

def dateadd(unit,n,x):
    if x is None or n is None:return None
    factor={'day':86400,'minute':60,'second':1,'millisecond':0.001}[unit.lower()]
    return (timestamp(x)+dt.timedelta(seconds=float(n)*factor)).isoformat(' ',timespec='milliseconds')

def datediff(unit,a,b):
    if a is None or b is None:return None
    seconds=(timestamp(b)-timestamp(a)).total_seconds()
    return round(seconds*1000) if unit.lower()=='millisecond' else seconds/{'second':1,'minute':60,'hour':3600,'day':86400}[unit.lower()]

def matching_paren(s,start):
    depth=0; quote=None;i=start
    while i<len(s):
        ch=s[i]
        if quote:
            if ch==quote:
                if i+1<len(s) and s[i+1]==quote:i+=1
                else:quote=None
        elif ch in "'\"":quote=ch
        elif ch=='(':depth+=1
        elif ch==')':
            depth-=1
            if depth==0:return i
        i+=1
    raise ValueError('Unbalanced CAST parentheses')

def sqlite_casts(sql):
    """Recursively preserve expressions while adapting Snowflake CAST target types."""
    sql=re.sub(r"::(?:timestamp_ntz|varchar|date)\b", "", sql, flags=re.I)
    m=re.search(r'\bcast\s*\(',sql,re.I)
    if not m:return re.sub(r'::(?:timestamp_ntz|varchar|date)\b','',sql,flags=re.I)
    start=sql.index('(',m.start());end=matching_paren(sql,start);body=sql[start+1:end]
    parts=list(re.finditer(r'\s+as\s+([a-z_]+(?:\(\d+,\d+\))?)\s*$',body,re.I))
    if not parts:raise ValueError('Unrecognised CAST '+body)
    cut=parts[-1];expr=sqlite_casts(body[:cut.start()]);typ=cut.group(1).lower()
    if typ=='date':replacement=f'date({expr})'
    elif typ in ('timestamp_ntz','varchar','variant'):replacement=f'cast({expr} as text)'
    elif typ.startswith('number'):replacement=f'cast({expr} as numeric)'
    else:replacement=f'cast({expr} as {typ})'
    return sql[:m.start()]+replacement+sqlite_casts(sql[end+1:])

def render(path:Path,variables=None,incremental=False):
    v={'as_of_timestamp':ASOF,'exploration_days':90,'task_match_window_minutes':60,'incremental_overlap_days':3}
    v.update(variables or {})
    env=Environment(undefined=StrictUndefined)
    env.globals.update(ref=lambda n:'"'+n+'"',source=lambda a,b:'"raw_'+a+'__'+b+'"',
                       config=lambda *a,**k:'',var=lambda n,default=None:v.get(n,default),
                       is_incremental=lambda:incremental,this='"fct_disbursement_attempts"',
                       run_started_at=timestamp(ASOF))
    for p in sorted((ROOT/'macros').glob('*.sql')):
        module=env.from_string(p.read_text()).make_module()
        for n in dir(module):
            if not n.startswith('_'):env.globals[n]=getattr(module,n)
    return env.from_string(path.read_text()).render()

class Warehouse:
    def __init__(self, raw=None):
        self.conn=sqlite3.connect(':memory:');self.conn.row_factory=sqlite3.Row
        self.conn.create_function('get_path',2,getpath)
        self.conn.create_function('try_parse_json',1,parsed)
        self.conn.create_function('to_varchar',1,lambda x:None if x is None else str(x))
        self.conn.create_function('to_variant',1,lambda x:x)
        self.conn.create_function('array_contains',2,lambda item,arr:None if arr is None else int(item in json.loads(arr)))
        self.conn.create_function('try_to_boolean',1,lambda x:None if x is None else (1 if str(x).lower() in ('true','1','yes') else (0 if str(x).lower() in ('false','0','no') else None)))
        self.conn.create_function('dateadd',3,dateadd)
        self.conn.create_function('datediff',3,datediff)
        self.source_schema=json.loads((ROOT/'validation/source_schema.json').read_text())
        self.catalog=json.loads((ROOT/'validation/model_catalog.json').read_text())
        self.executed=[]
        for table,spec in self.source_schema.items():
            name='raw_'+spec['source']+'__'+table
            defs=', '.join('"'+c[0]+'" '+('NUMERIC' if c[1] in ('decimal','integer','bigint') else 'TEXT') for c in spec['columns'])
            self.conn.execute(f'create table "{name}" ({defs})')
        self.conn.execute('create table raw_reference_data__daily_fx_rates(rate_date text,currency text,usd_per_unit numeric,rate_source text)')
        self.conn.execute('create table transaction_type_policy(transaction_type text,is_volume_qualifying boolean,rationale text)')
        with (ROOT/'seeds/transaction_type_policy.csv').open() as f:
            self.conn.executemany('insert into transaction_type_policy values (?,?,?)',[(r['transaction_type'],r['is_volume_qualifying']=='true',r['rationale']) for r in csv.DictReader(f)])
        if raw:
            for table,rows in raw.items():
                name='raw_reference_data__daily_fx_rates' if table=='daily_fx_rates' else 'raw_'+self.source_schema[table]['source']+'__'+table
                for row in rows:self.insert(name,row)
    def insert(self,table,row):
        keys=list(row);vs=[json.dumps(row[k]) if isinstance(row[k],(dict,list)) else row[k] for k in keys]
        cols=', '.join('"'+k+'"' for k in keys);places=','.join('?' for _ in keys)
        self.conn.execute(f'insert into "{table}" ({cols}) values ({places})',vs)
    def build(self):
        files={p.stem:p for p in (ROOT/'models').rglob('*.sql')}
        # The Snowflake GENERATOR is not executed in SQLite; equivalent reference calendar only.
        self.conn.execute('create table metricflow_time_spine(date_day text)')
        self.conn.executemany('insert into metricflow_time_spine values (?)',[((dt.date(2020,1,1)+dt.timedelta(days=i)).isoformat(),) for i in range(7305)])
        done={'metricflow_time_spine','transaction_type_policy'}
        while len(done)-1<len(files):
            progress=False
            for n,p in files.items():
                if n in done:continue
                deps=set(re.findall(r"ref\(['\"]([^'\"]+)['\"]\)",p.read_text()))
                if deps <= done:
                    query=sqlite_casts(render(p))
                    try:self.conn.execute(f'create table "{n}" as {query}')
                    except Exception as exc:raise RuntimeError(f'{n}: {exc}\n{query}') from exc
                    actual=[r[1] for r in self.conn.execute(f'pragma table_info("{n}")')]
                    expected=[c['name'] for c in self.catalog[n]['columns']]
                    if actual!=expected:raise AssertionError(f'{n}: output/doc mismatch\n{actual}\n{expected}')
                    done.add(n);self.executed.append(n);progress=True
            if not progress:raise RuntimeError('Dependency cycle or unresolved model '+str(set(files)-done))
        return self
    def query(self,sql):return [dict(r) for r in self.conn.execute(sql)]
    def model_test(self,path):return self.query(sqlite_casts(render(path)))
    def close(self):self.conn.close()
