import sys,collections,re
b=collections.defaultdict(collections.Counter); t0=None; cur=None; first=False
for l in sys.stdin:
    l=l.rstrip('\n')
    if not l.strip(): continue
    m=re.match(r'^\s*(\d+\.\d+):\s*$',l)
    if m:
        t=float(m.group(1)); t0=t if t0 is None else t0; cur=int(t-t0); first=True; continue
    if cur is None or not first: continue
    s=l.strip().split()[-1]
    if 'inflate' in s or 'adler' in s: cat='inflate'
    elif any(k in s for k in ['progress','ucp','ucs','uct','pml','coll','opal','sync_wait','mca_']): cat='mpi'
    elif s.startswith('0xffff') or s=='[unknown]': cat='kernel'
    elif 'write' in s or 'buf' in s: cat='fortran-io'
    else: cat='o:'+s[:28]
    b[cur//5][cat]+=1; first=False
for k in sorted(b):
    tot=sum(b[k].values()); print('%3d-%3ds n=%4d '%(5*k,5*k+5,tot)+' '.join('%s=%d'%(c,n) for c,n in b[k].most_common(4)))
