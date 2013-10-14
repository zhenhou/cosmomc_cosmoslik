# Manually make sure our C types and Fortran types are the same size 
# See corresponding line in coscos.f90
from libc.stdint cimport uint32_t, uint64_t 
ctypedef public uint64_t ccint
ctypedef public double   ccreal
ctypedef public uint32_t ccnchar
from numpy import float64 as np_ccreal


# This is needed so that Ctrl+C kills the program even if inside Python code
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)



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

cdef public void init_coscos_(ccint *_kill_on_error):
    Py_Initialize()
    initcoscos_wrapper()
    global kill_on_error
    kill_on_error = (_kill_on_error[0]==1)

cdef char* add_null_term(char *str, ccnchar nstr):
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


gscripts = {}

cdef public void init_script_(ccint *ccid, char *name, ccnchar nname):
    try:
        global gscripts
        script = K.load_script(str(add_null_term(name,nname)).strip())
        script._params = dict()
        gscripts[id(script)] = script
        ccid[0] = id(script)
    except Exception as e:
        handle_exception(e)


cdef public void get_num_params_(ccint *ccid, ccint *num_params):
    try:
        global gscripts
        num_params[0] = len(gscripts[ccid[0]].get_sampled())
    except Exception as e:
        handle_exception(e)



cdef public void get_param_info_(ccint *ccid,
                                 ccint *i, 
                                 char *paramname, 
                                 ccreal *start,
                                 ccreal *min, ccreal *max, 
                                 ccreal *width, ccreal *scale,
                                 ccnchar nparamname):
    try:
        global gscripts
        name,info = gscripts[ccid[0]].get_sampled().items()[i[0]-1]
        start[0] = info.start
        min[0] = getattr(info,'min',-inf)
        max[0] = getattr(info,'max',inf)
        width[0] = scale[0] = getattr(info,'scale',1)
        memcpy(paramname,<char*>name,len(name))
    except Exception as e:
        handle_exception(e)


cdef public void set_param_(ccint *ccid, ccint *i, ccreal *val):
    try:
        global gscripts
        script = gscripts[ccid[0]]
        script._params[script.get_sampled().keys()[i[0]-1]] = val[0]
    except Exception as e:
        handle_exception(e)


cdef public void get_lnl_(ccint *ccid, ccreal* lnl):
    try:
        global gscripts
        script = gscripts[ccid[0]]
        lnl[0] = script.evaluate(**script._params)[0]
    except Exception as e:
        handle_exception(e)





