import cosmoslik as K
import traceback
import sys

script = None
kill_on_error = None

from libc.stdlib cimport malloc
from libc.string cimport memcpy

cdef extern from "Python.h":
    void Py_Initialize()

cdef extern void initcoscos()

cdef public void init_coscos_(int *_kill_on_error):
    """
    Initialize the coscos plugin. This must be called before any other coscos functions are used. 

    Parameters:
    -----------
    int *_kill_on_error - 1 to exit the program and print a stack trace on a 
                          Python error, otherwise 0 to ignore Python errors

    """
    Py_Initialize()
    initcoscos()
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

cdef int handle_exception(e):
    """Handle exception e given the kill_on_error option."""
    global kill_on_error, last_exception
    last_exception = (type(e), e, sys.exc_info()[2], None, sys.stderr)
    if kill_on_error:
        print_exception(last_exception)
        exit(1)
    else:
        return -1



cdef public init_script_(char *name, int nname):
    """
    Initialize a CosmoSlik script.
    """
    global script
    try:
        script = K.load_script(str(add_null_term(name,nname)).strip())
    except Exception as e:
        handle_exception(e)
