/* Private ABI-only pure-subroutine bridge. No arithmetic/state/allocation. */
#include <stdint.h>
extern int wrf_cqu_ordered(const float*,float*,float*,int,int,int,int,int64_t,int64_t,int64_t);
void wrf_cqu_ordered_sub(const float*m,float*o,float*q,int n,int ns,int nk,int nj,
                         int64_t sk,int64_t sj,int64_t ss,int*admitted){
 *admitted=wrf_cqu_ordered(m,o,q,n,ns,nk,nj,sk,sj,ss);
}
