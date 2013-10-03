#ifndef __PYX_HAVE__coscos_
#define __PYX_HAVE__coscos_


#ifndef __PYX_HAVE_API__coscos_

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

__PYX_EXTERN_C DL_IMPORT(PyObject) *init_python_(void);
__PYX_EXTERN_C DL_IMPORT(PyObject) *init_script_(char *, int);
__PYX_EXTERN_C DL_IMPORT(PyObject) *test_(void);

#endif /* !__PYX_HAVE_API__coscos_ */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initcoscos_(void);
#else
PyMODINIT_FUNC PyInit_coscos_(void);
#endif

#endif /* !__PYX_HAVE__coscos_ */
