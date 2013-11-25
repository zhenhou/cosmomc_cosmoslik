#ifndef __PYX_HAVE__coscos_wrapper
#define __PYX_HAVE__coscos_wrapper


/* "coscos_wrapper.pyx":4
 * # See corresponding line in coscos.f90
 * from libc.stdint cimport uint32_t, uint64_t
 * ctypedef public uint64_t ccint             # <<<<<<<<<<<<<<
 * ctypedef public double   ccreal
 * ctypedef public uint32_t ccnchar
 */
typedef uint64_t ccint;

/* "coscos_wrapper.pyx":5
 * from libc.stdint cimport uint32_t, uint64_t
 * ctypedef public uint64_t ccint
 * ctypedef public double   ccreal             # <<<<<<<<<<<<<<
 * ctypedef public uint32_t ccnchar
 * from numpy import float64 as np_ccreal
 */
typedef double ccreal;

/* "coscos_wrapper.pyx":6
 * ctypedef public uint64_t ccint
 * ctypedef public double   ccreal
 * ctypedef public uint32_t ccnchar             # <<<<<<<<<<<<<<
 * from numpy import float64 as np_ccreal
 * 
 */
typedef uint32_t ccnchar;

#ifndef __PYX_HAVE_API__coscos_wrapper

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

__PYX_EXTERN_C DL_IMPORT(void) init_coscos_(ccint *);
__PYX_EXTERN_C DL_IMPORT(PyObject) *print_last_exception_(void);
__PYX_EXTERN_C DL_IMPORT(void) init_script_(ccint *, char *, ccint *, ccnchar);
__PYX_EXTERN_C DL_IMPORT(void) get_num_params_(ccint *, ccint *);
__PYX_EXTERN_C DL_IMPORT(void) get_param_info_(ccint *, ccint *, char *, ccreal *, ccreal *, ccreal *, ccreal *, ccreal *, ccnchar);
__PYX_EXTERN_C DL_IMPORT(void) set_param_(ccint *, ccint *, ccreal *);
__PYX_EXTERN_C DL_IMPORT(void) get_lnl_(ccint *, ccreal *);
__PYX_EXTERN_C DL_IMPORT(void) set_cls_(ccint *, char *, ccreal *, ccint *, ccint *, ccnchar);

#endif /* !__PYX_HAVE_API__coscos_wrapper */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initcoscos_wrapper(void);
#else
PyMODINIT_FUNC PyInit_coscos_wrapper(void);
#endif

#endif /* !__PYX_HAVE__coscos_wrapper */
