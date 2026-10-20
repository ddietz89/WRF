program full_mcica_caller_benchmark
use iso_fortran_env,only:int32
use iso_c_binding,only:c_int,c_int64_t
use parkind,only:rb=>kind_rb
use parrrtm
use rrlw_con,only:grav,pi
use rrlw_wvn,only:ngb
use mcica_subcol_gen_lw,only:generate_stochastic_clouds,mcica_subcol_lw
implicit none
integer,parameter::columns(2)=[1,3],layers(3)=[4,7,33]
integer,parameter::counts(16)=[ng1,ng2,ng3,ng4,ng5,ng6,ng7,ng8,ng9,ng10,ng11,ng12,ng13,ng14,ng15,ng16]
integer(int32),parameter::guard=int(z'ffc12345',int32)
real(rb),allocatable::play(:,:),pmid(:,:),cld(:,:),clwp(:,:),ciwp(:,:),cswp(:,:),tau(:,:,:)
real(rb),allocatable::height(:,:),decorr(:),rei(:,:),rel(:,:),res(:,:),out(:,:,:,:),rout(:,:,:)
integer(int32),allocatable::saved(:)
integer(c_int)::state(5)
integer::ci,li,ncol,nlay,overlap,rng,irng,mode,i,k,g,b,previous,c,u,iteration,iterations
integer(int32),allocatable::baseline(:),current(:)
real(rb),allocatable::input_copy(:)
integer(int32)::ngb_copy(ngptlw)
integer::offset,n
integer(c_int64_t)::begin_time,end_time,begin_cpu,end_cpu
real(8)::total,total_cpu
character(32)::arg
character(512)::path
interface
 function bench_clock()result(t)bind(c)
 import c_int64_t
 integer(c_int64_t)::t
 end function
 function bench_cpu_clock()result(t)bind(c)
 import c_int64_t
 integer(c_int64_t)::t
 end function
 subroutine observation_case(n)bind(c)
 import c_int
 integer(c_int),value::n
 end subroutine
 subroutine reset_observation()bind(c)
 end subroutine
 subroutine read_observation(s)bind(c)
 import c_int
 integer(c_int)::s(5)
 end subroutine
end interface
call get_command_argument(1,arg);read(arg,*)iterations
if(iterations/=20000.and.iterations/=1)error stop 'fixed timing20000 or onecall buildvalidation only'
call get_command_argument(2,path)
if(storage_size(0._rb)/=32)error stop 'REAL32 required'
grav=9.80665_rb;pi=3.1415927_rb;previous=0
do b=1,nbndlw
 ngb(previous+1:previous+counts(b))=b;previous=previous+counts(b)
enddo
if(previous/=ngptlw)error stop 'gpoint mapping'
ncol=1;nlay=33
 allocate(play(ncol,nlay),pmid(ncol,nlay),cld(ncol,nlay),clwp(ncol,nlay),ciwp(ncol,nlay),cswp(ncol,nlay))
 allocate(tau(nbndlw,ncol,nlay),height(ncol,nlay),decorr(ncol),rei(ncol,nlay),rel(ncol,nlay),res(ncol,nlay))
 allocate(out(ngptlw,ncol,nlay,5),rout(ncol,nlay,3))
 do i=1,ncol
  decorr(i)=2500._rb
  do k=1,nlay
   play(i,k)=1000._rb-10._rb*real(k,rb)+real(i,rb)*0.03125_rb
   height(i,k)=100._rb*real(k,rb)
   cld(i,k)=real(mod(i+k,5),rb)*0.25_rb
   clwp(i,k)=real(i+k,rb)*0.125_rb;ciwp(i,k)=real(i+2*k,rb)*0.0625_rb
   cswp(i,k)=real(2*i+k,rb)*0.03125_rb
   rei(i,k)=15._rb;rel(i,k)=10._rb;res(i,k)=20._rb
   do b=1,nbndlw
    tau(b,i,k)=real(mod(b+i+k,9),rb)*0.125_rb
   enddo
  enddo
 enddo
 pmid=play*1.e2_rb

saved=snapshot();input_copy=transfer(saved,input_copy);ngb_copy=ngb
total=0.d0;total_cpu=0.d0
do iteration=1,iterations
 ! Restore original inputs and observation state outside the call interval.
 offset=0
 call restore(play);call restore(pmid);call restore(cld);call restore(clwp);call restore(ciwp);call restore(cswp)
 call restore3(tau);call restore(height);call restore1(decorr);call restore(rei);call restore(rel);call restore(res)
 ngb=ngb_copy;grav=9.80665_rb;pi=3.1415927_rb
 irng=0;out=transfer(guard,0._rb);rout=transfer(guard,0._rb)
 call observation_case(0_c_int);call reset_observation()
 begin_time=bench_clock();begin_cpu=bench_cpu_clock()
 call mcica_subcol_lw(1,ncol,nlay,2,150,irng,play,cld,ciwp,clwp,cswp,rei,rel,res,tau, &
      height,0,285,40._rb,out(1:ngptlw,1:ncol,1:nlay,1),out(1:ngptlw,1:ncol,1:nlay,3), &
      out(1:ngptlw,1:ncol,1:nlay,2),out(1:ngptlw,1:ncol,1:nlay,4), &
      rout(1:ncol,1:nlay,1),rout(1:ncol,1:nlay,2),rout(1:ncol,1:nlay,3),out(1:ngptlw,1:ncol,1:nlay,5))
 end_cpu=bench_cpu_clock();end_time=bench_clock()
 call read_observation(state)
 total=total+real(end_time-begin_time,8)*1.d-9
 total_cpu=total_cpu+real(end_cpu-begin_cpu,8)*1.d-9
 if(any(saved/=snapshot()))error stop 'readonly input changed'
 if(irng/=0)error stop 'unexpected RNG flag change'
 current=[transfer(out,[0_int32]),transfer(rout,[0_int32]),int(state,int32),int(irng,int32)]
 if(iteration==1)then
  baseline=current
 else
  if(any(current/=baseline))error stop 'per-call raw output/state drift'
 endif
enddo
open(newunit=u,file=trim(path),status='new',access='stream',form='unformatted')
write(u)baseline,saved
close(u)
print '(a,i0,a,es24.16,a,es24.16,a,i0)','BENCH iterations=',iterations,' wall_seconds=',total,' cpu_seconds=',total_cpu,' raw_bytes=',4*(size(baseline)+size(saved))
contains
subroutine restore(a)
 real(rb)::a(:,:)
 n=size(a);a=reshape(input_copy(offset+1:offset+n),shape(a));offset=offset+n
end subroutine
subroutine restore3(a)
 real(rb)::a(:,:,:)
 n=size(a);a=reshape(input_copy(offset+1:offset+n),shape(a));offset=offset+n
end subroutine
subroutine restore1(a)
 real(rb)::a(:)
 n=size(a);a=input_copy(offset+1:offset+n);offset=offset+n
end subroutine
function snapshot()result(words)
 integer(int32),allocatable::words(:)
 words=[transfer(play,[0_int32]),transfer(pmid,[0_int32]),transfer(cld,[0_int32]), &
 transfer(clwp,[0_int32]),transfer(ciwp,[0_int32]),transfer(cswp,[0_int32]), &
 transfer(tau,[0_int32]),transfer(height,[0_int32]),transfer(decorr,[0_int32]), &
 transfer(rei,[0_int32]),transfer(rel,[0_int32]),transfer(res,[0_int32]), &
 int(ngb,int32),transfer(grav,[0_int32]),transfer(pi,[0_int32])]
end function
end program
