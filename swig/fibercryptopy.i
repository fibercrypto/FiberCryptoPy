%module fibercryptopy
%include "typemaps.i"
%{
	#define SWIG_FILE_WITH_INIT
	#include "libfibercrypto.h"
	#include "fctypes.h"
	#include "swig.h"
%}

//Apply strictly to python
%include "gopath/src/github.com/fibercrypto/libfibercrypto/lib/swig/common/common.i"
%include "gopath/src/github.com/fibercrypto/libfibercrypto/lib/swig/dynamic/dynamic.i"
%include "basic.i"

/* Find the modified copy of libfibercrypto */
%include "swig.h"
%include "libfibercrypto.h"
%include "structs.i"
%include "fcerrors.h"
%include "fctypes.h"
