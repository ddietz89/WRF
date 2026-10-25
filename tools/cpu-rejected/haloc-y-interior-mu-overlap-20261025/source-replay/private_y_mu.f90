MODULE private_y_mu_module
USE module_configure,ONLY:grid_config_rec_type
IMPLICIT NONE
CONTAINS
SUBROUTINE advance_mu_t_y_private( ww, ww_1, u, u_1, v, v_1,            &
                         mu, mut, muave, muts, muu, muv, mudf,&
                         c1h, c2h, c1f, c2f,                  &
                         c3h, c4h, c3f, c4f,                  &
                         uam, vam, wwam, t, t_1,              &
                         t_ave, ft, mu_tend,                  &
                         rdx, rdy, dts, epssm,                &
                         dnw, fnm, fnp, rdnw,                 &
                         msfux, msfuy, msfvx, msfvx_inv,      &
                         msfvy, msftx, msfty,                 &
                         step, config_flags,                  &
                         ids, ide, jds, jde, kds, kde,        &
                         ims, ime, jms, jme, kms, kme,        &
                         its, ite, jts, jte, kts, kte, ips, ipe, jps, jpe, finish_exchange )
  IMPLICIT NONE  

  TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags
  INTEGER,      INTENT(IN   )    :: ids,ide, jds,jde, kds,kde
  INTEGER,      INTENT(IN   )    :: ims,ime, jms,jme, kms,kme
  INTEGER,      INTENT(IN   )    :: its,ite, jts,jte, kts,kte
  INTEGER,      INTENT(IN   )    :: step
  REAL, DIMENSION( ims:ime , kms:kme, jms:jme ),   &
            INTENT(IN   ) ::                       &
                                              u_1, &
                                              v_1, &
                                              t_1, &
                                              ft
  REAL, DIMENSION(ims:ime,kms:kme,jms:jme), INTENT(INOUT) :: u,v
  REAL, DIMENSION( ims:ime , kms:kme, jms:jme ),      &
            INTENT(INOUT) ::                          &
                                              ww,     &
                                              ww_1,   &
                                              t,      &
                                              t_ave,  &
                                              uam,    &
                                              vam,    &
                                              wwam
                                              
  REAL, DIMENSION( ims:ime , jms:jme ),    INTENT(IN   ) :: muu,  &
                                                            muv,  &
                                                            mut,  &
                                                            msfux,&
                                                            msfuy,&
                                                            msfvx,&
                                                            msfvx_inv,&
                                                            msfvy,&
                                                            msftx,&
                                                            msfty,&
                                                            mu_tend
  REAL, DIMENSION( ims:ime , jms:jme ),    INTENT(  OUT) :: muave, &
                                                            muts,  &
                                                            mudf
  REAL, DIMENSION( ims:ime , jms:jme ),    INTENT(INOUT) :: mu
  REAL, DIMENSION( kms:kme ),              INTENT(IN   ) :: fnm,    &
                                                            fnp,    &
                                                            dnw,    &
                                                            rdnw
  REAL,                                    INTENT(IN   ) :: rdx,    &
                                                            rdy,    &
                                                            dts,    &
                                                            epssm
  REAL, DIMENSION( kms:kme ),INTENT(IN   ) :: c1h, c2h, c1f, c2f, &
                                              c3h, c4h, c3f, c4f

  REAL, DIMENSION (its:ite, kts:kte) :: wdtn, dvdxi
  REAL, DIMENSION (its:ite) :: dmdt
  INTEGER :: i, j, k, kk, i_start, i_end, j_start, j_end, k_start, k_end
  INTEGER :: i_endu, j_endv
  REAL    :: acc









  INTEGER, INTENT(IN) :: ips,ipe,jps,jpe
  INTEGER :: aa,bb,cc,dd,ci0,ci1,cj0,cj1,mid,tile,lo,hi
  INTERFACE
    SUBROUTINE finish_exchange(u,v,ims,ime,jms,jme,kms,kme)
      INTEGER, INTENT(IN) :: ims,ime,jms,jme,kms,kme
      REAL, INTENT(INOUT) :: u(ims:ime,kms:kme,jms:jme),v(ims:ime,kms:kme,jms:jme)
    END SUBROUTINE
  END INTERFACE
  i_start = its
  i_end   = min(ite,ide-1)
  j_start = jts
  j_end   = min(jte,jde-1)
  k_start = kts
  k_end   = kte-1
  IF ( .NOT. config_flags%periodic_x )THEN
     IF ( config_flags%specified .or. config_flags%nested ) then
       i_start = max(its,ids+1)
       i_end   = min(ite,ide-2)
     ENDIF
  ENDIF
  IF ( config_flags%specified .or. config_flags%nested ) then
     j_start = max(jts,jds+1)
     j_end   = min(jte,jde-2)
  ENDIF
  i_endu = ite
  j_endv = jte


  aa=i_start;bb=i_end;cc=j_start;dd=j_end
  ci0=max(aa,ips+1);ci1=min(bb,ipe-1)
  cj0=max(cc,jps+1);cj1=min(dd,jpe-1)
  mid=(jts+jte)/2
  IF(ci0<=ci1.AND.cj0<=cj1)THEN
    DO tile=1,2
      lo=jts;hi=mid
      IF(tile==2)THEN
        lo=mid+1;hi=jte
      ENDIF
      CALL rectangle(ci0,ci1,max(cj0,lo),min(cj1,hi))
    ENDDO
  ENDIF
  CALL finish_exchange(u,v,ims,ime,jms,jme,kms,kme)
  DO tile=1,2
    lo=max(cc,jts);hi=min(dd,mid)
    IF(tile==2)THEN
      lo=max(cc,mid+1);hi=min(dd,jte)
    ENDIF
    IF(ci0>ci1.OR.cj0>cj1)THEN
      CALL rectangle(aa,bb,lo,hi)
    ELSE
      CALL rectangle(aa,bb,lo,min(hi,cj0-1))
      CALL rectangle(aa,ci0-1,max(lo,cj0),min(hi,cj1))
      CALL rectangle(ci1+1,bb,max(lo,cj0),min(hi,cj1))
      CALL rectangle(aa,bb,max(lo,cj1+1),hi)
    ENDIF
  ENDDO
CONTAINS
  SUBROUTINE rectangle(ia,ib,ja,jb)
    INTEGER,INTENT(IN)::ia,ib,ja,jb
    IF(ia>ib.OR.ja>jb)RETURN
    i_start=ia;i_end=ib;j_start=ja;j_end=jb
   DO j = j_start, j_end
     DO i=i_start, i_end
            DMDT(i) = 0.
     ENDDO





















     DO k=k_start, k_end
!$OMP SIMD
     DO i=i_start, i_end
         dvdxi(i,k) = msftx(i,j)*msfty(i,j)*(                                      &
                     rdy*( (v(i,k,j+1)+(c1h(k)*muv(i,j+1)+c2h(k))*v_1(i,k,j+1)*msfvx_inv(i,j+1))   &
                          -(v(i,k,j  )+(c1h(k)*muv(i,j  )+c2h(k))*v_1(i,k,j  )*msfvx_inv(i,j  )) ) &
                    +rdx*( (u(i+1,k,j)+(c1h(k)*muu(i+1,j)+c2h(k))*u_1(i+1,k,j)/msfuy(i+1,j))       &
                          -(u(i,k,j  )+(c1h(k)*muu(i  ,j)+c2h(k))*u_1(i,k,j  )/msfuy(i  ,j)) ))
        DMDT(i)    = DMDT(i) + dnw(k)*dvdxi(i,k)
     ENDDO
     ENDDO
     DO i=i_start, i_end
       MUAVE(i,j) = MU(i,j)
       MU(i,j) = MU(i,j)+dts*(DMDT(i)+MU_TEND(i,j))
       MUDF(i,j) = (DMDT(i)+MU_TEND(i,j)) 
       MUTS(i,j) = MUT(i,j)+MU(i,j)
       MUAVE(i,j) =.5*((1.+epssm)*MU(i,j)+(1.-epssm)*MUAVE(i,j))
     ENDDO
     DO kk=2,k_end
     k=kk-1
     DO i=i_start, i_end
       ww(i,kk,j)=ww(i,kk-1,j)-dnw(kk-1)*((c1h(k)*dmdt(i))+dvdxi(i,kk-1)+(c1h(k)*mu_tend(i,j)))/msfty(i,j)
       ww(i,kk-1,j)=ww(i,kk-1,j)-ww_1(i,kk-1,j)
     ENDDO
     END DO
     IF (k_end>=1) THEN
     DO i=i_start, i_end
       ww(i,k_end,j)=ww(i,k_end,j)-ww_1(i,k_end,j)
     END DO
     END IF

   ENDDO















   DO j=j_start, j_end
     DO k=1,k_end
     DO i=i_start, i_end
       t_ave(i,k,j) = t(i,k,j)
       t   (i,k,j) = t(i,k,j) + msfty(i,j)*dts*ft(i,k,j)
     END DO
     END DO
   ENDDO   
   DO j=j_start, j_end
     DO i=i_start, i_end
       wdtn(i,1  )=0.
       wdtn(i,kde)=0.
     ENDDO
     DO k=2,k_end
     kk = k-1
     DO i=i_start, i_end
        wdtn(i,k)= ww(i,k,j)*(fnm(k)*t_1(i,k  ,j)+fnp(k)*t_1(i,k-1,j))
       t(i,kk,j) = t(i,kk,j) - dts*msfty(i,j)*(              &
                          
                          msftx(i,j)*(                     &
               .5*rdy*                                     &
              ( v(i,kk,j+1)*(t_1(i,kk,j+1)+t_1(i,kk, j ))     &
               -v(i,kk,j  )*(t_1(i,kk, j )+t_1(i,kk,j-1)) )   &
             + .5*rdx*                                     &
              ( u(i+1,kk,j)*(t_1(i+1,kk,j)+t_1(i  ,kk,j))     &
               -u(i  ,kk,j)*(t_1(i  ,kk,j)+t_1(i-1,kk,j)) ) ) &
             + rdnw(kk)*( wdtn(i,kk+1)-wdtn(i,kk) ) )       
     ENDDO
     ENDDO
     IF(k_end>=1)THEN
       k = k_end
       DO i=i_start, i_end
         t(i,k,j) = t(i,k,j) - dts*msfty(i,j)*( msftx(i,j)*( .5*rdy* ( v(i,k,j+1)*(t_1(i,k,j+1)+t_1(i,k, j )) -v(i,k,j  )*(t_1(i,k, j )+t_1(i,k,j-1)) ) + .5*rdx* ( u(i+1,k,j)*(t_1(i+1,k,j)+t_1(i  ,k,j)) -u(i  ,k,j)*(t_1(i  ,k,j)+t_1(i-1,k,j)) ) ) + rdnw(k)*( wdtn(i,k+1)-wdtn(i,k) ) )       
       ENDDO
     ENDIF

   ENDDO
  END SUBROUTINE rectangle
END SUBROUTINE advance_mu_t_y_private
END MODULE private_y_mu_module
