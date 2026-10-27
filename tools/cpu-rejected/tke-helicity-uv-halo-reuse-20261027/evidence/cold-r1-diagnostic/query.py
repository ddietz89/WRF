from pathlib import Path
import json,hashlib,struct
rows=[{'path': '/pool/wrf-experiment/wrf-cpu/kernels/currentda1c-uv-protocol512-arm0-hpc01-r1/work/protocol/physical.rank7.bin', 'sha256': 'bf0d6cd0879d5a7cf83ecbf2960f9ec298fbbbf785f6d480b4cb9e9e1e3f5740', 'bytes': 16099840, 'warm5': [14, 0, 32, 8096, 895], 'batch5': [34, 0, 0, 8064, 895]}, {'path': '/pool/wrf-experiment/wrf-cpu/kernels/currentda1c-uv-protocol512-arm1-hpc02-r1/work/protocol/physical.rank7.bin', 'sha256': 'c0032c2eccd4d039b5c67cc708c66e431cd823a99a70feeed9e3d3051c8f676e', 'bytes': 16099840, 'warm5': [34, 0, 32, 8096, 895], 'batch5': [34, 0, 0, 8064, 895]}]
blobs=[];files=[]
for r in rows:
 p=Path(r['path']);s=p.stat();assert s.st_uid==1000 and s.st_size==r['bytes']==16099840
 z=p.read_bytes();t=p.stat();assert (s.st_dev,s.st_ino,s.st_mode,s.st_uid,s.st_gid,s.st_size,s.st_mtime_ns,s.st_ctime_ns)==(t.st_dev,t.st_ino,t.st_mode,t.st_uid,t.st_gid,t.st_size,t.st_mtime_ns,t.st_ctime_ns)
 assert hashlib.sha256(z).hexdigest()==r['sha256'];blobs.append(z);files.append({'path':str(p),'sha256':r['sha256'],'bytes':len(z),'uid':s.st_uid})
a,b=blobs;stride=8049920
words=[];count=0
for off in range(0,len(a),4):
 if a[off:off+4]!=b[off:off+4]:
  count+=1
  if len(words)<16:words.append({'absolute_byte_offset':off,'record':off//stride,'record_offset':off%stride,'header_word_index':(off%stride)//4 if off%stride<32 else None,'parent_u32':int.from_bytes(a[off:off+4],'big'),'candidate_u32':int.from_bytes(b[off:off+4],'big')})
records=[]
for j in range(2):
 x=a[j*stride:(j+1)*stride];y=b[j*stride:(j+1)*stride]
 records.append({'record':j,'parent_header':struct.unpack('>8i',x[:32]),'candidate_header':struct.unpack('>8i',y[:32]),'header_equal':x[:32]==y[:32],'full_physical_and_intermediate_readset_exact':x[32:]==y[32:],'parent_physical_sha256':hashlib.sha256(x[32:]).hexdigest(),'candidate_physical_sha256':hashlib.sha256(y[32:]).hexdigest()})
out={'status':'PASS_DIAGNOSTIC_ONLY_ORIGINAL_STRICT_WAVE_FAIL_RETAINED','files':files,'differing_u32_count':count,'first_differences':words,'records':records,'fullraw_equal':a==b,'no_acceptance_relaxation':True}
s=json.dumps(out);assert len(s)<65536;print(s)
