import cosmoslik as K
script = None

from libc.stdlib cimport malloc
from libc.string cimport memcpy

cdef extern from "Python.h":
    void Py_Initialize()

cdef public init_python_():
    Py_Initialize()

cdef public init_script_(char *name, int nname):
    filename = str(add_null_term(name,nname)).strip()
    print "filename: "+filename
    try:
        script = K.load_script(filename)
    except Exception as e:
        print e

cdef char* add_null_term(char *str, int nstr):
    cdef char *_str = <char*>malloc(sizeof(char)*(nstr+1))
    memcpy(_str,str,nstr)
    _str[nstr]=0
    return _str

    

cdef public test_():
    print "here"

