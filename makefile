SHELL := /bin/bash

CODE_DIR=build/code
DOC_DIR=build/docs
PWD=$(shell pwd)
LINT_FILE=${PWD}/${CODE_DIR}/lint_output
EXIT_FILE=${PWD}/exit.txt
STATUS=0

all:  build run-py-tests

init: 
	./init.sh

build: init
	make -f tangle-make -k all
	export OAUTH_SERVICE=${PWD}
lint:  install-pep
	pep8 --ignore=E302 ${PWD}/${CODE_DIR} > ${LINT_FILE};

build-with-lint: build lint

clean:	
	make -f tangle-make clean
