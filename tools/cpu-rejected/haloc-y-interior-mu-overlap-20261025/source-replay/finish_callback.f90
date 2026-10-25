MODULE y_finish_module
USE iso_c_binding,ONLY:c_int
USE module_driver_constants,ONLY:DATA_ORDER_XZY
IMPLICIT NONE
INTEGER :: metadata(19)=0
CONTAINS
SUBROUTINE finish_pending_y(u,v,ims,ime,jms,jme,kms,kme)
 INTEGER,INTENT(IN)::ims,ime,jms,jme,kms,kme
 REAL,INTENT(INOUT)::u(ims:ime,kms:kme,jms:jme),v(ims:ime,kms:kme,jms:jme)
 INTEGER::comm,rank,np,ids,ide,jds,jde,kds,kde,ips,ipe,jps,jpe,kps,kpe,m,p,left,right,ierr,rc
 INTERFACE
  INTEGER(c_int)FUNCTION complete()BIND(C,name="rsl_lite_y_complete_exp_")
   IMPORT c_int
  END FUNCTION
 END INTERFACE
 comm=metadata(1);rank=metadata(2);np=metadata(3)
 ids=metadata(4);ide=metadata(5);jds=metadata(6);jde=metadata(7);kds=metadata(8);kde=metadata(9)
 ips=metadata(10);ipe=metadata(11);jps=metadata(12);jpe=metadata(13);kps=metadata(14);kpe=metadata(15)
 m=metadata(16);p=metadata(17)
 rc=complete();IF(rc/=0)ERROR STOP 'private COMPLETE failed'
 CALL pack(0,1,m,p)
 m=metadata(18);p=metadata(19)
 CALL RSL_LITE_INIT_EXCH(comm,1,1,1,m,1,p,1,m,1,p, &
 2,0,4,0,0,4,0,0,8,0,0,4,rank,np,2,2,ips,ipe,jps,jpe,kps,kpe)
 CALL pack(1,0,m,p)
 CALL RSL_LITE_EXCH_X(comm,rank,np,2,2,m,p,m,p)
 CALL pack(1,1,m,p)
 CONTAINS
 SUBROUTINE pack(xy,pu,m,p)
 INTEGER,INTENT(IN)::xy,pu,m,p
 CALL RSL_LITE_PACK(comm,u,1,1,m,1,p,1,m,1,p,4,xy,pu,DATA_ORDER_XZY,1, &
 rank,np,2,2,ids,ide,jds,jde,kds,kde,ims,ime,jms,jme,kms,kme,ips,ipe,jps,jpe,kps,kpe)
 CALL RSL_LITE_PACK(comm,v,1,1,m,1,p,1,m,1,p,4,xy,pu,DATA_ORDER_XZY,0, &
 rank,np,2,2,ids,ide,jds,jde,kds,kde,ims,ime,jms,jme,kms,kme,ips,ipe,jps,jpe,kps,kpe)
 END SUBROUTINE
END SUBROUTINE
END MODULE
