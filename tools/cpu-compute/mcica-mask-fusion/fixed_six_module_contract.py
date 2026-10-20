from pathlib import Path
import json,gzip,re,hashlib
NAMES=['module_ra_rrtmg_lw.mod','rrtmg_lw_init.mod','rrtmg_lw_rad.mod','rrtmg_lw_rtrnmc.mod','rrtmg_lw_setcoef.mod','rrtmg_lw_taumol.mod']
def parse(s):
 ts=re.findall(r"'(?:[^']|'')*'|[()]|[^\s()]+",s);i=0
 def val():
  nonlocal i
  t=ts[i];i+=1
  if t=='(':
   a=[]
   while ts[i]!=')':a.append(val())
   i+=1;return a
  assert t!=')'
  return ('Q',t[1:-1])if t.startswith("'")else(int(t)if re.fullmatch(r'-?\d+',t)else('A',t))
 a=[]
 while i<len(ts):a.append(val())
 return a
def symbol_table(x):
 return isinstance(x,list)and bool(x)and len(x)%6==0 and all(isinstance(x[i],int)and all(isinstance(x[i+j],tuple)and x[i+j][0]=='Q'for j in [1,2,3])and isinstance(x[i+4],int)and isinstance(x[i+5],list)for i in range(0,len(x),6))
def pub_table(x):
 return isinstance(x,list)and bool(x)and len(x)%3==0 and all(isinstance(x[i],tuple)and x[i][0]=='Q'and isinstance(x[i+1],int)and isinstance(x[i+2],int)for i in range(0,len(x),3))
def inspect(b):
 s=gzip.decompress(b).decode();h,s=s.split('\n',1);forms=parse(s);idx=[i for i,x in enumerate(forms)if symbol_table(x)];assert len(idx)==1,idx
 k=idx[0];table=forms[k];records={};ids={}
 for i in range(0,len(table),6):
  sid,name,module,bind,scope,body=table[i:i+6];key=(name,module,bind,scope);assert key not in records,key
  records[key]=body;ids[sid]=key
 pi=[i for i,x in enumerate(forms)if pub_table(x)];assert len(pi)==1,pi
 aliases={};pb=forms[pi[0]]
 for i in range(0,len(pb),3):
  alias,ambig,sid=pb[i:i+3];assert alias not in aliases;aliases[alias]=(ambig,ids[sid])
 other=[v for i,v in enumerate(forms)if i not in [k,pi[0]]]
 return h,records,ids,aliases,other

# Fixed-six GFortran15 subset only, audited against GCC13.3 module.cc.
# No normalization. Unknown classes/forms are rejected.
def body_references(records):
 refs=[];namespace_refs=[];counts={'symbols':0,'typespecs':0,'expressions':0}
 def ref(v,where):
  assert isinstance(v,int),(where,v)
  if v:refs.append((where,v))
 def ts(t,where):
  assert len(t)==7 and t[0][0]=='A'and t[0][1]in ['INTEGER','REAL','COMPLEX','LOGICAL','CHARACTER','UNKNOWN','PROCEDURE'],(where,t)
  assert isinstance(t[1],int)and isinstance(t[3],int)and isinstance(t[4],int)and t[5][0]=='A'
  ref(t[2],where+'/interface');counts['typespecs']+=1
  assert isinstance(t[6],list)
  if t[0][1]=='CHARACTER':
   assert len(t[6])in[0,1],t[6]
   if t[6]:expr(t[6][0],where+'/charlen')
  else:assert t[6]==[]
 def expr(e,where):
  if not e:return
  assert isinstance(e,list)and e[0][0]=='A';tag=e[0][1];counts['expressions']+=1
  assert tag in ['CONSTANT','VARIABLE','OP'],(where,tag)
  ts(e[1],where+'/type');assert isinstance(e[2],int)and e[-1]==[],(where,e)
  if tag=='VARIABLE':
   assert len(e)==6 and e[4]==[],(where,e);ref(e[3],where+'/symtree')
  elif tag=='CONSTANT':
   typ=e[1][0][1]
   if typ in ['INTEGER','REAL']:assert len(e)==5 and e[3][0]=='Q',(where,e)
   elif typ=='LOGICAL':assert len(e)==5 and isinstance(e[3],int),(where,e)
   elif typ=='CHARACTER':assert len(e)==6 and isinstance(e[3],int)and e[4][0]=='Q',(where,e)
   elif typ=='COMPLEX':assert len(e)==6 and e[3][0]==e[4][0]=='Q',(where,e)
   else:raise AssertionError((where,e))
  else:
   assert len(e)in[6,7]and e[3][0]=='A',(where,e)
   for i,x in enumerate(e[4:-1]):expr(x,where+'/operand'+str(i))
 def arr(a,where):
  if not a:return
  assert len(a)>=3 and isinstance(a[0],int)and isinstance(a[1],int)and a[2][0]=='A'
  assert a[2][1]in['EXPLICIT','ASSUMED_SHAPE','ASSUMED_SIZE','DEFERRED','ASSUMED_RANK']and len(a)==3+2*(a[0]+a[1]),(where,a)
  for i,x in enumerate(a[3:]):expr(x,where+'/bound'+str(i))
 for key,b in records.items():
  where=key[0][1]+'@'+key[1][1]+'#'+str(key[3]);counts['symbols']+=1
  assert isinstance(key[3],int);namespace_refs.append((where+'/scope',key[3]))
  flavor=b[0][0][1];assert flavor in ['MODULE','PARAMETER','PROCEDURE','VARIABLE']and len(b)==(14 if flavor=='PARAMETER' else 13),(where,b)
  attrs=[x[1]for x in b[0]if isinstance(x,tuple)];assert not set(attrs)&{'CRAY_POINTEE','PDT_TYPE','STRUCTURE','DERIVED','VTYPE'},attrs
  assert b[1]==[] # no components/access field
  ts(b[2],where+'/type');assert isinstance(b[3],int);namespace_refs.append((where+'/formal_ns',b[3]));ref(b[4],where+'/common_next')
  assert isinstance(b[5],list)
  for i,v in enumerate(b[5]):ref(v,where+'/formal_arg'+str(i))
  off=1 if flavor=='PARAMETER' else 0
  if off:expr(b[6],where+'/value')
  arr(b[6+off],where+'/array');ref(b[7+off],where+'/result')
  assert b[8+off]==[]and b[9+off]==[]and b[10+off]==[]and b[11+off]==0 and b[12+off]==0,(where,b[8+off:])
 return refs,namespace_refs,counts

def empty_form(x):
 return isinstance(x,list)and all(empty_form(y)for y in x)

def compare_fixed_six(parent,candidate,expected_pairs):
 assert set(expected_pairs)==set(NAMES)
 rows=[]
 for name in NAMES:
  a=(Path(parent)/name).read_bytes();b=(Path(candidate)/name).read_bytes()
  assert hashlib.sha256(a).hexdigest()==expected_pairs[name]['parent']and hashlib.sha256(b).hexdigest()==expected_pairs[name]['candidate']
  h,ar,ai,ap,ao=inspect(a);j,br,bi,bp,bo=inspect(b)
  assert h==j=="GFORTRAN module version '15' created from module_ra_rrtmg_lw.f90"
  assert all(empty_form(x)for x in ao)and all(empty_form(x)for x in bo),'Unknownotherformmightcontainrefs'
  assert h==j and ar==br and ap==bp and ao==bo
  changed={i for i in set(ai)|set(bi)if ai.get(i)!=bi.get(i)}
  refs,nss,counts=body_references(ar);crefs,cnss,ccounts=body_references(br);assert sorted(refs)==sorted(crefs)and sorted(nss)==sorted(cnss)and counts==ccounts
  hit=[(w,i)for w,i in refs if i in changed];nhit=[(w,i)for w,i in nss if i in changed];assert not hit and not nhit,(name,hit,nhit)
  for w,i in refs:assert i in ai and ai[i]==bi[i],(w,i)
  changed_kinds=[]
  for i in sorted(changed):
   key=ai[i];body=ar[key];flavor=body[0][0][1];assert key[1][1]!=name[:-4]
   assert flavor in ['MODULE','PARAMETER','VARIABLE'],(key,flavor) # actualimports include REALtotplk16/totplnk aswellasCHARACTERrrlw_vsn
   changed_kinds.append({'parent_id':i,'symbol':key[0][1],'source_module':key[1][1],'flavor':flavor})
  rows.append({'module':name,'complete_bodies_and_alias_identities_equal':True,'changed_ids':sorted(changed),'changed_entities':changed_kinds,'all_actual_body_symbol_reference_positions_audited':len(refs),'all_actual_scope_namespace_reference_positions_audited':len(nss),'changed_id_body_reference_hits':hit,'changed_id_namespace_reference_hits':nhit,'every_nonzero_body_symbol_ref_resolves_to_identical_record':True,'subset_shape_counts':counts})
 r={'status':'PASS_FIXED_SIX_NO_CHANGED_ID_USED_BY_ANY_BODY_OR_NAMESPACE_REFERENCE','source_authority':'GCC13.3.0 gcc/fortran/module.cc: mio_symbol4361..4437, mio_typespec2692..2737, mio_formal_arglist3056..3084, mio_expr3543..3777, mio_array_spec2751..2797, mio_symtree_ref3115..3169. Publicofficialmirror https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-13.3.0/gcc/fortran/module.cc','limits':'Only exactactualsixGFortran15files/subset; rejectsDERIVED/CLASS/components/complexref-lists/functions/PDT/namelist/OMP extras/nonzerointrinsicmoduleids. No numericconstant normalization; typespeckind/rank/literalconstants untouched. Diagnostic only, no gate edit.','modules':rows}
 return r
