#define _GNU_SOURCE
/* Compile against the exact codec build's genuine headers and configuration. */
#include "zbuild.h"
#include "deflate.h"
#include <errno.h>
#include <fenv.h>
#include <immintrin.h>
#include <stdint.h>
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
static void one(unsigned w,unsigned pattern){
 cases++;current_window=w;current_pattern=pattern;
 struct table head=table_new(HASH_SIZE),prev=table_new(w);prepare(head,w,pattern);prepare(prev,w,pattern);
 size_t state_capacity=((sizeof(deflate_state)+page_size-1)/page_size)*page_size;
 uint8_t *raw=mmap(NULL,state_capacity,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);CHECK(raw!=MAP_FAILED);memset(raw,0,state_capacity);
 deflate_state *s=(deflate_state *)raw;s->head=head.p;s->prev=prev.p;s->w_size=w;s->w_mask=w-1;
 unsigned bits=0;for(unsigned n=w;n>1;n>>=1)bits++;s->w_bits=bits;
 uint8_t *state_copy=malloc(state_capacity);CHECK(state_copy);memcpy(state_copy,raw,state_capacity);CHECK(mprotect(raw,state_capacity,PROT_READ)==0);
 invoke(parent_slide_hash_avx2,s,pattern);check_output(head,w,pattern);check_output(prev,w,pattern);CHECK(memcmp(raw,state_copy,state_capacity)==0);
 size_t hn=head.entries*sizeof(Pos),pn=prev.entries*sizeof(Pos);Pos *parent_head=malloc(hn),*parent_prev=malloc(pn);CHECK(parent_head&&parent_prev);memcpy(parent_head,head.p,hn);memcpy(parent_prev,prev.p,pn);
 prepare(head,w,pattern);prepare(prev,w,pattern);
 invoke(candidate_slide_hash_avx2,s,pattern);check_output(head,w,pattern);check_output(prev,w,pattern);CHECK(memcmp(head.p,parent_head,hn)==0&&memcmp(prev.p,parent_prev,pn)==0);CHECK(memcmp(raw,state_copy,state_capacity)==0);
 free(parent_head);free(parent_prev);free(state_copy);CHECK(munmap(raw,state_capacity)==0);table_drop(head);table_drop(prev);
}
int main(void){
 long pg=sysconf(_SC_PAGESIZE);CHECK(pg>0);page_size=(size_t)pg;CHECK(page_size%32==0);
 static const unsigned windows[]={256,512,4096,32768};
 for(unsigned i=0;i<sizeof windows/sizeof windows[0];i++)for(unsigned p=0;p<2;p++)one(windows[i],p);
 printf("{\"status\":\"PASS_COMPLETE_SLIDE_HASH_REAL_STATE_FULL_ARRAY_SATURATION_CANARY_READONLY_STATE_NATIVE_FENV\",\"cases\":%u,\"calls\":%u,\"head_entries\":%u,\"timing\":false,\"production_qualification\":false}\n",cases,calls,HASH_SIZE);return 0;
}
