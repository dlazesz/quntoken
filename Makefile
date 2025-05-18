# ABBREV := data/abbreviations_nytud-hu.txt
ABBREV := data/abbreviations_orig-hu.txt
MODULES := preproc hyphen snt sntcorr token convxml convjson convtsv convspl
# MODULES := token


# build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
all:
	@make -s build OPT='-ggdb'
	@make -s test
	@make -s packaging
.PHONY: all


build-docker:
	@rm -rf release/quntoken-*
	docker build -t quntoken-builder .
	docker run --rm -it -v $(PWD)/release:/build/release --user=$$(id -u):$$(id -g) quntoken-builder:latest
.PHONY: build-docker


release: clean
	@make -s build OPT='-O1'
	@make -s test
	@make -s targz
	@make -s packaging
.PHONY: release


packaging:
	@rm -rf build/
	@rm -rf dist/
	@rm -rf quntoken.egg-info/
	@venv/bin/pip3 show quntoken && venv/bin/pip3 uninstall -y quntoken || echo -n ''
	@venv/bin/python3 setup.py sdist bdist_wheel
	@venv/bin/pip3 install .
.PHONY: packaging

test:
	@venv/bin/pytest --verbose test/test_quntoken.py
.PHONY: test


targz:
	@tar -czf "quntoken_`uname -s`_`uname -m`_v`grep -Po '\d+\.\d+\.\d+' quntoken/version.py`.tar.gz" quntoken/qt_* quntoken/quntoken.py quntoken/__init__.py
.PHONY: targz


COMPILER := g++-5 $(OPT) -Wall -Werror -Wno-error=maybe-uninitialized -pedantic -static -std=c++11 -I./ -Iquex/ -DQUEX_OPTION_ASSERTS_DISABLED -DQUEX_OPTION_POSIX -DWITH_UTF8 -DQUEX_SETTING_BUFFER_SIZE=2097152 -DQUEX_OPTION_ASSERTS_DISABLED
build: quex
	@rm -f quntoken/qt_*
	@echo 'Compile binaries.'
	@cp src/cpp/main.cpp tmp/
	@cd tmp/ ; for module in $(MODULES) ; do \
		 { $(COMPILER) $${module}Lexer.cpp main.cpp -DLEXER_CLASS="$${module}Lexer" -DMYLEXER="\"$${module}Lexer\"" -o ../quntoken/qt_$${module} ; echo "- $${module}" ; } & \
	done ; wait ;
	@echo -e 'Done.\n'
.PHONY: build


QXCMD := export QUEX_PATH=quex ; python2 quex/quex-exe.py --bet wchar_t -i ../src/quex_modules/definitions.qx abbrev.qx
quex:
	@find tmp -maxdepth 1 -type f -exec rm -f {} \;
	@make -s abbrev
	@echo 'Run Quex.'
	@cd tmp/ ; for module in $(MODULES) ; do \
		{ $(QXCMD) ../src/quex_modules/$${module}.qx -o $${module}Lexer ; echo "- $${module}" ; } & \
	done ; wait ;
	@echo -e 'Done.\n'
.PHONY: quex


abbrev:
	@echo 'Generate abbrev.qx' ;
	@./src/scripts/generate_abbrev.qx.py -d $(ABBREV) -o tmp/abbrev.qx
	@echo -e 'Done.\n'
.PHONY: abbrev


# aux ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prereq: clean install_quex venv
.PHONY: prereq


venv:
	@rm -rf venv/
	python3 -m venv venv
	./venv/bin/pip3 install wheel  # Needed to be installed separately before other packages
	./venv/bin/pip3 install -r requirements-dev.txt
.PHONY: venv


clean:
	@rm -f quntoken/qt_*
	@[ -d "tmp" ] && find tmp -maxdepth 1 -type f -exec rm -f {} \; || :  # noop if tmp dir not exists
	@rm -rf build/
	@rm -rf dist/
	@rm -rf quntoken.egg-info/
.PHONY: clean


QUEX_VERSION = 0.67.5
QUEX_VERSION_MINOR = `echo $(QUEX_VERSION) | sed -E 's/\.[0-9]+$$//'`
QUEX_LINK = https://sourceforge.net/projects/quex/files/HISTORY/$(QUEX_VERSION_MINOR)/quex-$(QUEX_VERSION).tar.gz/download
install_quex:
	@rm -rf tmp/
	@mkdir -p tmp
	@cd tmp ; \
	rm -rf quex ; \
	wget -q -O quex.tar.gz $(QUEX_LINK) ; \
	tar zxf quex.tar.gz ; \
	mv quex-$(QUEX_VERSION)/ quex ; \
	rm quex.tar.gz
.PHONY: install_quex

