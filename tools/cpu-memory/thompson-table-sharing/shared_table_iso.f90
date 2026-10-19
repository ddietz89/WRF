module shared_table_iso
use iso_c_binding
implicit none
! Qualified MPI stack must have MPI_Fint represented by C int (C static_assert).
! Communicator is the caller's Fortran MPI integer handle, not MPI_COMM_WORLD in C.
interface
 function st_create(comm,staging,nbytes,opt,owner,view)bind(C)result(rc)
 import c_int,c_size_t,c_ptr
 integer(c_int),value::comm,opt
 type(c_ptr),value::staging
 integer(c_size_t),value::nbytes
 type(c_ptr)::owner,view
 integer(c_int)::rc
 end function
 function st_destroy(comm,owner,view)bind(C)result(rc)
 import c_int,c_ptr
 integer(c_int),value::comm
 type(c_ptr)::owner,view
 integer(c_int)::rc
 end function
 function st_describe(owner,r,nr,node,cr,cs,ncpu,nbytes)bind(C)result(rc)
 import c_int,c_size_t,c_ptr
 type(c_ptr),value::owner
 integer(c_int)::r,nr,node,cr,cs,ncpu
 integer(c_size_t)::nbytes
 integer(c_int)::rc
 end function
end interface
! Caller uses a genuine INTEGER(C_INT8_T),POINTER view, never ALLOCATABLE.
! No finalizer: all participants explicitly destroy before MPI_Finalize.
end module
