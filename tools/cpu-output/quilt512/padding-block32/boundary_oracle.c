/* Separate twelfth oracle; original eleven-case fixture is not included/edited.
 * Include exact production source to call its actual private AVX2 helper. */
#define _GNU_SOURCE
#include <fenv.h>
#include "candidate_root_chunk_provider.c"
#pragma STDC FENV_ACCESS ON
struct fpstate { int error,flags,round; unsigned mxcsr; unsigned short cw; };
static struct fpstate snap(void) {
 struct fpstate s;s.error=errno;s.flags=fetestexcept(FE_ALL_EXCEPT);
 s.round=fegetround();__asm__ volatile("stmxcsr %0":"=m"(s.mxcsr));
 __asm__ volatile("fnstcw %0":"=m"(s.cw));return s;
}
static int same(struct fpstate a,struct fpstate b) {
 return a.error==b.error&&a.flags==b.flags&&a.round==b.round&&
        a.mxcsr==b.mxcsr&&a.cw==b.cw;
}
#define CHECK(x) do{if(!(x)){fprintf(stderr,"FAIL line=%d expression=%s\n",__LINE__,#x);return 2;}}while(0)
int main(void) {
#if SHUF4_X86
 __builtin_cpu_init();CHECK(__builtin_cpu_supports("avx2"));
 fenv_t entry;CHECK(fegetenv(&entry)==0);int entry_errno=errno;
 unsigned char src[512],readonly[512],out[512],expected[512];
 unsigned checks=0;
 for(unsigned mode=0;mode<2;mode++)for(size_t residue=0;residue<33;residue++) {
  /* 32..63 exercises one actual wide block + every remainder; final case empty. */
  size_t active=residue==32?0:32+residue;
  size_t prefix=5,suffix=7,stride=prefix+active+suffix;
  size_t base=19; /* source+1 and destination+19+5 deliberately misaligned. */
  CHECK(base+4*stride+16<=sizeof out && 1+4*active<=sizeof src);
  for(size_t i=0;i<sizeof src;i++)src[i]=(unsigned char)(i*73u+(i>>3)*19u+11u);
  memcpy(readonly,src,sizeof src);
  for(size_t i=0;i<sizeof out;i++)out[i]=expected[i]=(unsigned char)(0xa5u^(i*29u));
  /* Independent byteplane reference, no production scalar helper reuse. */
  for(size_t plane=0;plane<4;plane++)for(size_t i=0;i<active;i++)
   expected[base+plane*stride+prefix+i]=src[1+4*i+plane];
  CHECK(feclearexcept(FE_ALL_EXCEPT)==0);
  CHECK(fesetround(mode?FE_UPWARD:FE_TONEAREST)==0);
  if(mode)CHECK(feraiseexcept(FE_INEXACT|FE_DIVBYZERO)==0);
  errno=mode?EDOM:0;struct fpstate before=snap();
  shuffle4_avx2(out+base+prefix,stride,src+1,4*active);
  struct fpstate after=snap();CHECK(same(before,after));
  /* Whole-buffer compare includes every plane prefix/suffix and outer canaries. */
  CHECK(memcmp(out,expected,sizeof out)==0);
  CHECK(memcmp(src,readonly,sizeof src)==0);checks++;
 }
 CHECK(fesetenv(&entry)==0);errno=entry_errno;
 printf("PASS_COMBINED8DB_SEPARATE_BOUNDARY_ORACLE residues=32 empty=1 fpstates=2 checks=%u original11fixture_unchanged=1\n",checks);
 return 0;
#else
 fprintf(stderr,"UNAVAILABLE actual AVX2 execution requires x86\n");return 3;
#endif
}
