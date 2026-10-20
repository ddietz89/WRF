#include <errno.h>
#include <fenv.h>
#include <stdlib.h>
#include <xmmintrin.h>
static int selected_case;
static fenv_t entry_environment;
static int entry_errno;
void observation_case(int n){selected_case=n;}
void reset_observation(void){entry_errno=errno;if(fegetenv(&entry_environment))abort();if(fesetenv(FE_DFL_ENV)||fesetround(selected_case==1?FE_DOWNWARD:FE_TONEAREST)||feclearexcept(FE_ALL_EXCEPT))abort();if(selected_case&&feraiseexcept(FE_DIVBYZERO))abort();errno=ERANGE;}
void read_observation(int *s){unsigned short cw;int e=errno;__asm__ volatile("fnstcw %0":"=m"(cw));s[0]=e;s[1]=fegetround();s[2]=fetestexcept(FE_ALL_EXCEPT);s[3]=(int)_mm_getcsr();s[4]=cw;if(fesetenv(&entry_environment))abort();errno=entry_errno;}
