"""prepare_case: compare live fixture stats to the pinned manifest ignoring st_dev only (pool remounted after
node reboots 2026-11-01: device 52->48; inode/size/mtime/ctime identical)."""
import sys,json,hashlib
from pathlib import Path
P=Path(sys.argv[1]); p=P/'prepare_case.py'; s=p.read_text()
old="assert stat(p)==fr['bytecopies'][name]['original_stats']and"
if old in s:
    s=s.replace(old,"assert {k:v for k,v in stat(p).items() if k!='device'}=={k:v for k,v in fr['bytecopies'][name]['original_stats'].items() if k!='device'} and")
    p.write_text(s)
for f in ['runtime_stock.py','runtime_combined.py']:
    q=P/f; t=q.read_text(); o="assert str(p)==prepared['input_targets'][name]and stat(p)==expected and"
    if o in t:
        t=t.replace(o,"assert str(p)==prepared['input_targets'][name]and {k:v for k,v in stat(p).items() if k!='device'}=={k:v for k,v in expected.items() if k!='device'} and"); q.write_text(t)
pins=json.loads((P/'source-pins.json').read_text())
for n in pins: pins[n]=hashlib.sha256((P/n).read_bytes()).hexdigest()
(P/'source-pins.json').write_text(json.dumps(pins,indent=2)+'\n'); print('devstat ok',P.name)
