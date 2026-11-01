"""Stage pinned Thompson lookup tables (qr_acr_qg_V4, qr_acr_qsV2, freezeH2O) read-only into the run directory.
Gated on lease['experimental_thompson_tables']. Usage: tables_patch.py <pkg>"""
import sys,json,hashlib
from pathlib import Path
P=Path(sys.argv[1]); F='/pool/wrf-experiment/wrf-cpu/fixtures/thompson-tables-r1'
sums={l.split()[1]:l.split()[0] for l in open('/tmp/claude-1000/-home-ddietz-wrf/0df3e64e-9311-4710-8322-9babb0b17cad/scratchpad/tables.sha') if l.strip()}
p=P/'prepare_case.py'; s=p.read_text()
old=" inputs={};targets={}\n"; assert s.count(old)==1
new=""" for name,h in sorted(lease.get('experimental_thompson_tables',{}).get('files',{}).items()):
  p=Path(lease['experimental_thompson_tables']['directory'])/name;q=D/name;assert sha(p)==h and not p.stat().st_mode&0o222 and not q.exists()
  shutil.copyfile(p,q);q.chmod(0o444);assert sha(q)==h
 inputs={};targets={}
"""
p.write_text(s.replace(old,new))
b=P/'batch_release.py'; t=b.read_text(); o="allowed={"; assert t.count(o)==1; b.write_text(t.replace(o,"allowed={'experimental_thompson_tables',"))
lp=P/'lease-candidate-proposed.json'; l=json.loads(lp.read_text())
l['experimental_thompson_tables']={'directory':F,'files':sums,'note':'tables written by identical prior runs (byte-identical across 5 runs and builds); WRF reads instead of recomputing'}
lp.write_text(json.dumps(l,indent=2))
pins=json.loads((P/'source-pins.json').read_text())
for n in pins: pins[n]=hashlib.sha256((P/n).read_bytes()).hexdigest()
(P/'source-pins.json').write_text(json.dumps(pins,indent=2)+'\n'); print('tables patch', sums)
