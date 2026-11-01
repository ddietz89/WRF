#include <immintrin.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
int main(int c,char**v){double secs=atof(v[1]);__m256d a[8];for(int i=0;i<8;i++)a[i]=_mm256_set1_pd(1.0+i*1e-9);
__m256d m=_mm256_set1_pd(0.9999999),b=_mm256_set1_pd(1e-9);struct timespec t0,t;clock_gettime(CLOCK_MONOTONIC,&t0);
for(;;){for(int k=0;k<100000;k++)for(int i=0;i<8;i++)a[i]=_mm256_fmadd_pd(a[i],m,b);clock_gettime(CLOCK_MONOTONIC,&t);if(t.tv_sec-t0.tv_sec+(t.tv_nsec-t0.tv_nsec)*1e-9>secs)break;}
double s=0;double o[4];for(int i=0;i<8;i++){_mm256_storeu_pd(o,a[i]);s+=o[0];}printf("%g\n",s>0?0:1);return 0;}
