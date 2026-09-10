# Run synthetic models and export inspectable CSVs; never connects to a warehouse.
import argparse,csv,json
from pathlib import Path
from fixtures import fixtures
from harness import Warehouse

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir',type=Path,default=Path('demo_outputs'))
    args=parser.parse_args();args.output_dir.mkdir(parents=True,exist_ok=True)
    w=Warehouse(fixtures()).build()
    tables=['agg_transactions_daily','agg_provider_daily','agg_fincrime_daily','fct_fincrime_tasks','fct_onboarding_funnel','agg_onboarding_daily']
    summary={}
    for table in tables:
        rows=w.query('select * from "'+table+'"')
        p=args.output_dir/(table+'.csv')
        if rows:
            with p.open('w',newline='') as f:
                writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
        summary[table]=len(rows)
    (args.output_dir/'README.txt').write_text('SYNTHETIC TEST OUTPUTS ONLY. Not NALA data, not real FX, and not Snowflake execution.\n')
    print(json.dumps(summary,indent=2));w.close()
if __name__=='__main__':main()
