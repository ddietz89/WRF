






















 module bl_gwdo
 use ccpp_kind_types,only: kind_phys
 implicit none
 private
 public:: bl_gwdo_run,     &
          bl_gwdo_init,    &
          bl_gwdo_finalize
 contains




 subroutine bl_gwdo_init(errmsg,errflg)


 character(len=*),intent(out):: errmsg
 integer,intent(out):: errflg
 errmsg = 'bl_gwdo_init OK'
 errflg = 0
 end subroutine bl_gwdo_init




 subroutine bl_gwdo_finalize(errmsg,errflg)


 character(len=*),intent(out):: errmsg
 integer,intent(out):: errflg
 errmsg = 'bl_gwdo_finalize OK'
 errflg = 0
 end subroutine bl_gwdo_finalize




   subroutine bl_gwdo_run(sina, cosa,                                          &
                     rublten,rvblten,                                          &
                     dtaux3d,dtauy3d,                                          &
                     dusfcg,dvsfcg,                                            &
                     uproj, vproj,                                             &
                     t1, q1,                                                   &
                     prsi, prsl, prslk, zl,                                    &
                     var, oc1,                                                 &
                     oa2d1, oa2d2,                                             &
                     oa2d3, oa2d4,                                             &
                     ol2d1, ol2d2,                                             &
                     ol2d3, ol2d4, omax,                                       &
                     dx_factor, if_nonhyd,                                     &
                     g_, cp_, rd_, rv_, fv_, pi_,                              &
                     dxmeter, deltim,                                          &
                     its, ite, kte, kme,                                       &
                     errmsg, errflg                                            )



















































   implicit none

   integer               , intent(in   ) ::                                    &
                                            its, ite, kte, kme
   logical               , intent(in   ) ::                                    &
                                            if_nonhyd
   real(kind=kind_phys)  , intent(in   ) ::                                    &
                                            g_, pi_, rd_, rv_, fv_, cp_,       &
                                            deltim, dx_factor

   real(kind=kind_phys), dimension(its:)  , intent(in   ) ::                   &
                                            dxmeter,sina, cosa,var, oc1, omax, &
                                            oa2d1, oa2d2, oa2d3, oa2d4,        &
                                            ol2d1, ol2d2, ol2d3, ol2d4

   real(kind=kind_phys), dimension(its:,:), intent(in   ) ::                   &
                                            uproj, vproj,t1, q1, prslk, zl,    &
                                            prsl, prsi

   real(kind=kind_phys), dimension(its:,:), intent(inout) ::                   &
                                            rublten, rvblten

   real(kind=kind_phys), dimension(its:),   intent(out)   ::                   &
                                            dusfcg, dvsfcg
   real(kind=kind_phys), dimension(its:,:), intent(out)   ::                   &
                                            dtaux3d, dtauy3d

   character(len=*)                        , intent(  out) :: errmsg
   integer                                 , intent(  out) :: errflg

   integer, parameter       ::            &
                        kts     = 1      ,&
                        kgwdmin = 2      ,&  
                        mdir    = 8          

   real(kind=kind_phys), parameter     :: &
                        qmin    = 1.0e-30,&  
                        ric     = 0.25   ,&  
                        velmin  = 1.     ,&  
                        rimin   = -100.  ,&  
                        bnv2min = 1.0e-5 ,&  
                        efacmin = 0.     ,&  
                        efacmax = 10.    ,&  
                        frc     = 1.0    ,&  
                        frmax   = 10.    ,&  
                        ce      = 0.8    ,&  
                        cg      = 1.     ,&  
                        var_min = 10.    ,&  
                        hmt_min = 50.    ,&  
                        oc_min  = 1.     ,&  
                        oc_max  = 10.    ,&  
                        olmin   = 1.0e-5 ,&  
                        odmin   = 0.1    ,&  
                        odmax   = 10.    ,&  
                        cdmin   = 0.     ,&  
                        pcutoff  = 7.5e2 ,&  
                        pcutoff_den  = 0.01  



   integer                              ::                                                     &
                        kgwdmax, latd, lond, i, k, lcap, lcapp1, nwd, idir, klcap, kp1, kblk

   real(kind=kind_phys)                 ::                                                     &
                        fdir, cs, rcsks, wdir, ti, rdz, tem1, tem2, temc, tem, temv, dw2, shr2,&
                        bvf2, rdelks, wtkbj, gfac, hd, fro, rim, efac, dtaux, dtauy, denfac,   &
                        fbdcd, zblk, tautem, fbdpe, fbdke, xlinv

   real(kind=kind_phys), dimension(its:ite)           ::                                       &
                         dusfc, dvsfc, coefm, taub, xn, yn, ubar, vbar, fr, ulow, rulow, bnv,  &
                         oa, ol, oc, rhobar, brvf, delks,delks1, zref, dx_eff

   real(kind=kind_phys), dimension(its:ite,kts:kte)   ::                                       &
                         dudt, dvdt, dtaux2d, dtauy2d
   logical, dimension(its:ite)                        :: ldrag, icrilv, flag



   real(kind=kind_phys)                               :: nhd_effect

   real(kind=kind_phys), dimension(its:ite,kts:kte+1) :: taup
   real(kind=kind_phys), dimension(its:ite,kts:kte-1) :: velco
   real(kind=kind_phys), dimension(its:ite,kts:kte)   ::                                       &
                         bnv2, usqj, taud, rho, vtk, vtj, dtfac, del, u1, v1
   real(kind=kind_phys), dimension(its:ite,4)         ::                                       &
                         oa4, ol4

   integer, dimension(its:ite)                        :: kref, komax, kbomax

   real(kind=kind_phys), dimension(its:ite)           ::                                       &
                         delx, dely, dxy, dxyp, olp, od, area

   real(kind=kind_phys), dimension(its:ite,4)         ::                                       &
                         dxy4, dxy4p
   real(kind=kind_phys), dimension(4)                 ::                                       &
                         ol4p
   real(kind=kind_phys), dimension(its:ite,kts:kte+1) :: taufb

   integer, dimension(mdir)                           :: nwdir
   data nwdir/6,7,5,8,2,3,1,4/




   lcap   = kte
   lcapp1 = lcap + 1
   fdir   = mdir / (2.0*pi_)
   kgwdmax = kte / 2 



    errmsg = ''
    errflg = 0



   delx(its:ite) = dxmeter(its:ite)
   dely(its:ite) = dxmeter(its:ite)
   area(its:ite) = delx(its:ite)*dely(its:ite)
   dxy4(its:ite,1)  = delx(its:ite)
   dxy4(its:ite,2)  = dely(its:ite)
   dxy4(its:ite,3)  = sqrt(delx(its:ite)**2. + dely(its:ite)**2.)
   dxy4(its:ite,4)  = dxy4(its:ite,3)
   dxy4p(its:ite,1) = dxy4(its:ite,2)
   dxy4p(its:ite,2) = dxy4(its:ite,1)
   dxy4p(its:ite,3) = dxy4(its:ite,4)
   dxy4p(its:ite,4) = dxy4(its:ite,3)

   dx_eff(its:ite) = dx_factor*(delx(its:ite)+dely(its:ite))*0.5



   ldrag   = .false. ; icrilv = .false. ; flag    = .true.
   kref    = 0       ; komax  = 0       ; kbomax = 0
   taufb   = 0.      ; dtaux  = 0.      ; dtauy  = 0.
   xn      = 0.      ; yn     = 0.
   ubar    = 0.      ; vbar   = 0.      ; rhobar  = 0.     ; ulow    = 0.
   oa      = 0.      ; ol     = 0.      ; oc      = 0.     ; taub    = 0.
   usqj    = 0.      ; bnv2   = 0.      ; vtj     = 0.     ; vtk     = 0.
   taup    = 0.      ; taud   = 0.      ; dtaux2d = 0.     ; dtauy2d = 0.
   dtfac   = 1.0     ; xlinv  = 1.0     ; denfac =  1.0
   nhd_effect = 1.0

   do k = kts,kte
     do i = its,ite
       vtj(i,k) = t1(i,k)  * (1.+fv_*q1(i,k))
       vtk(i,k) = vtj(i,k) / prslk(i,k)
       
       rho(i,k) = 1./rd_ * prsl(i,k) / vtj(i,k)
       
       del(i,k) = prsi(i,k) - prsi(i,k+1)
       
       u1(i,k) = uproj(i,k)*cosa(i) - vproj(i,k)*sina(i)
       v1(i,k) = uproj(i,k)*sina(i) + vproj(i,k)*cosa(i)
     enddo
   enddo

   do i = its,ite
       zref(i) = 2. * var(i)
   enddo

#if defined(WRF_GWDO_FIRSTHIT_O2_ENABLE) && !defined(WRF_GWDO_FIRSTHIT_O2_DISABLE) && defined(DM_PARALLEL) && !defined(_OPENMP)
   do i = its,ite
     flag(i) = .true.
   enddo

   do i = its,ite
     do k = kts+1,kte
       if (flag(i) .and. zl(i,k)-zl(i,1)>=zref(i)) then
         kref(i) = k+1
         flag(i) = .false.
         exit
       endif
     enddo
   enddo

   do i = its,ite
     kref(i) = max(min(kref(i),kgwdmax),kgwdmin)
   enddo




   do i = its,ite
     flag(i) = .true.
   enddo

   do i = its,ite
     do k = kts+1,kte
       if (flag(i) .and. zl(i,k)>=omax(i)) then
         komax(i) = k+1
         flag(i)  = .false.
         exit
       endif
     enddo
   enddo

   do i = its,ite
     komax(i) = max(komax(i),kref(i))
   enddo



   do i = its,ite
     flag(i) = .true.
   enddo

   do i = its,ite
     do k = kts+1,kte
       if (flag(i) .and. zl(i,k)>=(omax(i)+zref(i))) then
         kbomax(i) = k+1
         flag(i)  = .false.
         exit
       endif
     enddo
   enddo
#else
   do i = its,ite
     flag(i) = .true.
   enddo

   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)-zl(i,1)>=zref(i)) then
         kref(i) = k+1
         flag(i) = .false.
       endif
     enddo
   enddo

   do i = its,ite
     kref(i) = max(min(kref(i),kgwdmax),kgwdmin)
   enddo




   do i = its,ite
     flag(i) = .true.
   enddo

   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)>=omax(i)) then
         komax(i) = k+1
         flag(i)  = .false.
       endif
     enddo
   enddo

   do i = its,ite
     komax(i) = max(komax(i),kref(i))
   enddo



   do i = its,ite
     flag(i) = .true.
   enddo

   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)>=(omax(i)+zref(i))) then
         kbomax(i) = k+1
         flag(i)  = .false.
       endif
     enddo
   enddo
#endif

   do i = its,ite
     delks(i)  = 1.0 / (prsi(i,1) - prsi(i,kref(i)))
     delks1(i) = 1.0 / (prsl(i,1) - prsl(i,kref(i)))
   enddo



   do k = kts,kgwdmax
     do i = its,ite
       if (k < kref(i)) then
         rcsks     = del(i,k) * delks(i)
         rdelks    = del(i,k)  * delks(i)
         ubar(i)   = ubar(i) + rcsks  * u1(i,k)      
         vbar(i)   = vbar(i) + rcsks  * v1(i,k)      
         rhobar(i) = rhobar(i) + rdelks * rho(i,k)   
       endif
     enddo
   enddo






   do i = its,ite
     oa4(i,1) = oa2d1(i)
     oa4(i,2) = oa2d2(i)
     oa4(i,3) = oa2d3(i)
     oa4(i,4) = oa2d4(i)
     ol4(i,1) = ol2d1(i)
     ol4(i,2) = ol2d2(i)
     ol4(i,3) = ol2d3(i)
     ol4(i,4) = ol2d4(i)
     wdir  = atan2(ubar(i),vbar(i)) + pi_
     idir  = mod(nint(fdir*wdir),mdir) + 1
     nwd   = nwdir(idir)
     oa(i) = (1-2*int( (nwd-1)/4 )) * oa4(i,mod(nwd-1,4)+1)
     ol(i) = max(ol4(i,mod(nwd-1,4)+1),olmin)
     oc(i) = min(max(oc1(i),oc_min),oc_max)



     ol4p(1) = ol4(i,2)
     ol4p(2) = ol4(i,1)
     ol4p(3) = ol4(i,4)
     ol4p(4) = ol4(i,3)
     olp(i)  = max(ol4p(mod(nwd-1,4)+1),olmin)



     od(i) = olp(i)/ol(i)
     od(i) = min(od(i),odmax)
     od(i) = max(od(i),odmin)



     dxy(i)  = dxy4(i,MOD(nwd-1,4)+1)
     dxyp(i) = dxy4p(i,MOD(nwd-1,4)+1)
   enddo



   do k = kts,kte-1
     do i = its,ite
       ti        = 2.0 / (t1(i,k)+t1(i,k+1))
       rdz       = 1./(zl(i,k+1) - zl(i,k))
       tem1      = u1(i,k) - u1(i,k+1)
       tem2      = v1(i,k) - v1(i,k+1)
       dw2       = tem1*tem1 + tem2*tem2
       shr2      = max(dw2,velmin) * rdz * rdz
       bvf2      = g_*(g_/cp_+rdz*(vtj(i,k+1)-vtj(i,k))) * ti
       usqj(i,k) = max(bvf2/shr2,rimin)
       bnv2(i,k) = 2.0*g_*rdz*(vtk(i,k+1)-vtk(i,k))/(vtk(i,k+1)+vtk(i,k))
     enddo
   enddo



   do i = its,ite
     ulow(i) = max(sqrt(ubar(i)*ubar(i) + vbar(i)*vbar(i)), 1.0)
     rulow(i) = 1./ulow(i)
   enddo



   do k = kts,kte-1
     do i = its,ite
       velco(i,k) = 0.5 * ((u1(i,k)+u1(i,k+1)) * ubar(i)                       &
                         + (v1(i,k)+v1(i,k+1)) * vbar(i))
       velco(i,k) = velco(i,k) * rulow(i)
       if ((velco(i,k) < velmin) .and. (velco(i,k) >0. )) then
         velco(i,k) = velmin
       endif
     enddo
   enddo

   do i = its,ite
     ldrag(i) = omax(i) <= hmt_min               
     ldrag(i) = ldrag(i) .or. var(i) <= 0.       
     ldrag(i) = ldrag(i) .or. velco(i,1)<=0.     
     ldrag(i) = ldrag(i) .or. ulow(i)==1.0       
   enddo



   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) ldrag(i) = ldrag(i) .or. velco(i,k)<=0.                &
                                            .or. bnv2(i,k)<0.
     enddo
   enddo



   do i = its,ite
     wtkbj     = (prsl(i,1)-prsl(i,2)) * delks1(i)
     bnv2(i,1) = wtkbj * bnv2(i,1)
     usqj(i,1) = wtkbj * usqj(i,1)
   enddo

   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) then
         rdelks    = (prsl(i,k)-prsl(i,k+1)) * delks1(i)
         bnv2(i,1) = bnv2(i,1) + bnv2(i,k) * rdelks
         usqj(i,1) = usqj(i,1) + usqj(i,k) * rdelks
       endif
     enddo
   enddo

   do i = its,ite
     ldrag(i) = ldrag(i) .or. bnv2(i,1)<=0.     
   enddo



   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) usqj(i,k) = usqj(i,1)
     enddo
   enddo

   do i = its,ite
     if (.not.ldrag(i))   then
       bnv(i) = sqrt( bnv2(i,1) )
       fr(i) = bnv(i)  * rulow(i) * var(i) * od(i)
       fr(i) = min(fr(i),frmax)
       xn(i)  = ubar(i) * rulow(i)
       yn(i)  = vbar(i) * rulow(i)
     endif
   enddo



   do i = its,ite
     if (.not. ldrag(i))   then
       efac    = (oa(i) + 2.) ** (ce*fr(i)/frc)
       efac    = min( max(efac,efacmin), efacmax )
       coefm(i) = (1. + ol(i)) ** (oa(i)+1.)
       xlinv    = coefm(i) / dx_eff(i)
       tem      = fr(i) * fr(i) * oc(i)
       gfac     = tem / (tem + cg)
       taub(i)  = rhobar(i) * efac * xlinv * gfac * ulow(i)*ulow(i)*ulow(i)    &
                  / bnv(i)
       if (if_nonhyd) then
         tem = fr(i) * fr(i)
         nhd_effect = -9./8.*tem + exp(-2./fr(i))                              &
                   *(-5./4./tem-0.5/fr(i)+5./4.+9./4.*fr(i)+9./8.*tem)
         taub(i)  = taub(i) * (1.+nhd_effect)
       endif
     else
       taub(i) = 0.
       xn(i)   = 0.
       yn(i)   = 0.
     endif
   enddo



   do k = kts,kgwdmax
     do i = its,ite
       if (k <= kref(i)) taup(i,k) = taub(i)
     enddo
   enddo

   do k = kgwdmin, kte-1                   
     kp1 = k + 1
     do i = its,ite



       if (k >= kref(i)) then
         icrilv(i) = icrilv(i) .or. ( usqj(i,k) < ric)                         &
                               .or. (velco(i,k) <= 0.)
         brvf(i) = max(bnv2(i,k),bnv2min) 
         brvf(i) = sqrt(brvf(i))          
       endif
     enddo

     do i = its,ite
       if (k >= kref(i) .and. (.not. ldrag(i)))   then
         if (.not.icrilv(i) .and. taup(i,k) > 0. ) then
           temv = 1.0 / velco(i,k)
           tem1 = coefm(i)/dxy(i)*(rho(i,kp1)+rho(i,k))*brvf(i)*velco(i,k)*0.5
           hd   = sqrt(taup(i,k) / tem1)
           fro  = brvf(i) * hd * temv



           tem2 = sqrt(usqj(i,k))
           tem  = 1. + tem2 * fro
           rim  = usqj(i,k) * (1.-fro) / (tem * tem)



           if (rim <= ric) then  
             temc = 2.0 + 1.0 / tem2
             hd   = velco(i,k) * (2.*sqrt(temc)-temc) / brvf(i)
             taup(i,kp1) = tem1 * hd * hd
           else                    
             taup(i,kp1) = taup(i,k)
           endif
         endif
       endif
     enddo
   enddo

   if (lcap < kte) then
     do klcap = lcapp1,kte
       do i = its,ite
         taup(i,klcap) = prsi(i,klcap) / prsi(i,lcap) * taup(i,lcap)
       enddo
     enddo
   endif
   do i = its,ite
     if (.not.ldrag(i)) then



       kblk = 0
       fbdpe = 0.
       fbdke = 0.
       do k = kte, kgwdmin, -1
         if (kblk==0 .and. k<=kbomax(i)) then
           fbdpe = fbdpe + bnv2(i,k)*(zl(i,komax(i))-zl(i,k))                  &
                   *del(i,k)/g_/rho(i,k)
           fbdke = 0.5*(u1(i,k)**2.+v1(i,k)**2.)



           if (fbdpe>=fbdke .and. k<=komax(i)) then
             kblk = k
             zblk = zl(i,kblk)-zl(i,kts)
           endif
         endif
       enddo
       if (kblk /= 0) then



         fbdcd = max(2.0-1.0/od(i),0.)
         taufb(i,kts) = 0.5*rhobar(i)*coefm(i)/area(i)*fbdcd*dxyp(i)           &
                        *olp(i)*zblk*ulow(i)**2
         tautem = taufb(i,kts)/real(kblk-kts)
         do k = kts+1, kblk
           taufb(i,k) = taufb(i,k-1) - tautem
         enddo



         taup(i,:) = taup(i,:) + taufb(i,:)
       endif
     endif
   enddo



   do k = kts,kte
     do i = its,ite
       taud(i,k) = 1. * (taup(i,k+1) - taup(i,k)) * g_ / del(i,k)
     enddo
   enddo



   do k = kts,kgwdmax-1
     do i = its,ite
       if (abs(taud(i,k)) >= qmin) then
         dtfac(i,k) = min(dtfac(i,k),abs(velco(i,k)/(deltim*taud(i,k))))
       endif
     enddo
   enddo



   do k = kgwdmax,kte-1
     do i = its,ite
       if (abs(taud(i,k)) >= qmin .and. prsl(i,k) <= pcutoff) then
         denfac = min(rho(i,k)/pcutoff_den,1.)
         dtfac(i,k) = min(dtfac(i,k),denfac*abs(velco(i,k)                     &
                     /(deltim*taud(i,k))))
       endif
     enddo
   enddo
   dtfac(:,kte) = dtfac(:,kte-1)

   do i = its,ite
     dusfc(i) = 0.
     dvsfc(i) = 0.
   enddo

   do k = kts,kte
     do i = its,ite
       taud(i,k) = taud(i,k) * dtfac(i,k)
       dtaux = taud(i,k) * xn(i)
       dtauy = taud(i,k) * yn(i)
       dtaux2d(i,k) = dtaux
       dtauy2d(i,k) = dtauy
       dudt(i,k) = dtaux
       dvdt(i,k) = dtauy
       dusfc(i)  = dusfc(i) + dtaux * del(i,k)
       dvsfc(i)  = dvsfc(i) + dtauy * del(i,k)
     enddo
   enddo

   do i = its,ite
     dusfc(i) = (-1./g_) * dusfc(i)
     dvsfc(i) = (-1./g_) * dvsfc(i)
   enddo



   do k = kts,kte
      do i = its,ite
         rublten(i,k) = rublten(i,k)+dudt(i,k)*cosa(i) + dvdt(i,k)*sina(i)
         rvblten(i,k) = rvblten(i,k)-dudt(i,k)*sina(i) + dvdt(i,k)*cosa(i)
         dtaux3d(i,k) = dtaux2d(i,k)*cosa(i) + dtauy2d(i,k)*sina(i)
         dtauy3d(i,k) =-dtaux2d(i,k)*sina(i) + dtauy2d(i,k)*cosa(i)
     enddo
   enddo
   do i = its,ite
      dusfcg(i) = dusfc(i)*cosa(i) + dvsfc(i)*sina(i)
      dvsfcg(i) =-dusfc(i)*sina(i) + dvsfc(i)*cosa(i)
   enddo
   return
   end subroutine bl_gwdo_run


 end module bl_gwdo

