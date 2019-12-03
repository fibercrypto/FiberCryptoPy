.DEFAULT_GOAL := help
.PHONY: configure build-libc build-swig develop build-libc-swig build
.PHONY: test test-ci help

# Compilation output
.ONESHELL:
SHELL := /bin/bash

PYTHON_BIN   ?= python$(PYTHON)
MKFILE_PATH   = $(abspath $(lastword $(MAKEFILE_LIST)))
REPO_ROOT     = $(dir $(MKFILE_PATH))
GOPATH_DIR    = gopath
FCLIBC_DIR  ?= $(GOPATH_DIR)/src/github.com/fibercrypto/libfibercrypto
FCCOIN_DIR  ?= $(FCLIBC_DIR)/vendor/github.com/fibercrypto/FiberCryptoWallet
FCBUILD_DIR  = $(FCLIBC_DIR)/build
BUILDLIBC_DIR = $(FCBUILD_DIR)/libfibercrypto
LIBC_DIR      = $(FCLIBC_DIR)/lib/cgo
LIBSWIG_DIR   = swig
BUILD_DIR     = build
DIST_DIR      = dist
BIN_DIR       = $(FCLIBC_DIR)/bin
INCLUDE_DIR   = $(FCLIBC_DIR)/include
FULL_PATH_LIB = $(REPO_ROOT)/$(BUILDLIBC_DIR)

LIB_FILES = $(shell find $(FCLIBC_DIR)/lib/cgo -type f -name "*.go")
SRC_FILES = $(shell find $(FCCOIN_DIR)/src -type f -name "*.go")
SWIG_FILES = $(shell find $(LIBSWIG_DIR) -type f -name "*.i")
HEADER_FILES = $(shell find $(INCLUDE_DIR) -type f -name "*.h")


ifeq ($(shell uname -s),Linux)
	TEMP_DIR = tmp
	PYTHON_BIN = python$(PYTHON)
else ifeq ($(shell uname -s),Darwin)
	TEMP_DIR = $TMPDIR
	PYTHON_BIN = python
endif

configure: ## Configure build environment
	echo "Configure build environment"
	mkdir -p $(BUILD_DIR)/usr/tmp $(BUILD_DIR)/usr/lib $(BUILD_DIR)/usr/include
	mkdir -p $(BUILDLIBC_DIR) $(BIN_DIR) $(INCLUDE_DIR)
	mkdir -p $(DIST_DIR)


build-libc: configure ## Build libfibercrypto C client library
	echo "Build libfibercrypto C client library"
	GOPATH="$(REPO_ROOT)/$(GOPATH_DIR)" make -C $(FCLIBC_DIR) clean-libc
	GOPATH="$(REPO_ROOT)/$(GOPATH_DIR)" make -C $(FCLIBC_DIR) build-libc
	rm -f swig/include/libfibercrypto.h
	rm -f swig/include/swig.h
	mkdir -p swig/include
	cp $(FCLIBC_DIR)/include/swig.h swig/include/
	grep -v _Complex $(FCLIBC_DIR)/include/libfibercrypto.h > swig/include/libfibercrypto.h

build-swig: ## Generate Python C module from SWIG interfaces
	echo "Generate Python C module from SWIG interfaces"
	#Generate structs.i from FCtypes.gen.h
	rm -f $(LIBSWIG_DIR)/structs.i
	cp $(INCLUDE_DIR)/fctypes.gen.h $(LIBSWIG_DIR)/structs.i
	{ \
		if [[ "$$(uname -s)" == "Darwin" ]]; then \
			sed -i '.kbk' 's/#/%/g' $(LIBSWIG_DIR)/structs.i ;\
		else \
			sed -i 's/#/%/g' $(LIBSWIG_DIR)/structs.i ;\
		fi \
	}
	rm -fv fibercryptopy/fibercryptopy.py
	rm -f swig/fibercryptopy_wrap.c
	rm -f swig/include/swig.h
	swig -python -py3 -w501,505,401,302,509,451 -Iswig/include -I$(INCLUDE_DIR) -outdir ./fibercryptopy/ -o swig/fibercryptopy_wrap.c $(LIBSWIG_DIR)/fibercryptopy.i

develop: ## Install fibercryptopy for development
	$(PYTHON_BIN) setup.py develop

build-libc-swig: build-libc build-swig

build: build-libc-swig ## Build fibercryptopy Python package
	$(PYTHON_BIN) setup.py build

test-ci: build-libc build-swig develop ## Run tests on (Travis) CI build
	tox
	# (cd $(PYTHON_CLIENT_DIR) && tox)

test-libfc: build-libc build-swig develop ## Run project test suite by fibercryptopy
	echo "Run project test suite by fibercryptopy"
	$(PYTHON_BIN) setup.py test

test: test-libfc ## Run project test suite

sdist: ## Create source distribution archive
	$(PYTHON_BIN) setup.py sdist --formats=gztar

bdist_wheel: ## Create architecture-specific binary wheel distribution archive
	$(PYTHON_BIN) setup.py bdist_wheel

# FIXME: After libfibercrypto 32-bits binaries add bdist_manylinux_i686
bdist_manylinux: bdist_manylinux_amd64 ## Create multilinux binary wheel distribution archives

bdist_manylinux_amd64: ## Create 64 bits multilinux binary wheel distribution archives
	docker pull quay.io/pypa/manylinux1_x86_64
	docker run --rm -t -v $(REPO_ROOT):/io quay.io/pypa/manylinux1_x86_64 /io/.travis/build_wheels.sh
	ls wheelhouse/
	mkdir -p $(DIST_DIR)
	cp -v wheelhouse/* $(DIST_DIR)


bdist_manylinux_i686: ## Create 32 bits multilinux binary wheel distribution archives
	docker pull quay.io/pypa/manylinux1_i686
	docker run --rm -t -v $(REPO_ROOT):/io quay.io/pypa/manylinux1_i686 linux32 /io/.travis/build_wheels.sh
	ls wheelhouse/
	mkdir -p $(DIST_DIR)
	cp -v wheelhouse/* $(DIST_DIR)

dist: sdist bdist_wheel bdist_manylinux_amd64 ## Create distribution archives

check-dist: dist ## Perform self-tests upon distributions archives
	docker run --rm -t -v $(REPO_ROOT):/io quay.io/pypa/manylinux1_i686 linux32 /io/.travis/check_wheels.sh

format: ## Format code that autopep8
	autopep8 --in-place --aggressive --aggressive --aggressive --aggressive ./tests/*.py

lint: ## Linter to pylint
	pylint -E tests/*.py
	yamllint -d relaxed .travis.yml
	
clean: #Clean all
	make -C $(FCLIBC_DIR) clean-libc
	$(PYTHON_BIN) -m pip uninstall -y fibercryptopy
	rm -rfv tests/__pycache__
	rm -rfv fibercryptopy/__pycache__
	rm -rfv fibercryptopy/*.pyc
	rm -rfv tests/*.pyc
	rm -rfv tests/utils/*.pyc
	rm -rfv tests/utils/__pycache__
	rm -rfv *.so
	rm -rfv qemu_python_*
	$(PYTHON_BIN) setup.py clean
	

help: ## List available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'