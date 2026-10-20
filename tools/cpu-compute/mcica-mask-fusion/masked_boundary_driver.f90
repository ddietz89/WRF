program full_mcica_caller_gate
use iso_fortran_env,only:int32
use iso_c_binding,only:c_int
use parkind,only:rb=>kind_rb
use parrrtm
use rrlw_con,only:grav,pi
use rrlw_wvn,only:ngb
use mcica_subcol_gen_lw,only:generate_stochastic_clouds,mcica_subcol_lw
implicit none
integer,parameter::columns(1)=[1],layers(1)=[4]
integer,parameter::counts(16)=[ng1,ng2,ng3,ng4,ng5,ng6,ng7,ng8,ng9,ng10,ng11,ng12,ng13,ng14,ng15,ng16]
integer(int32),parameter::guard=int(z'ffc12345',int32)
real(rb),allocatable::play(:,:),pmid(:,:),cld(:,:),clwp(:,:),ciwp(:,:),cswp(:,:),tau(:,:,:)
real(rb),allocatable::height(:,:),decorr(:),rei(:,:),rel(:,:),res(:,:),out(:,:,:,:),rout(:,:,:)
integer(int32),allocatable::saved(:)
integer(c_int)::state(5)
integer::ci,li,ncol,nlay,overlap,rng,irng,mode,i,k,g,b,previous,c,u,variant
character(512)::path
interface
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
call get_command_argument(1,path)
open(newunit=u,file=trim(path),status='new',access='stream',form='unformatted')
if(storage_size(0._rb)/=32)error stop 'REAL32 required'
grav=9.80665_rb;pi=3.1415927_rb;previous=0
do b=1,nbndlw
 ngb(previous+1:previous+counts(b))=b;previous=previous+counts(b)
enddo
if(previous/=ngptlw)error stop 'gpoint mapping'
c=0
do variant=1,3
do ci=1,size(columns);do li=1,size(layers)
 ncol=columns(ci);nlay=layers(li)
 allocate(play(ncol,nlay),pmid(ncol,nlay),cld(ncol,nlay),clwp(ncol,nlay),ciwp(ncol,nlay),cswp(ncol,nlay))
 allocate(tau(nbndlw,ncol,nlay),height(ncol,nlay),decorr(ncol),rei(ncol,nlay),rel(ncol,nlay),res(ncol,nlay))
 allocate(out(0:ngptlw+1,0:ncol+1,0:nlay+1,5),rout(0:ncol+1,0:nlay+1,3))
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
 if(variant==1)cld(1,2)=transfer(int(z'7fc00000',int32),0._rb)
 if(variant==2)cld(1,2)=transfer(int(z'00000001',int32),0._rb)
 if(variant==3)then
  cld(1,1)=0._rb;cld(1,2)=1._rb;cld(1,3)=1.e-20_rb;cld(1,4)=nearest(1.e-20_rb,-1._rb)
 endif
 pmid=play*1.e2_rb
 do overlap=2,2;do rng=0,1;do mode=1,2
  c=c+1;irng=rng;out=transfer(guard,0._rb);rout=transfer(guard,0._rb)
  saved=snapshot()
  call observation_case(int(mod(c,2),c_int));call reset_observation()
  if(mode==1)then
   call generate_stochastic_clouds(ncol,nlay,ngptlw,overlap,irng,pmid,cld,clwp,ciwp,cswp,tau, &
      height,decorr,out(1:ngptlw,1:ncol,1:nlay,1),out(1:ngptlw,1:ncol,1:nlay,2), &
      out(1:ngptlw,1:ncol,1:nlay,3),out(1:ngptlw,1:ncol,1:nlay,4),out(1:ngptlw,1:ncol,1:nlay,5),150)
  else
   call mcica_subcol_lw(1,ncol,nlay,overlap,150,irng,play,cld,ciwp,clwp,cswp,rei,rel,res,tau, &
      height,0,285,40._rb,out(1:ngptlw,1:ncol,1:nlay,1),out(1:ngptlw,1:ncol,1:nlay,3), &
      out(1:ngptlw,1:ncol,1:nlay,2),out(1:ngptlw,1:ncol,1:nlay,4), &
      rout(1:ncol,1:nlay,1),rout(1:ncol,1:nlay,2),rout(1:ncol,1:nlay,3),out(1:ngptlw,1:ncol,1:nlay,5))
  endif
  call read_observation(state)
  if(any(saved/=snapshot()))error stop 'readonly input changed'
  if(irng/=rng)error stop 'unexpected RNG flag change'
  do b=1,5;do k=0,nlay+1;do i=0,ncol+1;do g=0,ngptlw+1
   if(g>=1.and.g<=ngptlw.and.i>=1.and.i<=ncol.and.k>=1.and.k<=nlay)cycle
   if(transfer(out(g,i,k,b),0_int32)/=guard)error stop 'property padding'
  enddo;enddo;enddo;enddo
  do b=1,3;do k=0,nlay+1;do i=0,ncol+1
   if(mode==2.and.i>=1.and.i<=ncol.and.k>=1.and.k<=nlay)cycle
   if(transfer(rout(i,k,b),0_int32)/=guard)error stop 'size padding'
  enddo;enddo;enddo
  write(u)c,ncol,nlay,overlap,rng,mode,irng,out,rout,state
  deallocate(saved)
 enddo;enddo;enddo
 deallocate(play,pmid,cld,clwp,ciwp,cswp,tau,height,decorr,rei,rel,res,out,rout)
enddo;enddo
enddo
close(u)
if(c/=12)error stop 'case count'
print '(a)','PASS_12_MASKED_CLOUD_INPUT_BOUNDARY_RAW_READONLY_PADDING_STATE'
contains
function snapshot()result(words)
 integer(int32),allocatable::words(:)
 words=[transfer(play,[0_int32]),transfer(pmid,[0_int32]),transfer(cld,[0_int32]), &
 transfer(clwp,[0_int32]),transfer(ciwp,[0_int32]),transfer(cswp,[0_int32]), &
 transfer(tau,[0_int32]),transfer(height,[0_int32]),transfer(decorr,[0_int32]), &
 transfer(rei,[0_int32]),transfer(rel,[0_int32]),transfer(res,[0_int32]), &
 int(ngb,int32),transfer(grav,[0_int32]),transfer(pi,[0_int32])]
end function
end program
