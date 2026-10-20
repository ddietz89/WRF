program complete_part2_driver
use iso_c_binding
use module_big_step_utilities_em,only:phy_prep_part2
use module_configure,only:grid_config_rec_type
use module_state_description,only:P_QV,P_QC,P_QR,P_QI,P_QS,P_QG,PARAM_FIRST_SCALAR, &
 MYJPBLSCHEME,KFCUPSCHEME,GDSCHEME,GFLSCHEME,G3SCHEME,KFETASCHEME,MSKFSCHEME,TIEDTKESCHEME,NTIEDTKESCHEME
implicit none
integer,parameter::ims=0,ime=24,kms=0,kme=8,jms=0,jme=6
integer,parameter::ni=ime-ims+1,nk=kme-kms+1,nj=jme-jms+1,n3=ni*nk*nj,n2=ni*nj
integer,parameter::ids=0,jds=0,kds=0
integer::ide,jde,kde,its,ite,jts,jte,kts,kte,ie,je,ke,caseid,f,i,j,k,idx,round_case
integer,parameter::widths(4)=[1,7,8,17]
type field3
 real(c_float),pointer::v(:,:,:)
 type(c_ptr)::p,saved
end type
type field2
 real(c_float),pointer::v(:,:)
 type(c_ptr)::p,saved
end type
type(field3)::a(34)
type(field2)::b(4)
type(grid_config_rec_type)::config_flags
real(c_float),pointer::flat(:),c(:,:)
type(c_ptr)::cp,csaved
integer(c_int),target::mask3(ims:ime,kms:kme,jms:jme),mask2(ims:ime,jms:jme),cmask(nk*4),state(5),header(21)
integer::old_species(6),species_before(6),cfg_before(7),cfg_after(7)
integer(c_int),parameter::qa=int(z'7fc12345',c_int),qb=int(z'ffc54321',c_int),sn=int(z'7f812345',c_int)
logical::enabled(34),species(6),forcingq,forcingt,live
character(512)::path
interface
 function guard_alloc(n)result(p)bind(c)
 import c_int,c_ptr
 integer(c_int),value::n
 type(c_ptr)::p
 end function
 function save_bytes(p,n)result(s)bind(c)
 import c_int,c_ptr
 type(c_ptr),value::p
 integer(c_int),value::n
 type(c_ptr)::s
 end function
 subroutine check_emit(p,s,m,n,kind)bind(c)
 import c_int,c_ptr
 type(c_ptr),value::p,s
 integer(c_int)::m(*)
 integer(c_int),value::n,kind
 end subroutine
 subroutine begin_raw(p)bind(c)
 import c_char
 character(c_char)::p(*)
 end subroutine
 subroutine end_raw()bind(c)
 end subroutine
 subroutine emit_words(p,n)bind(c)
 import c_ptr,c_int
 type(c_ptr),value::p
 integer(c_int),value::n
 end subroutine
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
call get_command_argument(1,path);call begin_raw(trim(path)//c_null_char)
if(storage_size(0.)/=32.or.c_sizeof(0._c_float)/=4)error stop 'REAL32 ABI required'
old_species=[P_QV,P_QC,P_QR,P_QI,P_QS,P_QG]
do caseid=1,68
 ide=19;jde=5;kde=7;its=1;ite=17;jts=1;jte=3;kts=1;kte=7
 config_flags%ra_lw_physics=0;config_flags%ra_sw_physics=0;config_flags%cu_physics=KFCUPSCHEME
 config_flags%shcu_physics=0;config_flags%bl_pbl_physics=0;config_flags%use_theta_m=0;config_flags%grid_fdda=0
 P_QV=PARAM_FIRST_SCALAR;P_QC=PARAM_FIRST_SCALAR;P_QR=PARAM_FIRST_SCALAR
 P_QI=PARAM_FIRST_SCALAR;P_QS=PARAM_FIRST_SCALAR;P_QG=PARAM_FIRST_SCALAR
 select case(caseid)
 case(1);config_flags%cu_physics=0
 case(2:5);ite=widths(caseid-1)
 case(6);its=3;ite=19;ide=21
 case(7);its=ite+1
 case(8);jts=jte+1
 case(9);kts=kte+1
 case(10)
  config_flags%ra_lw_physics=1;config_flags%ra_sw_physics=1;config_flags%shcu_physics=1;config_flags%bl_pbl_physics=1
 case(11);config_flags%cu_physics=GDSCHEME
 case(12);config_flags%cu_physics=GFLSCHEME;config_flags%use_theta_m=1
 case(13);config_flags%cu_physics=G3SCHEME;config_flags%use_theta_m=1
 case(14:15)
  config_flags%grid_fdda=caseid-13;its=0;jts=0;config_flags%ra_lw_physics=1;config_flags%bl_pbl_physics=1
 case(16)
  P_QV=PARAM_FIRST_SCALAR-1;P_QC=PARAM_FIRST_SCALAR-1;P_QR=PARAM_FIRST_SCALAR-1
  P_QI=PARAM_FIRST_SCALAR-1;P_QS=PARAM_FIRST_SCALAR-1;P_QG=PARAM_FIRST_SCALAR-1
 case(20);ite=24;ide=17;jte=6;jde=4;kte=8;kde=6
 case(21:32)
  config_flags%cu_physics=0;config_flags%bl_pbl_physics=1
  select case(caseid)
  case(27:28);its=3;ite=19;ide=21
  case(29);its=ite+1
  case(30);jts=jte+1
  case(31);kts=kte+1
  case(32);ite=1
  end select
 case(33:44)
  config_flags%cu_physics=TIEDTKESCHEME;config_flags%bl_pbl_physics=MYJPBLSCHEME
  config_flags%ra_lw_physics=4;config_flags%ra_sw_physics=4
  config_flags%shcu_physics=0;config_flags%use_theta_m=1;config_flags%grid_fdda=0
  select case(caseid)
  case(39:40);its=3;ite=19;ide=21
  case(41);P_QV=PARAM_FIRST_SCALAR-1
  case(42);its=ite+1
  case(43);jts=jte+1
  case(44);kts=kte+1
  end select
 case(45:56)
  config_flags%cu_physics=TIEDTKESCHEME;config_flags%bl_pbl_physics=MYJPBLSCHEME
  config_flags%ra_lw_physics=4;config_flags%ra_sw_physics=4
  config_flags%shcu_physics=0;config_flags%use_theta_m=1;config_flags%grid_fdda=0
  select case(caseid)
  case(51:52);its=3;ite=19;ide=21
  case(53);P_QV=PARAM_FIRST_SCALAR-1
  case(54);its=ite+1
  case(55);jts=jte+1
  case(56);kts=kte+1
  end select
 case(57:68)
  config_flags%cu_physics=0;config_flags%bl_pbl_physics=0
  config_flags%ra_lw_physics=4;config_flags%ra_sw_physics=4
  config_flags%shcu_physics=0;config_flags%use_theta_m=1;config_flags%grid_fdda=0
  select case(caseid)
  case(57);ite=8;config_flags%ra_sw_physics=0
  case(58);config_flags%ra_lw_physics=0
  case(63);its=3;ite=9;ide=21
  case(64);ite=8;config_flags%ra_lw_physics=0;config_flags%ra_sw_physics=0
  case(65);its=ite+1
  case(66);jts=jte+1
  case(67);kts=kte+1
  case(68);ite=1;P_QV=PARAM_FIRST_SCALAR-1
  end select
 end select
 species_before=[P_QV,P_QC,P_QR,P_QI,P_QS,P_QG]
 cfg_before=[config_flags%ra_lw_physics,config_flags%ra_sw_physics,config_flags%cu_physics, &
 config_flags%shcu_physics,config_flags%bl_pbl_physics,config_flags%use_theta_m,config_flags%grid_fdda]
 do f=1,34
  a(f)%p=guard_alloc(n3);call c_f_pointer(a(f)%p,flat,[n3]);a(f)%v(ims:ime,kms:kme,jms:jme)=>flat
  do j=jms,jme;do k=kms,kme;do i=ims,ime
   a(f)%v(i,k,j)=real(modulo(17*i+31*j+11*k+23*f+7*caseid,257)-128)/1024.
  enddo;enddo;enddo
 enddo
 a(32)%v=10.;a(34)%v=0.005
 do f=1,4
  b(f)%p=guard_alloc(n2);call c_f_pointer(b(f)%p,flat,[n2]);b(f)%v(ims:ime,jms:jme)=>flat
  b(f)%v=60000.+real(f)
 enddo
 cp=guard_alloc(nk*4);call c_f_pointer(cp,flat,[nk*4]);c(kms:kme,1:4)=>flat
 c(:,1)=0.9;c(:,2)=100.;c(:,3)=0.8;c(:,4)=120.
 if(caseid==17)then
  c(2,1)=0.;c(2,2)=0.;c(3,1)=transfer(int(z'80000000',c_int),0.);c(3,2)=transfer(int(z'80000000',c_int),0.)
  a(8)%v(1,2,1)=0.;a(9)%v(2,2,1)=1.;a(10)%v(3,3,1)=-1.
 endif
 if(caseid==18)then
  a(8)%v(1,2,1)=transfer(qa,0.);a(9)%v(2,2,1)=transfer(qb,0.);a(10)%v(3,2,1)=transfer(sn,0.)
 endif
 if(caseid==19)then
  a(8)%v(1,2,1)=transfer(int(z'80000000',c_int),0.);a(9)%v(2,2,1)=transfer(1_c_int,0.)
  a(10)%v(3,2,1)=transfer(int(z'7f800000',c_int),0.);a(8)%v(4,2,1)=transfer(int(z'ff800000',c_int),0.)
 endif
 ! Additive PBL-only live fields: a2=RTHBLTEN, a3=RUBLTEN, a4=RVBLTEN.
 ! Existing CU cases 1..20 remain byte-for-byte equivalent in all inputs and state.
 if(caseid>=21)then
  do j=jms,jme;do i=ims,ime
   b(1)%v(i,j)=60000.+real(17*i+5*j)
  enddo;enddo
  select case(caseid)
  case(21:22)
   c(2,1)=0.;c(2,2)=0.
   a(2)%v(1,2,1)=0.;a(3)%v(2,2,1)=1.;a(4)%v(3,2,1)=-1.
   c(3,1)=transfer(int(z'80000000',c_int),0.)
   c(3,2)=transfer(int(z'80000000',c_int),0.)
   a(2)%v(1,3,1)=transfer(int(z'80000000',c_int),0.)
  case(23:24)
   a(2)%v(1,2,1)=transfer(qa,0.);a(3)%v(2,2,1)=transfer(qb,0.)
   a(4)%v(3,2,1)=transfer(sn,0.)
  case(25:26)
   c(2,1)=0.;c(2,2)=1.
   a(2)%v(1,2,1)=transfer(1_c_int,0.)
   a(3)%v(2,2,1)=transfer(int(z'7f800000',c_int),0.)
   a(4)%v(3,2,1)=transfer(int(z'ff800000',c_int),0.)
   c(3,1)=0.;c(3,2)=transfer(1_c_int,0.)
   a(2)%v(1,3,1)=1.;a(3)%v(2,3,1)=-1.
  end select
 endif
 ! Additive actualCONUS forcing field: a26=RQVFTEN; prior32 inputs unchanged.
 if(caseid>=33)then
  ! Keep actualCONUS flags, but avoid unrelated nonzero/zero or overflow operands
  ! masking target a26 DIVBYZERO/OVERFLOW flags in nearest-mode diagnostic cases.
  if(any(caseid==[33,34,37,38]))then
   do f=1,31
    if(f/=26)then
     a(f)%v(:,2,:)=0.;a(f)%v(:,3,:)=0.
    endif
   enddo
  endif
  select case(caseid)
  case(33:34)
   c(2,1)=0.;c(2,2)=0.
   a(26)%v(1,2,1)=0.;a(26)%v(2,2,1)=1.;a(26)%v(3,2,1)=-1.
   c(3,1)=transfer(int(z'80000000',c_int),0.)
   c(3,2)=transfer(int(z'80000000',c_int),0.)
   a(26)%v(1,3,1)=transfer(int(z'80000000',c_int),0.)
  case(35:36)
   a(26)%v(1,2,1)=transfer(qa,0.);a(26)%v(2,2,1)=transfer(qb,0.)
   a(26)%v(3,2,1)=transfer(sn,0.)
  case(37:38)
   c(2,1)=0.;c(2,2)=1.
   a(26)%v(1,2,1)=transfer(1_c_int,0.)
   a(26)%v(2,2,1)=transfer(int(z'7f800000',c_int),0.)
   a(26)%v(3,2,1)=transfer(int(z'ff800000',c_int),0.)
   c(3,1)=0.;c(3,2)=transfer(1_c_int,0.)
   a(26)%v(1,3,1)=1.;a(26)%v(2,3,1)=-1.
  case(41)
   a(26)%v(1,2,1)=transfer(sn,0.)
   a(26)%v(2,2,1)=transfer(qa,0.)
  end select
 endif
 ! Additive actualCONUS PBL vaporfield a5=RQVBLTEN; prior44 unchanged.
 if(caseid>=45)then
  if(any(caseid==[45,46,49,50]))then
   do f=1,31
    if(f/=5)then
     a(f)%v(:,2,:)=0.;a(f)%v(:,3,:)=0.
    endif
   enddo
  endif
  select case(caseid)
  case(45:46)
   c(2,1)=0.;c(2,2)=0.
   a(5)%v(1,2,1)=0.;a(5)%v(2,2,1)=1.;a(5)%v(3,2,1)=-1.
   c(3,1)=transfer(int(z'80000000',c_int),0.)
   c(3,2)=transfer(int(z'80000000',c_int),0.)
   a(5)%v(1,3,1)=transfer(int(z'80000000',c_int),0.)
  case(47:48)
   a(5)%v(1,2,1)=transfer(qa,0.);a(5)%v(2,2,1)=transfer(qb,0.)
   a(5)%v(3,2,1)=transfer(sn,0.)
  case(49:50)
   c(2,1)=0.;c(2,2)=1.
   a(5)%v(1,2,1)=transfer(1_c_int,0.)
   a(5)%v(2,2,1)=transfer(int(z'7f800000',c_int),0.)
   a(5)%v(3,2,1)=transfer(int(z'ff800000',c_int),0.)
   c(3,1)=0.;c(3,2)=transfer(1_c_int,0.)
   a(5)%v(1,3,1)=1.;a(5)%v(2,3,1)=-1.
  case(53)
   a(5)%v(1,2,1)=transfer(sn,0.);a(5)%v(2,2,1)=transfer(qa,0.)
  end select
 endif
 ! Additive radiation target a1=RTHRATEN; all prior56 inputs and execution unchanged.
 if(caseid>=57)then
  select case(caseid)
  case(57:58)
   c(2,1)=0.;c(2,2)=0.
   a(1)%v(1,2,1)=0.;a(1)%v(2,2,1)=1.;a(1)%v(3,2,1)=-1.
   c(3,1)=transfer(int(z'80000000',c_int),0.)
   c(3,2)=transfer(int(z'80000000',c_int),0.)
   a(1)%v(1,3,1)=transfer(int(z'80000000',c_int),0.)
  case(59:60)
   a(1)%v(1,2,1)=transfer(qa,0.);a(1)%v(2,2,1)=transfer(qb,0.)
   a(1)%v(3,2,1)=transfer(sn,0.)
  case(61:62)
   c(2,1)=0.;c(2,2)=1.
   a(1)%v(1,2,1)=transfer(1_c_int,0.)
   a(1)%v(2,2,1)=transfer(int(z'7f800000',c_int),0.)
   a(1)%v(3,2,1)=transfer(int(z'ff800000',c_int),0.)
   c(3,1)=0.;c(3,2)=transfer(1_c_int,0.)
   a(1)%v(1,3,1)=1.;a(1)%v(2,3,1)=-1.
  case(64)
   a(1)%v(1,2,1)=transfer(sn,0.);c(2,1)=0.;c(2,2)=0.
  end select
 endif
 do f=1,34;a(f)%saved=save_bytes(a(f)%p,n3);enddo
 do f=1,4;b(f)%saved=save_bytes(b(f)%p,n2);enddo
 csaved=save_bytes(cp,nk*4)
 round_case=mod(caseid-1,4)
 if(caseid>=21)round_case=mod(caseid-21,2)
 call observation_case(round_case);call reset_observation()
call phy_prep_part2(config_flags,b(1)%v,b(2)%v,b(3)%v,c(:,1),c(:,2),c(:,3),c(:,4), &
 a(1)%v,a(2)%v,a(3)%v,a(4)%v,a(5)%v,a(6)%v, &
 a(7)%v,a(8)%v,a(9)%v,a(10)%v,a(11)%v,a(12)%v, &
 a(13)%v,a(14)%v,a(15)%v,a(16)%v,a(17)%v,a(18)%v, &
 a(19)%v,a(20)%v,a(21)%v,a(22)%v,a(23)%v,a(24)%v, &
 a(25)%v,a(26)%v,a(27)%v,a(28)%v,a(29)%v,a(30)%v, &
 a(31)%v,b(4)%v,a(32)%v,a(33)%v,a(34)%v, &
 ids,ide,jds,jde,kds,kde,ims,ime,jms,jme,kms,kme,its,ite,jts,jte,kts,kte)
 call read_observation(state)
 cfg_after=[config_flags%ra_lw_physics,config_flags%ra_sw_physics,config_flags%cu_physics, &
 config_flags%shcu_physics,config_flags%bl_pbl_physics,config_flags%use_theta_m,config_flags%grid_fdda]
 if(any(cfg_before/=cfg_after).or.any(species_before/=[P_QV,P_QC,P_QR,P_QI,P_QS,P_QG]))error stop 'readonly config/species'
 header=[caseid,its,ite,jts,jte,kts,kte,ide,jde,kde,cfg_before,round_case,ni,nk,nj]
 call emit_words(c_loc(header),size(header));call emit_words(c_loc(state),5)
 ie=min(ite,ide-1);je=min(jte,jde-1);ke=min(kte,kde-1)
 species=species_before>=PARAM_FIRST_SCALAR;enabled=.false.
 enabled(1)=config_flags%ra_lw_physics>0.or.config_flags%ra_sw_physics>0
 if(config_flags%bl_pbl_physics>0)then
  enabled(2:4)=.true.;enabled(5)=species(1);enabled(6)=species(2);enabled(7)=species(4)
 endif
 if(config_flags%cu_physics>0)then
  enabled(8:10)=.true.;enabled(11:15)=species(1:5)
 endif
 if(config_flags%shcu_physics>0)then
  enabled(16:18)=.true.;enabled(19:24)=species
 endif
 forcingq=any(config_flags%cu_physics==[GDSCHEME,GFLSCHEME,G3SCHEME,KFETASCHEME,MSKFSCHEME,TIEDTKESCHEME,NTIEDTKESCHEME])
 forcingt=any(config_flags%cu_physics==[GDSCHEME,GFLSCHEME,G3SCHEME,NTIEDTKESCHEME])
 enabled(25)=forcingt;enabled(26)=forcingq.and.species(1)
 enabled(27:30)=config_flags%grid_fdda>0;enabled(30)=config_flags%grid_fdda==2
 enabled(31)=config_flags%grid_fdda>=1.and.config_flags%grid_fdda/=2.and.species(1)
 enabled(33)=forcingt.and.config_flags%use_theta_m==1
 do f=1,34
  mask3=0
  if(enabled(f))then
   do j=jts,je;do k=kts,merge(kte,ke,f==30);do i=its,ie
    live=.true.
    if(f==27)live=i>=max(its,ids+1)
    if(f==28)live=j>=max(jts,jds+1)
    if(live)mask3(i,k,j)=1
   enddo;enddo;enddo
  endif
  call check_emit(a(f)%p,a(f)%saved,mask3,n3,1_c_int);nullify(a(f)%v)
 enddo
 mask2=0
 do f=1,4;call check_emit(b(f)%p,b(f)%saved,mask2,n2,2_c_int);nullify(b(f)%v);enddo
 cmask=0;call check_emit(cp,csaved,cmask,nk*4,2_c_int);nullify(c)
 P_QV=old_species(1);P_QC=old_species(2);P_QR=old_species(3);P_QI=old_species(4);P_QS=old_species(5);P_QG=old_species(6)
enddo
call end_raw()
end program
