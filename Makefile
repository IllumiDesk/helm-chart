.PHONY: all prepare venv lint test clean

SHELL=/bin/bash

VENV_NAME?=venv
VENV_BIN=$(shell pwd)/${VENV_NAME}/bin
VENV_ACTIVATE=. ${VENV_BIN}/activate

PYTHON=${VENV_BIN}/python3

all:
	@echo "make prepare"
	@echo "    Create python virtual environment and install dependencies."
	@echo "make venv"
	@echo "    Create and activate virtual environment."
	@echo "make clean"
	@echo "    Remove python artifacts and virtualenv."

prepare:
	which virtualenv || python3 -m pip install virtualenv
	make venv

venv:
	test -d $(VENV_NAME) || virtualenv -p python3 $(VENV_NAME)
	$(VENV_BIN)/python3 -m pip install --upgrade pip
	$(VENV_BIN)/python3 -m pip install -r dev-requirements.txt

pip-compile: venv
	$(VENV_BIN)/pip-compile images/jupyterhub/requirements.in

build-jhub: pip-compile
	@docker build -t illumidesk/jupyterhub:py3.8 images/jupyterhub/.
	@docker build -t illumidesk/k8s-jhub:py3.8 -f images/jupyterhub/Dockerfile.k8 images/jupyterhub/.

build-push-jhubs: build-jhub
	@docker push illumidesk/jupyterhub:py3.8
	@docker push illumidesk/k8s-jhub:py3.8

clean:
	find . -name '*.pyc' -exec rm -f {} +
	rm -rf $(VENV_NAME) *.eggs *.egg-info dist build docs/_build .cache
