#define _GNU_SOURCE
/* Compile against the exact codec build's genuine headers and configuration. */
#include "zbuild.h"
#include "deflate.h"
#include <errno.h>
#include <fenv.h>
#include <immintrin.h>
#include <stdint.h>
#include <inttypes.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
extern void parent_slide_hash_avx2(deflate_state *);
extern void candidate_slide_hash_avx2(deflate_state *);
_Static_assert(HASH_SIZE==65536u,"actual hash size required");
_Static_assert(sizeof(Pos)==2,"actual16bit Pos required");
static unsigned cases,calls,current_window,current_pattern;
static void fail(const char *why){fprintf(stderr,"FAIL case=%u window=%u pattern=%u reason=%s\n",cases,current_window,current_pattern,why);exit(1);}
#define CHECK(x) do{if(!(x))fail(#x);}while(0)
struct table {uint8_t *map,*data;Pos *p;size_t map_bytes,capacity,entries;};
static size_t page_size;
static struct table table_new(size_t n){
 struct table a={0};a.entries=n;a.capacity=((n*sizeof(Pos)+64+page_size-1)/page_size)*page_size;a.map_bytes=a.capacity+2*page_size;
 a.map=mmap(NULL,a.map_bytes,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);CHECK(a.map!=MAP_FAILED);
 a.data=a.map+page_size;CHECK(mprotect(a.data,a.capacity,PROT_READ|PROT_WRITE)==0);a.p=(Pos *)(a.data+32);
 CHECK((uintptr_t)a.p%32==0&&n>0&&n%16==0);return a;
}
static void table_drop(struct table a){CHECK(munmap(a.map,a.map_bytes)==0);}
static Pos value(size_t i,unsigned w,unsigned pattern){
 if(!pattern){switch(i%6){case 0:return 0;case 1:return 1;case 2:return (Pos)(w-1);case 3:return (Pos)w;case 4:return (Pos)(w+1);default:return UINT16_MAX;}}
 uint32_t x=(uint32_t)i*1664525u+1013904223u;return (Pos)(x^(x>>16));
}
static void prepare(struct table a,unsigned w,unsigned pattern){
 memset(a.data,0xa5,a.capacity);for(size_t i=0;i<a.entries;i++)a.p[i]=value(i,w,pattern);
}
static void check_output(struct table a,unsigned w,unsigned pattern){
 for(size_t i=0;i<a.entries;i++){Pos original=value(i,w,pattern);Pos expected=original>=w?(Pos)(original-w):0;CHECK(a.p[i]==expected);}
 for(size_t i=0;i<32;i++)CHECK(a.data[i]==0xa5);
 for(size_t i=32+a.entries*sizeof(Pos);i<a.capacity;i++)CHECK(a.data[i]==0xa5);
}
struct native_state{fenv_t env;int err,round,flags;unsigned csr;unsigned short cw;};
static struct native_state native_get(void){
 struct native_state s;memset(&s,0,sizeof s);s.err=errno;CHECK(fegetenv(&s.env)==0);s.round=fegetround();s.flags=fetestexcept(FE_ALL_EXCEPT);s.csr=_mm_getcsr();__asm__ volatile("fnstcw %0":"=m"(s.cw));return s;
}
static void native_equal(struct native_state a,struct native_state b){
 CHECK(a.err==b.err&&a.round==b.round&&a.flags==b.flags&&a.csr==b.csr&&a.cw==b.cw);CHECK(memcmp(&a.env,&b.env,sizeof a.env)==0);
}
static void invoke(void (*fn)(deflate_state *),deflate_state *s,unsigned mode){
 fenv_t original;int saved_errno=errno;CHECK(feholdexcept(&original)==0);CHECK(fesetround(mode?FE_DOWNWARD:FE_TONEAREST)==0);
 if(mode)CHECK(feraiseexcept(FE_INVALID|FE_DIVBYZERO|FE_OVERFLOW|FE_UNDERFLOW|FE_INEXACT)==0);
 errno=EILSEQ;struct native_state before=native_get();fn(s);struct native_state after=native_get();native_equal(before,after);
 CHECK(fesetenv(&original)==0);errno=saved_errno;calls++;
}

enum {WINDOW=32768,REPEATS=262144};
static uint64_t ns(clockid_t id){struct timespec t;CHECK(clock_gettime(id,&t)==0);return(uint64_t)t.tv_sec*1000000000u+(uint64_t)t.tv_nsec;}
int main(int argc,char **argv){
 CHECK(argc==2);void(*fn)(deflate_state *);const char *which=argv[1];
 if(!strcmp(which,"parent"))fn=parent_slide_hash_avx2;else if(!strcmp(which,"candidate"))fn=candidate_slide_hash_avx2;else fail("parent or candidate required");
 long pg=sysconf(_SC_PAGESIZE);CHECK(pg>0);page_size=(size_t)pg;CHECK(page_size%32==0);current_window=WINDOW;current_pattern=1;
 struct table head=table_new(HASH_SIZE),prev=table_new(WINDOW),gold_head=table_new(HASH_SIZE),gold_prev=table_new(WINDOW);
 prepare(head,WINDOW,1);prepare(prev,WINDOW,1);prepare(gold_head,WINDOW,1);prepare(gold_prev,WINDOW,1);
 CHECK(mprotect(gold_head.data,gold_head.capacity,PROT_READ)==0&&mprotect(gold_prev.data,gold_prev.capacity,PROT_READ)==0);
 size_t hn=HASH_SIZE*sizeof(Pos),pn=WINDOW*sizeof(Pos),sc=((sizeof(deflate_state)+page_size-1)/page_size)*page_size;
 uint8_t *raw=mmap(NULL,sc,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);CHECK(raw!=MAP_FAILED);memset(raw,0,sc);
 deflate_state *s=(deflate_state*)raw;s->head=head.p;s->prev=prev.p;s->w_size=WINDOW;s->w_mask=WINDOW-1;s->w_bits=15;
 uint8_t *state_copy=malloc(sc);CHECK(state_copy);memcpy(state_copy,raw,sc);CHECK(mprotect(raw,sc,PROT_READ)==0);
 invoke(fn,s,1);check_output(head,WINDOW,1);check_output(prev,WINDOW,1);CHECK(memcmp(raw,state_copy,sc)==0);
 fenv_t original;int saved_errno=errno;CHECK(feholdexcept(&original)==0);CHECK(fesetround(FE_DOWNWARD)==0);
 CHECK(feraiseexcept(FE_INVALID|FE_DIVBYZERO|FE_OVERFLOW|FE_UNDERFLOW|FE_INEXACT)==0);errno=EILSEQ;
 struct native_state before=native_get();uint64_t wall=0,cpu=0,whole0=ns(CLOCK_PROCESS_CPUTIME_ID);
 for(unsigned i=0;i<REPEATS;i++){
  /* Both complete mutable arrays restored identically BEFORE each measured call. */
  memcpy(head.p,gold_head.p,hn);memcpy(prev.p,gold_prev.p,pn);
  uint64_t w0=ns(CLOCK_MONOTONIC),c0=ns(CLOCK_PROCESS_CPUTIME_ID);
  fn(s);
  uint64_t c1=ns(CLOCK_PROCESS_CPUTIME_ID),w1=ns(CLOCK_MONOTONIC);
  cpu+=c1-c0;wall+=w1-w0;
 }
 uint64_t whole=ns(CLOCK_PROCESS_CPUTIME_ID)-whole0;native_equal(before,native_get());CHECK(cpu>0&&wall>0&&whole>=cpu);
 CHECK(fesetenv(&original)==0);errno=saved_errno;
 check_output(head,WINDOW,1);check_output(prev,WINDOW,1);CHECK(memcmp(raw,state_copy,sc)==0);
 for(size_t i=0;i<HASH_SIZE;i++)CHECK(gold_head.p[i]==value(i,WINDOW,1));
 for(size_t i=0;i<WINDOW;i++)CHECK(gold_prev.p[i]==value(i,WINDOW,1));
 memcpy(head.p,gold_head.p,hn);memcpy(prev.p,gold_prev.p,pn);invoke(fn,s,1);
 check_output(head,WINDOW,1);check_output(prev,WINDOW,1);CHECK(memcmp(raw,state_copy,sc)==0);
 CHECK(munmap(raw,sc)==0);free(state_copy);table_drop(head);table_drop(prev);table_drop(gold_head);table_drop(gold_prev);
 printf("{\"status\":\"PASS_COMPLETE_SLIDE_HASH_FIXED_CALLER_RAW_GUARDS_READONLY_STATE_FENV\",\"arm\":\"%s\",\"head_entries\":%u,\"window_entries\":%u,\"repeats\":%u,\"proof_calls\":%u,\"call_wall_ns\":%" PRIu64 ",\"call_process_cpu_ns\":%" PRIu64 ",\"restore_and_call_process_cpu_ns\":%" PRIu64 ",\"timing_scope\":\"sum of individual complete function calls including clock overhead; full-array restoration outside each call clock\",\"production_or_provider_timing\":false}\n",which,HASH_SIZE,WINDOW,REPEATS,calls,wall,cpu,whole);
 return 0;
}
