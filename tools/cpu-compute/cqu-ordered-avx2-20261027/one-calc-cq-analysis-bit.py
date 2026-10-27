"""Read-only fixed GNU13.3 metadata comparison, no admission or MOD rewrite."""
from pathlib import Path
import gzip,re,hashlib

def check(parent,candidate):
    a=gzip.decompress(Path(parent).read_bytes()).decode()
    b=gzip.decompress(Path(candidate).read_bytes()).decode()
    token=re.compile(r"'(?:[^']|'')*'|[()]|[^\s()]+")
    aa=token.findall(a);bb=token.findall(b)
    prefix=['4733',"'calc_cq'","'module_big_step_utilities_em'","''",'1','(','(','PROCEDURE']
    hits=[i for i in range(len(aa)-len(prefix)+1)if aa[i:i+len(prefix)]==prefix]
    assert len(hits)==1,('CALC_CQ_DEFINITION_ID_OR_OWNER_DIFFERENCE',hits)
    i=hits[0]+len(prefix);end=aa.index(')',i);attrs=aa[i:end]
    assert 'SUBROUTINE'in attrs and 'IMPLICIT_PURE'in attrs and 'ELEMENTAL'not in attrs
    assert 'ARRAY_OUTER_DEPENDENCY'not in attrs
    expected=aa[:end]+['ARRAY_OUTER_DEPENDENCY']+aa[end:]
    assert bb==expected,'ADDITIONAL_OR_DIFFERENT_PUBLIC_MOD_TOKEN_DELTA'
    assert bb.count('ARRAY_OUTER_DEPENDENCY')==aa.count('ARRAY_OUTER_DEPENDENCY')+1
    sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
    return {'status':'PASS_EXACT_ONE_CALC_CQ_ARRAY_OUTER_DEPENDENCY_ADDITION_ONLY','definition_id':4733,'procedure':'calc_cq','owner':'module_big_step_utilities_em','added_only':'ARRAY_OUTER_DEPENDENCY','IMPLICIT_PURE_retained':True,'parent_raw_sha256':sha(parent),'candidate_raw_sha256':sha(candidate),'raw_bytes_exact':Path(parent).read_bytes()==Path(candidate).read_bytes(),'all_other_literal_typed_tokens_IDs_signatures_attributes_exact':True,'parent_tokens':len(aa),'candidate_tokens':len(bb),'artifact_rewritten':False,'scope':'Read-only structural proof only; root admission separately required. GNU13.3 ordinary non-elemental direct-call route, no universal or rebuilt-caller assurance.'}
