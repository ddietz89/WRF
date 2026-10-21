"""Ordered GNU/BSD regular ar payload inventory; metadata/index records excluded."""
from pathlib import Path
import hashlib

def inventory(path):
 data=Path(path).read_bytes()
 if data[:8]!=b'!<arch>\n':raise ValueError('regular archive required')
 pos=8;names=b'';counts={};out=[]
 while pos<len(data):
  if pos+60>len(data):raise ValueError('truncated header')
  h=data[pos:pos+60]
  if h[58:60]!=b'`\n':raise ValueError('invalid header trailer')
  raw=h[:16].decode('ascii').rstrip();size=int(h[48:58]);pos+=60
  if size<0 or pos+size>len(data):raise ValueError('truncated payload')
  payload=data[pos:pos+size];pos+=size+(size%2)
  if pos>len(data):raise ValueError('missing alignment')
  if raw=='//':names=payload;continue
  if raw in ['/', '/SYM64/']:continue
  if raw.startswith('#1/'):
   n=int(raw[3:]);name=payload[:n].rstrip(b'\0').decode('utf-8');payload=payload[n:]
  elif raw.startswith('/')and raw[1:].isdigit():
   off=int(raw[1:]);end=names.find(b'/\n',off)
   if off>=len(names)or end<0:raise ValueError('invalid long name')
   name=names[off:end].decode('utf-8')
  else:name=raw.removesuffix('/')
  counts[name]=counts.get(name,0)+1
  out.append({'name':name,'occurrence':counts[name],'bytes':len(payload),'sha256':hashlib.sha256(payload).hexdigest()})
 if pos!=len(data):raise ValueError('trailing bytes')
 return out

def verify_only(parent,candidate,name,new_object):
 a,b=inventory(parent),inventory(candidate)
 if len(a)!=len(b):raise AssertionError('archive count changed')
 wanted=hashlib.sha256(Path(new_object).read_bytes()).hexdigest();changed=[]
 for idx,(x,y)in enumerate(zip(a,b)):
  if (x['name'],x['occurrence'])!=(y['name'],y['occurrence']):raise AssertionError('ordered identity changed')
  if x['name']==name:
   if y['sha256']!=wanted:raise AssertionError('replacement object mismatch')
   changed.append(idx)
  elif x!=y:raise AssertionError(('other occurrence changed',x,y))
 if len(changed)!=1:raise AssertionError('target must be unique')
 return {'total_occurrences':len(a),'unchanged_occurrences':len(a)-1,'replaced_index':changed[0],'parent':a,'candidate':b}
