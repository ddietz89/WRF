"""Bounded ELF64 LE relocatable comparison; exclude debug, never strip FP code."""
from pathlib import Path
import struct,hashlib

def semantic_object(path):
 data=Path(path).read_bytes()
 assert len(data)<16*2**20 and data[:6]==b'\x7fELF\x02\x01'
 h=struct.unpack_from('<16sHHIQQQIHHHHHH',data)
 assert h[1]==1 and h[2]==62 and h[11]==64, 'ELF64 x86-64 ET_REL only'
 off,n,strings=h[6],h[12],h[13]
 assert 0<n<1024 and off+n*64<=len(data)
 sec=[struct.unpack_from('<IIQQQQIIQQ',data,off+i*64)for i in range(n)]
 def blob(s):
  assert s[4]+s[5]<=len(data)
  return data[s[4]:s[4]+s[5]]
 def cstr(b,i):
  assert 0<=i<len(b);end=b.find(b'\0',i);assert end>=0
  return b[i:end].decode('ascii')
 names_blob=blob(sec[strings]);names=[cstr(names_blob,s[0])for s in sec]
 assert len(set(names))==len(names)
 def section_name(i):
  return names[i] if i<n else 'RESERVED:'+str(i)
 allocated={names[i]:{'type':s[1],'flags':s[2],'size':s[5],'align':s[8],
                    'sha256':None if s[1]==8 else hashlib.sha256(blob(s)).hexdigest()}
            for i,s in enumerate(sec)if s[2]&2}
 assert '.text'in allocated and allocated['.text']['size']>0
 symbols_by_table={};symbols=[]
 for i,s in enumerate(sec):
  if s[1]!=2:continue
  assert s[9]==24 and s[5]%24==0
  sb=blob(sec[s[6]]);entries=[]
  for at in range(s[4],s[4]+s[5],24):
   name,info,other,idx,value,size=struct.unpack_from('<IBBHQQ',data,at)
   row=(cstr(sb,name),info,other,section_name(idx),value,size);entries.append(row)
   if info&15!=4: symbols.append(row) # STT_FILE is the compilation path/name only.
  symbols_by_table[i]=entries
 relocations={}
 for i,s in enumerate(sec):
  if s[1]not in (4,9)or not sec[s[7]][2]&2:continue
  assert s[1]==4 and s[9]==24 and s[5]%24==0,'x86-64 RELA expected'
  rows=[]
  for at in range(s[4],s[4]+s[5],24):
   offset,info,addend=struct.unpack_from('<QQq',data,at)
   rows.append((offset,info&0xffffffff,symbols_by_table[s[6]][info>>32],addend))
  relocations[names[s[7]]]=rows
 return {'allocated_sections':allocated,'allocated_relocations':relocations,'symbols_except_STT_FILE':sorted(symbols)}

def compare_objects(reference,parent):
 a,b=semantic_object(reference),semantic_object(parent)
 assert a==b,'Rebuilt parent differs in allocated section bytes/attributes, runtime relocation, or non-file symbol; stop, no candidate substitution'
 return {'status':'PASS_ALLOCATED_BYTES_RELOCATIONS_NONFILE_SYMBOLS_EXACT',
         'reference_sha256':hashlib.sha256(Path(reference).read_bytes()).hexdigest(),
         'rebuilt_sha256':hashlib.sha256(Path(parent).read_bytes()).hexdigest(),
         'comparison':a,'excluded':'Only nonallocated sections (including debug paths), STT_FILE symbol. All allocated text/rodata/data/bss/unwind sections and their relocations exact.'}
