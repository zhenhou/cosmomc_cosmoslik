import cosmoslik as K
import traceback
import sys, os
from numpy import inf

scripts = None
kill_on_error = None
params = None

from libc.stdlib cimport malloc
from libc.string cimport memcpy

cdef extern from "Python.h":
    void Py_Initialize()

cdef extern void initcoscos_wrapper()

cdef public void init_coscos_(int *_kill_on_error):
    Py_Initialize()
    initcoscos_wrapper()
    global kill_on_error
    kill_on_error = (_kill_on_error[0]==1)

cdef char* add_null_term(char *str, int nstr):
    """Convert a Fortran string to a C string by adding a null terminating character"""
    cdef char *_str = <char*>malloc(sizeof(char)*(nstr+1))
    memcpy(_str,str,nstr)
    _str[nstr]=0
    return _str

   
cdef public print_last_exception_():
    """Print a stack-trace for the last Python exception"""
    global last_exception
    print_exception(last_exception)

def print_exception(e):
    """Print a Python exception."""
    traceback.print_exception(*e)

cdef void handle_exception(e):
    """Handle exception e given the kill_on_error option."""
    global kill_on_error, last_exception
    last_exception = (type(e), e, sys.exc_info()[2], None, sys.stderr)
    if kill_on_error:
        print_exception(last_exception)
        os._exit(1)



cdef public void init_script_(char *name, int nname):
    try:
        global script, params
        script = K.load_script(str(add_null_term(name,nname)).strip())
        params = dict()
    except Exception as e:
        handle_exception(e)


cdef public int get_num_params_(int *num_params):
    try:
        global script
        num_params[0] = len(script.get_sampled())
    except Exception as e:
        handle_exception(e)



cdef public void get_param_info_(int *i, char *paramname, 
                                 double *start,
                                 double *min, double *max, 
                                 double *width, double *scale,
                                 int nparamname):
    try:
        global script
        name,info = script.get_sampled().items()[i[0]-1]
        start[0] = info.start
        min[0] = getattr(info,'min',-inf)
        max[0] = getattr(info,'max',inf)
        width[0] = scale[0] = getattr(info,'scale',1)
        memcpy(paramname,<char*>name,len(name))
    except Exception as e:
        handle_exception(e)


cdef public void set_param_(int *i, double *val):
    try:
        global params, script
        params[script.get_sampled().keys()[i[0]-1]] = val[0]
    except Exception as e:
        handle_exception(e)


cdef public void get_lnl_(double* lnl):
    try:
        global script, params
        lnl[0] = script.evaluate(**params)[0]
    except Exception as e:
        handle_exception(e)





