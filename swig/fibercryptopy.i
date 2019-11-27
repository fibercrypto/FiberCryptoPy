%module fibercryptopy
%{
	#define SWIG_FILE_WITH_INIT
	#include "libfibercrypto.h"
	#include "fctypes.h"
%}

//Apply strictly to python

/* Find the modified copy of libfibercrypto */
%include "libfibercrypto.h"
%include "structs.i"
%include "fcerrors.h"
%include "fctypes.h"
