#include "shared_table.h"
#include <errno.h>
#include <fenv.h>
#include <stdlib.h>
#include <string.h>
_Static_assert(_Generic((MPI_Fint)0,int:1,default:0),"MPI_Fint must be C int");
/* Small admission-only bridge. Public tested owner stays unmodified. */
int thompson_tpi_preflight_c(MPI_Fint f,int allowed,int *enabled) {
 int saved_errno=errno;fenv_t env;int envrc=fegetenv(&env);
 MPI_Comm c=MPI_Comm_f2c(f);
 if(envrc){MPI_Abort(c,91);abort();}
 const char *v=getenv("WRF_EXPERIMENTAL_TPI_NUMA");
 int mode=0,bad=0;
 if(v&&*v){if(!strcmp(v,"1"))mode=1;else if(strcmp(v,"0"))bad=1;}
 const char *threads=getenv("OMP_NUM_THREADS"),*dynamic=getenv("OMP_DYNAMIC");
 if(!allowed||!threads||strcmp(threads,"1")||
    (dynamic&&strcmp(dynamic,"FALSE")&&strcmp(dynamic,"false")&&strcmp(dynamic,"0")))bad=1;
 int lo=0,hi=0,anybad=0,rc;
 rc=MPI_Allreduce(&mode,&lo,1,MPI_INT,MPI_MIN,c);
 if(rc!=MPI_SUCCESS){MPI_Abort(c,rc);abort();}
 rc=MPI_Allreduce(&mode,&hi,1,MPI_INT,MPI_MAX,c);
 if(rc!=MPI_SUCCESS){MPI_Abort(c,rc);abort();}
 rc=MPI_Allreduce(&bad,&anybad,1,MPI_INT,MPI_MAX,c);
 if(rc!=MPI_SUCCESS){MPI_Abort(c,rc);abort();}
 *enabled=mode;
 int status=anybad||lo!=hi?ST_ARGUMENT:(mode?ST_SHARED:ST_PRIVATE);
 if(fesetenv(&env)){MPI_Abort(c,92);abort();}errno=saved_errno;return status;
}
