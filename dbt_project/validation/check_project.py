"""Local structural checks. Deliberately not labelled a dbt/MetricFlow parser."""
from pathlib import Path
import re,json,yaml
from harness import ROOT,render

def main():
    models={p.stem:p for p in (ROOT/'models').rglob('*.sql')}
    docs={};sources={};metrics={};semantic={};tests=0
    for p in ROOT.rglob('*.yml'):
        if any(x in p.parts for x in ('target','dbt_packages')):continue
        data=yaml.safe_load(p.read_text()) or {}
        if not isinstance(data,dict):raise AssertionError(str(p))
        model_entries=data.get('models',[])
        if isinstance(model_entries,list):
            for m in model_entries:
                assert m['name'] not in docs,('Duplicate doc',m['name'])
                docs[m['name']]=m
        for src in data.get('sources',[]):
            for table in src['tables']:sources[(src['name'],table['name'])]=table
        for m in data.get('metrics',[]):
            assert m['name'] not in metrics;mtype=m['type'];assert mtype in ('simple','ratio')
            metrics[m['name']]=m
        for sm in data.get('semantic_models',[]):semantic[sm['name']]=sm
    assert set(models)==set(docs),('Undocumented or phantom model',set(models)^set(docs))
    rawdefs=json.loads((ROOT/'validation/source_schema.json').read_text());assert len(rawdefs)==15
    assert {(v['source'],k) for k,v in rawdefs.items()} <= sources.keys()
    seed_names={p.stem for p in (ROOT/'seeds').glob('*.csv')}
    for name,p in models.items():
        d=docs[name];assert d.get('description') and d.get('columns')
        for c in d['columns']:
            assert c.get('description') and c.get('data_type'),(name,c)
            tests+=len(c.get('data_tests',[]))
        assert d.get('data_tests') or any(c.get('data_tests') for c in d['columns']),('No tests',name)
        refs=set(re.findall(r"ref\(['\"]([^'\"]+)['\"]\)",p.read_text()))
        assert refs <= set(models)|seed_names,(name,'Unresolved ref',refs-set(models)-seed_names)
        for a,b in re.findall(r"source\(['\"]([^'\"]+)['\"],\s*['\"]([^'\"]+)['\"]\)",p.read_text()):assert (a,b) in sources
        sql=render(p);assert '{{' not in sql and '{%' not in sql, name
    measures={m['name'] for sm in semantic.values() for m in sm['measures']}
    for name,m in metrics.items():
        assert m.get('description') and m.get('label')
        if m['type']=='simple':assert m['type_params']['measure'] in measures
        else:
            assert m['type_params']['numerator'] in metrics
            assert m['type_params']['denominator'] in metrics
    for sm in semantic.values():
        model=re.findall(r"ref\('([^']+)'\)",sm['model'])[0]
        assert model in docs
        fields={c['name'] for c in docs[model]['columns']}
        assert sm['defaults']['agg_time_dimension'] in fields
        for e in sm['entities']:assert e['expr'] in fields
        for d in sm['dimensions']:assert d['name'] in fields
        for m in sm['measures']:assert m['expr'] in fields
    report={'sql_models':len(models),'source_staging_models':len(rawdefs),'production_marts':sum('/marts/' in str(p) for p in models.values()),'exploratory_models':sum('/exploratory/' in str(p) for p in models.values()),'documented_columns':sum(len(d['columns']) for d in docs.values()),'column_data_tests':tests,'singular_sql_tests':len(list((ROOT/'tests').glob('*.sql'))),'semantic_models':len(semantic),'metric_definitions_including_helpers':len(metrics),'status':'PASS','limitation':'Structural/Jinja validation only; not native dbt parse, MetricFlow compilation, or Snowflake execution.'}
    print(json.dumps(report,indent=2));return report
if __name__=='__main__':main()
