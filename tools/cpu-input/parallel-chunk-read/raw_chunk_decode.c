#define _GNU_SOURCE
#include "raw_chunk_decode.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sched.h>
#include <zlib.h>
#include <limits.h>
#include <H5FDsec2.h>

#define DIM_T 1u
#define DIM_L 32u
#define DIM_Y 1139u
#define DIM_X 1499u
#define CHK_T 1u
#define CHK_L 32u
#define CHK_Y 570u
#define CHK_X 750u

#define NOMINAL_BYTES ((size_t)CHK_T*CHK_L*CHK_Y*CHK_X*4u)   /* 54720000 */
#define FIELD_BYTES  ((size_t)DIM_T*DIM_L*DIM_Y*DIM_X*4u)     /* 218542208 */
#define MAX_RAW_PER_CHUNK ((uint64_t)64u*1024u*1024u)
#define MAX_COMPRESSED_TOTAL ((uint64_t)256u*1024u*1024u)

/* chunk coords in canonical iteration order: (0,0,0,0),(0,0,0,750),(0,0,570,0),(0,0,570,750) */
static const hsize_t COORD[4][4] = {
  {0,0,0,0}, {0,0,0,CHK_X}, {0,0,CHK_Y,0}, {0,0,CHK_Y,CHK_X}
};
static const size_t COORD_FY[4] = {0,0,CHK_Y,CHK_Y};
static const size_t COORD_FX[4] = {0,CHK_X,0,CHK_X};

typedef enum { JOB_UNSTARTED=0, JOB_OK=1, JOB_BAD=2 } job_state;

typedef struct {
  int idx;
  int cpu;
  unsigned char *comp;  /* compressed raw chunk (owned by scratch) */
  size_t comp_len;
  unsigned char *dec;   /* decoded, still shuffled (nominal bytes) */
  unsigned char *uns;   /* unshuffled (nominal bytes) */
  job_state st;
  int z_rc;
  char msg[96];
} job_t;

typedef struct {
  job_t *job;
  pthread_t tid;
  int started;
} worker_t;

static void put_why(char *why, size_t cap, const char *msg){
  if(!why || cap==0) return;
  size_t n=strlen(msg); if(n>=cap) n=cap-1;
  memcpy(why,msg,n); why[n]='\0';
}

/* Workers: decode one chunk from shuffled-deflated to unshuffled byte planes. */
static void *worker_main(void *arg){
  job_t *j = (job_t*)arg;
  char tmp[96];
  z_stream zs; memset(&zs,0,sizeof zs);
  int irc = inflateInit(&zs);
  if(irc != Z_OK){ j->st=JOB_BAD; j->z_rc=irc;
    snprintf(tmp,sizeof tmp,"inflateInit rc=%d",irc); memcpy(j->msg,tmp,strlen(tmp)+1); return NULL; }
  zs.next_in = j->comp; zs.avail_in = (uInt)j->comp_len;
  zs.next_out = j->dec; zs.avail_out = (uInt)NOMINAL_BYTES;
  int rc = inflate(&zs, Z_FINISH);
  uint64_t total_in = (uint64_t)zs.total_in;
  uint64_t total_out = (uint64_t)zs.total_out;
  int end_rc = inflateEnd(&zs);
  if(rc != Z_STREAM_END || total_in != (uint64_t)j->comp_len || total_out != (uint64_t)NOMINAL_BYTES || end_rc != Z_OK){
    j->st=JOB_BAD; j->z_rc=rc;
    snprintf(tmp,sizeof tmp,"inflate rc=%d in=%llu/%llu out=%llu/%llu",rc,
      (unsigned long long)total_in,(unsigned long long)j->comp_len,
      (unsigned long long)total_out,(unsigned long long)NOMINAL_BYTES);
    memcpy(j->msg,tmp,strlen(tmp)+1); return NULL;
  }
  /* unshuffle: nominal/4 words; byte planes layout produced by HDF5 shuffle:
     plane[p][w] = input byte for word w, byte-order position p. */
  size_t nwords = NOMINAL_BYTES/4u;
  const unsigned char *p0=j->dec, *p1=j->dec+nwords, *p2=j->dec+2*nwords, *p3=j->dec+3*nwords;
  unsigned char *o=j->uns;
  for(size_t w=0; w<nwords; w++){
    o[0]=p0[w]; o[1]=p1[w]; o[2]=p2[w]; o[3]=p3[w]; o+=4;
  }
  j->st=JOB_OK; j->z_rc=Z_OK;
  return NULL;
}

static int pin_self(int cpu){
  cpu_set_t set; CPU_ZERO(&set); CPU_SET(cpu,&set);
  int rc=pthread_setaffinity_np(pthread_self(), sizeof set, &set);
  if(rc) return rc;
  cpu_set_t got; if(pthread_getaffinity_np(pthread_self(),sizeof got,&got)) return -1;
  return CPU_EQUAL(&set,&got)?0:-1;
}

static void *worker_pinned(void *arg){
  /* wrapper to pin before running; job failure recorded via job state */
  job_t *j = (job_t*)arg;
  if(pin_self(j->cpu) != 0){ j->st=JOB_BAD; j->z_rc=-1;
    strncpy(j->msg,"affinity set failed",sizeof j->msg); j->msg[sizeof j->msg-1]='\0'; return NULL; }
  return worker_main(arg);
}

static int cpus_distinct(const int cpus[4]){
  for(int a=0;a<4;a++) if(cpus[a]<0 || cpus[a]>=CPU_SETSIZE) return 0;
  for(int a=0;a<4;a++) for(int b=a+1;b<4;b++) if(cpus[a]==cpus[b]) return 0;
  return 1;
}

/* Owner-only fixed synthetic admission. Unsupported != HDF metadata failure. */
static int check_metadata(hid_t dset, char *why, size_t whycap){
  int rc=-1; hid_t sp=-1,ft=-1,dcpl=-1,file=-1,fapl=-1;
  hsize_t dims[4]={0},chunk[4]={0}; unsigned intent=~0u,opts=~0u;
#define META_FAIL(message) do {put_why(why,whycap,message);rc=-1;goto done;}while(0)
#define DECLINE(message) do {put_why(why,whycap,message);rc=0;goto done;}while(0)
  file=H5Iget_file_id(dset); if(file<0) META_FAIL("file id");
  if(H5Fget_intent(file,&intent)<0) META_FAIL("file intent");
  if(intent!=H5F_ACC_RDONLY) DECLINE("not readonly");
  fapl=H5Fget_access_plist(file);if(fapl<0) META_FAIL("file access plist");
  hid_t driver=H5Pget_driver(fapl);if(driver<0) META_FAIL("file driver");
  if(driver!=H5FD_SEC2) DECLINE("not SEC2 serial");
  sp=H5Dget_space(dset);if(sp<0) META_FAIL("space");
  H5S_class_t cls=H5Sget_simple_extent_type(sp);if(cls==H5S_NO_CLASS) META_FAIL("space class");
  if(cls!=H5S_SIMPLE) DECLINE("not simple");
  int rank=H5Sget_simple_extent_ndims(sp);if(rank<0) META_FAIL("rank");
  if(rank!=4) DECLINE("rank != 4");
  if(H5Sget_simple_extent_dims(sp,dims,NULL)<0) META_FAIL("dims");
  if(dims[0]!=DIM_T||dims[1]!=DIM_L||dims[2]!=DIM_Y||dims[3]!=DIM_X) DECLINE("dims mismatch");
  ft=H5Dget_type(dset);if(ft<0) META_FAIL("type");
  htri_t le=H5Tequal(ft,H5T_IEEE_F32LE),native=H5Tequal(ft,H5T_NATIVE_FLOAT);
  if(le<0||native<0) META_FAIL("type equality");
  if(le!=1||native!=1) DECLINE("not native IEEE float32LE");
  dcpl=H5Dget_create_plist(dset);if(dcpl<0) META_FAIL("dcpl");
  H5D_layout_t layout=H5Pget_layout(dcpl);if(layout==H5D_LAYOUT_ERROR) META_FAIL("layout");
  if(layout!=H5D_CHUNKED) DECLINE("not chunked");
  rank=H5Pget_chunk(dcpl,4,chunk);if(rank<0) META_FAIL("chunk dimensions");
  if(rank!=4||chunk[0]!=CHK_T||chunk[1]!=CHK_L||chunk[2]!=CHK_Y||chunk[3]!=CHK_X) DECLINE("chunk dimensions mismatch");
  if(H5Pget_chunk_opts(dcpl,&opts)<0) META_FAIL("chunk options");
  if(opts!=0) DECLINE("nonzero chunk options");
  int nf=H5Pget_nfilters(dcpl);if(nf<0) META_FAIL("filter count");
  if(nf!=2) DECLINE("filter count !=2");
  for(unsigned i=0;i<2;i++){
    unsigned flags=0,cd[8]={0},config=0;size_t n=8;char name[64]={0};
    H5Z_filter_t filter=H5Pget_filter2(dcpl,i,&flags,&n,cd,sizeof name,name,&config);
    if(filter<0) META_FAIL("get filter");
    if(filter!=(i==0?H5Z_FILTER_SHUFFLE:H5Z_FILTER_DEFLATE)||flags!=H5Z_FLAG_OPTIONAL||n!=1||cd[0]!=(i==0?4u:2u)||config!=3u) DECLINE("filter mismatch");
  }
  rc=1;
done:
  if(dcpl>=0&&H5Pclose(dcpl)<0) rc=-1;
  if(ft>=0&&H5Tclose(ft)<0) rc=-1;
  if(sp>=0&&H5Sclose(sp)<0) rc=-1;
  if(fapl>=0&&H5Pclose(fapl)<0) rc=-1;
  if(file>=0&&H5Fclose(file)<0) rc=-1;
#undef META_FAIL
#undef DECLINE
  return rc;
}

int raw_parallel_read(hid_t dset, unsigned char *out, size_t out_bytes,
                      const int cpus[4], char *why, size_t whycap){
  if(out_bytes != FIELD_BYTES){ put_why(why,whycap,"out_bytes mismatch"); return -1; }
  if(!out){ put_why(why,whycap,"out NULL"); return -1; }
  if(!cpus || !cpus_distinct(cpus)){ put_why(why,whycap,"cpus not distinct"); return -1; }

  cpu_set_t allowed;
  if(pthread_getaffinity_np(pthread_self(),sizeof allowed,&allowed)) return -1;
  for(int i=0;i<4;i++) if(!CPU_ISSET(cpus[i],&allowed)){put_why(why,whycap,"CPU outside allowed mask");return -1;}
  int supported=check_metadata(dset,why,whycap);if(supported!=1)return supported;

  /* one serial owner: the caller's single main thread performs all HDF5 calls */
  job_t jobs[4]; worker_t wkr[4];
  memset(jobs,0,sizeof jobs);
  memset(wkr,0,sizeof wkr);
  unsigned char *scratch = NULL;
  uint64_t comp_sum = 0;
  int rc = -1;

  for(int k=0;k<4;k++){
    hsize_t sz = 0; unsigned mask = 0; haddr_t addr = 0;
    if(H5Dget_chunk_info_by_coord(dset, COORD[k], &mask, &addr, &sz) < 0){
      put_why(why,whycap,"chunk_info failed"); return -1; /* may not be a valid chunk coord */
    }
    if(mask != 0u){ put_why(why,whycap,"coord not allocated / masked"); return 0; }
    if(addr == HADDR_UNDEF || sz == 0u || (uint64_t)sz > MAX_RAW_PER_CHUNK){ put_why(why,whycap,"chunk size out of range"); return 0; }
    hsize_t storage=0;
    if(H5Dget_chunk_storage_size(dset,COORD[k],&storage)<0){put_why(why,whycap,"chunk storage size");return -1;}
    if(storage!=sz){put_why(why,whycap,"chunk index/storage mismatch");return -1;}
    jobs[k].idx = k; jobs[k].cpu = cpus[k];
    jobs[k].comp_len = (size_t)sz;
    comp_sum += (uint64_t)sz;
    if(comp_sum > MAX_COMPRESSED_TOTAL){ put_why(why,whycap,"compressed total exceeds bound"); return 0; }
  }

  /* Scratch: compressed (sum) + 2*NOMINAL*(decoded/unshuffled) per chunk. Bound 4*64MiB compressed + 4*nominal*2. */
  uint64_t scratch_bytes = 0;
  {
    uint64_t comp_cap = 0; for(int k=0;k<4;k++) comp_cap += (uint64_t)jobs[k].comp_len;
    uint64_t dec = (uint64_t)NOMINAL_BYTES*2u*4u;
    if(comp_cap > (uint64_t)UINT64_MAX - dec){ put_why(why,whycap,"scratch overflow"); return -1; }
    scratch_bytes = comp_cap + dec;
  }
  if(scratch_bytes==0 || scratch_bytes>(uint64_t)SIZE_MAX || scratch_bytes>UINT64_C(1073741824)){
    put_why(why,whycap,"scratch budget overflow");return -1;
  }
  _Static_assert(NOMINAL_BYTES==54720000u,"nominal chunk bytes");
  _Static_assert(FIELD_BYTES==218542208u,"field bytes");
  _Static_assert(NOMINAL_BYTES<=UINT_MAX,"inflate output bound");
  _Static_assert(MAX_RAW_PER_CHUNK<=UINT_MAX,"inflate input bound");
  scratch = (unsigned char*)malloc((size_t)scratch_bytes);
  if(!scratch){ put_why(why,whycap,"scratch malloc failed"); return -1; }

  { size_t off = 0;
    for(int k=0;k<4;k++){ jobs[k].comp = scratch + off; off += jobs[k].comp_len; }
    for(int k=0;k<4;k++){ jobs[k].dec = scratch + off; off += NOMINAL_BYTES; }
    for(int k=0;k<4;k++){ jobs[k].uns = scratch + off; off += NOMINAL_BYTES; }
    if(off!=(size_t)scratch_bytes){put_why(why,whycap,"scratch partition");goto cleanup;}
  }

  /* serial HDF5 raw reads; mask is OUTPUT, init 0; verify returned mask still 0 */
  for(int k=0;k<4;k++){
    uint32_t mask=0;
    if(H5Dread_chunk(dset, H5P_DEFAULT, COORD[k], &mask, jobs[k].comp) < 0){
      put_why(why,whycap,"H5Dread_chunk failed"); rc=-1; goto cleanup;
    }
    if(mask!=0){ /* one returned bitmask; set bits mean skipped filters */
      put_why(why,whycap,"H5Dread_chunk reported nonzero filter mask"); rc=-1; goto cleanup;
    }
  }

  /* start up to 4 pinned workers; partial create -> join created, clean error */
  int started = 0;
  for(int k=0;k<4;k++){
    if(pthread_create(&wkr[k].tid, NULL, worker_pinned, &jobs[k]) != 0){
      put_why(why,whycap,"pthread_create failed");
      /* join those already started, no partial results */
      for(int a=0;a<started;a++) if(pthread_join(wkr[a].tid,NULL)!=0) abort();
      rc = -1; goto cleanup;
    }
    wkr[k].started = 1; started++;
  }

  /* Failed join is fail-stop: a possibly live worker still owns scratch. */
  for(int k=0;k<4;k++) if(pthread_join(wkr[k].tid,NULL)!=0) abort();
  for(int k=0;k<4;k++) if(jobs[k].st!=JOB_OK){
    put_why(why,whycap,jobs[k].msg);rc=-1;goto cleanup;
  }
  /* Validate every crop span BEFORE the first caller-buffer write. */
  for(size_t k=0;k<4;k++){
    size_t fy=COORD_FY[k],fx=COORD_FX[k];
    size_t ny=CHK_Y<DIM_Y-fy?CHK_Y:DIM_Y-fy,nx=CHK_X<DIM_X-fx?CHK_X:DIM_X-fx;
    for(size_t l=0;l<CHK_L;l++)for(size_t y=0;y<ny;y++){
      size_t src=(l*CHK_Y+y)*CHK_X*4u,dst=((l*DIM_Y+fy+y)*DIM_X+fx)*4u,n=nx*4u;
      if(src>NOMINAL_BYTES||n>NOMINAL_BYTES-src||dst>out_bytes||n>out_bytes-dst){
        put_why(why,whycap,"crop bounds");rc=-1;goto cleanup;
      }
    }
  }
  /* crop valid rows precisely to C-order full destination; all 32 planes */
  {
    for(int k=0;k<4;k++){
      size_t fy = COORD_FY[k], fx = COORD_FX[k];
      size_t ylim = CHK_Y; if(fy+ylim > DIM_Y) ylim = DIM_Y - fy;
      size_t xlim = CHK_X; if(fx+xlim > DIM_X) xlim = DIM_X - fx;
      for(size_t l=0; l<CHK_L; l++){
        for(size_t y=0; y<ylim; y++){
          const unsigned char *src = jobs[k].uns + (((l*CHK_Y + y)*CHK_X)*4u);
          size_t dst_off = ((((size_t)l*DIM_Y) + (fy+y))*DIM_X + fx)*4u;
          size_t n = xlim*4u;
          /* bounds already exact: 4 chunks cover full plane, no overflow */
          memcpy(out + dst_off, src, n);
        }
      }
    }
  }
  rc = 1;
cleanup:
  if(scratch){ free(scratch); scratch = NULL; }
  return rc;
}
