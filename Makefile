.PHONY: help prepare venv lint test clean

SHELL=/bin/bash

VENV_NAME?=venv
VENV_BIN=$(shell pwd)/${VENV_NAME}/bin
VENV_ACTIVATE=. ${VENV_BIN}/activate

PYTHON=${VENV_BIN}/python3

help:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@echo "illumidesk/helm-chart"
	@echo "====================="
	@echo
	@grep -E '^[a-zA-Z0-9_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

venv: ## make virtual environment and install dev requirements
	which virtualenv || python3 -m pip install virtualenv
	test -d $(VENV_NAME) || virtualenv -p python3 $(VENV_NAME)
	$(VENV_BIN)/python3 -m pip install --upgrade pip
	$(VENV_BIN)/python3 -m pip install -r dev-requirements.txt

pip-compile: venv ## create requirements.txt using pip-compile (uses requirements.in as source)
	$(VENV_BIN)/pip-compile images/jupyterhub/requirements.in

clean:
	find . -name '*.pyc' -exec rm -f {} +
	rm -rf $(VENV_NAME) *.eggs *.egg-info dist build docs/_build .cache
