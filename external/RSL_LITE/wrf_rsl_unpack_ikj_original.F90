      SUBROUTINE wrf_rsl_unpack_ikj_original ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(ims:ime,kms:kme,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ie-is+1)*(ke-ks+1)+1
#endif
          SELECT CASE (ie-is+1)
          CASE (1)
            DO k = ks, ke
              outbuf(is,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          CASE (2)
            DO k = ks, ke
              outbuf(is,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+1,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          CASE (3)
            DO k = ks, ke
              outbuf(is,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+1,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+2,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          CASE (4)
            DO k = ks, ke
              outbuf(is,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+1,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+2,k,j) = inbuf(p)
              p = p + 1
              outbuf(is+3,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          CASE DEFAULT
          DO k = ks, ke
            DO i = is, ie
              outbuf(i,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
          END SELECT
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE wrf_rsl_unpack_ikj_original
