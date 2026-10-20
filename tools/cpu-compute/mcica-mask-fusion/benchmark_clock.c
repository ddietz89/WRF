#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
int64_t bench_clock(void){struct timespec t;int e=errno;if(clock_gettime(CLOCK_MONOTONIC_RAW,&t))abort();errno=e;return (int64_t)t.tv_sec*1000000000LL+t.tv_nsec;}

int64_t bench_cpu_clock(void){struct timespec t;int e=errno;if(clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&t))abort();errno=e;return (int64_t)t.tv_sec*1000000000LL+t.tv_nsec;}
