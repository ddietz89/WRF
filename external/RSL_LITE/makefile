OBJSL   = c_code.o buf_for_proc.o rsl_malloc.o rsl_bcast.o task_for_point.o period.o swap.o cycle.o f_pack.o f_xpose.o
OBJS    = $(OBJSL)
OPTS    = $(PLUSFLAG)
FFLAGS  =  $(OPTS)
LIBS    = 
M4      = m4 -Uinclude -Uindex -Ulen
AR      = ar
CFLAGS = $(PLUSFLAG)
CPPFLAGS =
FFLAGS =

# Qualified pure-MPI INTEGER32 width5/6 whole-block copy; independent opt-out.
# Kind-changing flags are excluded here and the Fortran interface checks INTEGER32.
WRF_RSL_WIDE_PRIVATE_VECTOR_COPY ?= 1
WRF_RSL_FC_VERSION := $(shell $(lastword $(FC)) -dumpfullversion 2>/dev/null)
WRF_RSL_CC_VERSION := $(shell $(firstword $(CC)) -dumpfullversion 2>/dev/null)
WRF_RSL_COPY_ENABLED :=
ifeq ($(WRF_RSL_WIDE_PRIVATE_VECTOR_COPY),1)
ifeq ($(WRF_RSL_FC_VERSION),13.3.0)
ifeq ($(WRF_RSL_CC_VERSION),13.3.0)
ifeq ($(strip $(OMP)$(OMPCPP)$(OMPCC)),)
ifeq ($(findstring -fopenmp,$(FFLAGS) $(CFLAGS) $(CPPFLAGS)),)
ifeq ($(filter -fdefault-integer-8 -finteger-4-integer-8 -fdefault-real-8 -freal-4-real-8,$(FFLAGS)),)
WRF_RSL_COPY_ENABLED := 1
override CPPFLAGS += -DWRF_RSL_WIDE_PRIVATE_VECTOR_COPY=1
OBJSL += wrf_rsl_pack_wide_i32.o
endif
endif
endif
endif
endif
endif

# These .F files are compiled in frame but leave behind auto-gen files here
F_FILES = \
 feedback_domain_em_part1.F \
 feedback_domain_em_part2.F \
 force_domain_em_part2.F    \
 interp_domain_em_part1.F   \
 interp_domain_em_part2.F   \
 interp_domain_em_part3.F   \
 interp_domain_em_small.F

# These will be the files we need to clean up
F90_FILES = $(foreach file,$(F_FILES),$(patsubst %.F,%.f90,$(file)))


.SUFFIXES:      .F90 .F .f .o .code

all : librsl_lite.a

librsl_lite.a:          $(OBJS)
			/bin/rm -f librsl_lite.a
			$(AR) cr librsl_lite.a $(OBJSL)

c_code.o:	        c_code.c
			$(CC) $(CFLAGS) -c c_code.c

period.o:	        period.c
			$(CC) $(CFLAGS) -c period.c

swap.o:	                swap.c
			$(CC) $(CFLAGS) -c swap.c

cycle.o:	        cycle.c
			$(CC) $(CFLAGS) -c cycle.c

rsl_bcast.o:	        rsl_bcast.c
			$(CC) $(CFLAGS) -c rsl_bcast.c

rsl_malloc.o:	        rsl_malloc.c
			$(CC) $(CFLAGS) -c rsl_malloc.c

task_for_point.o:	task_for_point.c
			$(CC) $(CFLAGS) -c task_for_point.c

buf_for_proc.o:	        buf_for_proc.c
			$(CC) $(CFLAGS) -c buf_for_proc.c

f_pack.o:	        f_pack.F90
			$(CPP) $(CPPFLAGS) f_pack.F90 > f_pack.f
			$(FC) -o $@ $(FFLAGS) -c f_pack.f

f_xpose.o:	        f_xpose.F90 f_pack.o
			$(CPP) f_xpose.F90 > f_xpose.f
			$(FC) -o $@ $(FFLAGS) -c f_xpose.f

clean : 
			@/bin/rm -f *.f *.o *.mod *.obj *.i $(F90_FILES)

superclean : clean
			@/bin/rm -f *.a


wrf_rsl_pack_wide_i32.o: wrf_rsl_pack_wide_i32.c
	$(CC) -O2 -std=c11 -Wall -Wextra -Werror -c $< -o $@

