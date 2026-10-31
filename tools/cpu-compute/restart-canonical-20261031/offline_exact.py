"""N07 offline exact comparison using the reader's unchanged wrf_exact comparator.
Usage: offline_exact.py <reference_run_dir> <candidate_run_dir> <out.json> <time> [<time> ...]
Compares wrfout_d01_<time> pairs and, when both runs have adaptive-steps.json, the ordered
(time, dt) sequence over the candidate's span. Read-only on both run directories."""
import sys, json, hashlib, os
from pathlib import Path
sys.path.insert(0, '/pool/wrf-experiment/wrf-cpu/validation')
sys.path.insert(0, '/pool/wrf-experiment/wrf-cpu/checker-runtime')
import wrf_exact, adaptive_chunk_cache

ref, cand, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
times = sys.argv[4:]
report = {'reference': str(ref), 'candidate': str(cand), 'invocation_id': os.environ.get('INVOCATION_ID'),
          'comparator': 'wrf_exact.compare (unchanged reader library)', 'comparisons': {}}
for t in times:
    name = 'wrfout_d01_' + t
    records = []
    restore = adaptive_chunk_cache.install(wrf_exact, records)
    try:
        r = wrf_exact.compare(str(ref / name), str(cand / name), expected_times=[t])
    finally:
        restore()
    report['comparisons'][name] = {'status': r['status'], 'errors': r['errors'][:20], 'n_errors': len(r['errors'])}

def steps(d):
    p = d / 'adaptive-steps.json'
    return [(x['time'], x['dt_text']) for x in json.loads(p.read_text())] if p.exists() else None

rs, cs = steps(ref), steps(cand)
if rs is not None and cs is not None:
    span = [x for x in rs if x[0] > cs[0][0] or x == cs[0]]
    span = [x for x in rs if cs[0][0] <= x[0] <= cs[-1][0]]
    report['steps'] = {'candidate_count': len(cs), 'reference_span_count': len(span), 'identical': span == cs,
                       'first_difference': next(({'i': i, 'ref': a, 'cand': b} for i, (a, b) in enumerate(zip(span, cs)) if a != b), None)}
report['status'] = 'PASS' if all(v['status'] == 'PASS' for v in report['comparisons'].values()) and report.get('steps', {}).get('identical', True) else 'FAIL'
out.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'status': report['status'], 'files': {k: v['status'] for k, v in report['comparisons'].items()}, 'steps': report.get('steps')}))
