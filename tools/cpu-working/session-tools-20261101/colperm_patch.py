"""Register column-permutation rank maps and select one. Usage: colperm_patch.py <pkg> <variant>"""
import sys,json,hashlib,shutil
from pathlib import Path
P=Path(sys.argv[1]); V=sys.argv[2]; SRC=Path('/home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/colperm-r1')
pins=json.loads((SRC/'map-pins.json').read_text())
for n in pins: shutil.copy(SRC/(n+'-rank-map.json'),P/(n+'-rank-map.json'))
old="'candidate': 'e003599c0fefc226055383019c09810b4aada079817531b604ba236a5e81c0d4'}"
new="'candidate': 'e003599c0fefc226055383019c09810b4aada079817531b604ba236a5e81c0d4', "+", ".join(f"'{k}': '{v}'" for k,v in pins.items())+"}"
for f in ['adapter/multinode_mpi.py','runtime_combined.py']:
    p=P/f; s=p.read_text(); assert s.count(old)==1,f; p.write_text(s.replace(old,new))
p=P/'placement_map_proof.py'; s=p.read_text(); o2="'candidate':'e003599c0fefc226055383019c09810b4aada079817531b604ba236a5e81c0d4'}"
assert s.count(o2)==1; p.write_text(s.replace(o2,"'candidate':'e003599c0fefc226055383019c09810b4aada079817531b604ba236a5e81c0d4',"+",".join(f"'{k}':'{v}'" for k,v in pins.items())+"}"))
b=P/'batch_release.py'; s=b.read_text()
o3="allowed={'root_authorized'"; assert s.count(o3)==1; s=s.replace(o3,"allowed={'rank_map','rank_map_variant','root_authorized'")
REF='ref' if "ref['nodes']" in s else 'old'
o4="for host,n in "+REF+"['nodes'].items():assert {k:v for k,v in n.items()if k!='unit'}=={k:v for k,v in l['nodes'][host].items()if k!='unit'}"
assert s.count(o4)==1
s=s.replace(o4,"for host,n in "+REF+"['nodes'].items():assert {k:v for k,v in n.items()if k!='unit' and not (k=='rank_physical_cpus' and l['rank_map_variant'].startswith('colperm'))}=={k:v for k,v in l['nodes'][host].items()if k!='unit' and not (k=='rank_physical_cpus' and l['rank_map_variant'].startswith('colperm'))}")
b.write_text(s)
rc=P/'runtime_checks.py'; t=rc.read_text(); o5="lease['rank_map_variant']in ['control','candidate']"; assert t.count(o5)==1; rc.write_text(t.replace(o5,"lease['rank_map_variant']in ['control','candidate','colperm-a','colperm-b','colperm-c']"))
lp=P/'lease-candidate-proposed.json'; l=json.loads(lp.read_text()); m=json.loads((P/(V+'-rank-map.json')).read_text())
l['rank_map']=m; l['rank_map_variant']=V
for h,n in l['nodes'].items(): n['rank_physical_cpus']=[r['cpu'] for r in m if r['host']==h]
lp.write_text(json.dumps(l,indent=2))
pp=json.loads((P/'source-pins.json').read_text())
for n in pins: pp[n+'-rank-map.json']=''
for n in pp: pp[n]=hashlib.sha256((P/n).read_bytes()).hexdigest()
(P/'source-pins.json').write_text(json.dumps(pp,indent=2)+'\n'); print('colperm',V)
