"""Member-level comparison of two static archives: allocated section bytes,
non-file symbols and relocations per member. Read-only; prints a JSON report."""
import subprocess, sys, json, hashlib, tempfile, os, re, collections
from pathlib import Path

def members(ar):
    names = subprocess.check_output(['ar', 't', ar], text=True).split()
    return names

def extract(ar, d):
    # ar x overwrites duplicate names; record duplicates separately.
    subprocess.check_call(['ar', 'x', os.path.abspath(ar)], cwd=d)

def facts(obj):
    sec = subprocess.check_output(['readelf', '-W', '-S', obj], text=True)
    alloc = {}
    for m in re.finditer(r'\]\s+(\S+)\s+(\S+)\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+(\S*)\s', sec):
        name, typ, off, size, flags = m.groups()
        if 'A' in flags and typ != 'NOBITS' and int(size, 16):
            data = open(obj, 'rb').read()[int(off, 16):int(off, 16) + int(size, 16)]
            alloc[name] = hashlib.sha256(data).hexdigest()
        elif 'A' in flags and typ == 'NOBITS':
            alloc[name] = 'nobits:' + str(int(size, 16))
    syms = subprocess.check_output(['nm', '-S', '--defined-only', obj], text=True, stderr=subprocess.DEVNULL)
    sym = sorted(l for l in syms.splitlines() if l.strip() and ' f ' not in l)
    rel_text = subprocess.check_output(['readelf', '-W', '-r', obj], text=True)
    rel, keep = [], False
    for l in rel_text.splitlines():
        m = re.match(r"Relocation section '([^']+)'", l)
        if m:
            keep = not m.group(1).startswith('.rela.debug')  # debug info is not loaded
            rel.append(l.split(' at offset')[0]) if keep else None
        elif keep and re.match(r'^\s*[0-9a-f]{8,}', l):
            rel.append(re.sub(r'^\s*[0-9a-f]+\s+[0-9a-f]+\s+', '', l))
    return {'alloc': alloc, 'sym': hashlib.sha256('\n'.join(sym).encode()).hexdigest(),
            'rel': hashlib.sha256('\n'.join(rel).encode()).hexdigest(),
            'syms_defined': [l.split()[-1] for l in sym if len(l.split()) == 4 and l.split()[2] in 'TtWD']}

def main(a, b):
    ma, mb = members(a), members(b)
    out = {'a': a, 'b': b, 'a_members': len(ma), 'b_members': len(mb),
           'a_dup': [k for k, v in collections.Counter(ma).items() if v > 1],
           'b_dup': [k for k, v in collections.Counter(mb).items() if v > 1],
           'only_a': sorted(set(ma) - set(mb)), 'only_b': sorted(set(mb) - set(ma)),
           'identical': [], 'differ': {}}
    with tempfile.TemporaryDirectory() as ta, tempfile.TemporaryDirectory() as tb:
        extract(a, ta); extract(b, tb)
        for n in sorted(set(ma) & set(mb)):
            fa, fb = facts(os.path.join(ta, n)), facts(os.path.join(tb, n))
            if fa['alloc'] == fb['alloc'] and fa['sym'] == fb['sym'] and fa['rel'] == fb['rel']:
                out['identical'].append(n)
            else:
                out['differ'][n] = {'sections': sorted(k for k in set(fa['alloc']) | set(fb['alloc'])
                                                       if fa['alloc'].get(k) != fb['alloc'].get(k)),
                                    'symbols_differ': fa['sym'] != fb['sym'], 'relocs_differ': fa['rel'] != fb['rel'],
                                    'syms_only_a': sorted(set(fa['syms_defined']) - set(fb['syms_defined']))[:20],
                                    'syms_only_b': sorted(set(fb['syms_defined']) - set(fa['syms_defined']))[:20]}
    out['n_identical'] = len(out['identical']); out['n_differ'] = len(out['differ'])
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
