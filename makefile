#SHELL := /bin/bash

CODE_DIR=build/code/imp
PWD=$(shell pwd)
LINT_FILE=${PWD}/${CODE_DIR}/lint_output
EXIT_FILE=${PWD}/exit.txt
STATUS=0

all:  build py-tests

init: 
	./init.sh

build: init
	make -f tangle-make -k all

py-tests:
	export PYTHONPATH=${PWD}/${CODE_DIR}; cd ${PWD}/${CODE_DIR}; python -m unittest discover

clean:	
	make -f tangle-make clean

