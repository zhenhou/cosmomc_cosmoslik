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
from numpy import inf, pi, arange, zeros, hstack
from collections import OrderedDict

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

cdef public void init_script_(ccint *slik_id, char *name, ccint *set_cls_externally, ccnchar nname):
    try:
        global gscripts
        script = K.load_script(str(add_null_term(name,nname)).strip(),_cls_set_externally=(set_cls_externally[0]==1))
        script._params = dict()
        gscripts[id(script)] = script
        slik_id[0] = id(script)
    except Exception as e:
        handle_exception(e)


cdef public void get_num_params_(ccint *slik_id, ccint *num_params):
    try:
        global gscripts
        num_params[0] = len(get_sampled(gscripts[slik_id[0]]))
    except Exception as e:
        handle_exception(e)

def get_sampled(slik):
    params = slik.get_sampled()
    if slik.params._cls_set_externally:
        return OrderedDict([(k,v) for k,v in params.items() if not k.startswith('cosmo.')])
    else:
        return params 
    
cdef get_script(ccint *slik_id):
    global gscripts
    return gscripts[slik_id[0]]


cdef public void get_param_info_(ccint *slik_id,
                                 ccint *i, 
                                 char *paramname, 
                                 ccreal *start,
                                 ccreal *min, ccreal *max, 
                                 ccreal *width, ccreal *scale,
                                 ccnchar nparamname):
    try:
        name,info = get_sampled(get_script(slik_id)).items()[i[0]-1]
        start[0] = info.start
        min[0] = getattr(info,'min',getattr(info,'range',[-inf])[0])
        max[0] = getattr(info,'max',getattr(info,'range',[inf])[-1])
        width[0] = scale[0] = getattr(info,'scale',1)
        memcpy(paramname,<char*>name,len(name))
    except Exception as e:
        handle_exception(e)


cdef public void set_param_(ccint *slik_id, ccint *i, ccreal *val):
    try:
        script = get_script(slik_id)
        script._params[get_sampled(script).keys()[i[0]-1]] = val[0]
    except Exception as e:
        handle_exception(e)


cdef public void get_lnl_(ccint *slik_id, ccreal *lnl):
    try:
        script = get_script(slik_id)
        if not all([k in script._params for k in get_sampled(script)]):
            raise Exception("CosmoSlik params not set: "+str([k for k in get_sampled(script) if k not in script._params]))
        lnl[0] = script.evaluate(**script._params)[0]
        script._params = dict()
    except Exception as e:
        handle_exception(e)

cdef public void set_cls_(ccint *slik_id, char *type, ccreal *cls, ccint *lmin, ccint *lmax, ccnchar ntype):
    cdef int i, l
    try:
        _cls = hstack([zeros(lmin[0]),arange(lmin[0],lmax[0]+1)*(arange(lmin[0],lmax[0]+1)+1)/2/pi])
        for i,l in enumerate(arange(lmin[0],lmax[0]+1)): _cls[l]*=cls[i]
        get_script(slik_id)._params.setdefault('cmb_result',K.SlikDict())['cl_%s'%str(add_null_term(type,ntype))] = _cls
#         from matplotlib.pyplot import semilogy, show, loglog, title
#         loglog(arange(lmin[0],lmax[0]),_cls[lmin[0]:lmax[0]])
#         title(str(add_null_term(type,ntype)))
#         show()
    except Exception as e:
        handle_exception(e)




