PYTHON ?= python3
.PHONY: check test demo
check:
	$(PYTHON) validation/check_project.py
test: check
	$(PYTHON) -m pytest validation -q
demo:
	$(PYTHON) validation/run_demo.py --output-dir demo_outputs
