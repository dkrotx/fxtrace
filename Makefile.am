AUTOMAKE_OPTIONS = subdir-objects
ACLOCAL_AMFLAGS = ${ACLOCAL_FLAGS}

bin_SCRIPTS = src/fxtrace
CLEANFILES = $(bin_SCRIPTS)

lib_LTLIBRARIES = libfxtrace.la

do_subst = sed -e 's,[@]FXTRACE_SO_DIR[@],$(libdir),g'

man_MANS = fxtrace.1
EXTRA_DIST = fxtrace.1 src/fxtrace.sh tests


# We have to re-create src/fxtrace after ./configure with, for example, another prefix
# so depend on config.status. It should be changed every time after ./configure
src/fxtrace: src/fxtrace.sh config.status
	$(do_subst) < src/fxtrace.sh > src/fxtrace
	chmod ugo+x src/fxtrace

test: src/fxtrace
	@echo ========================================
	@echo LAUNCHING TESTS
	@echo ========================================
	@cd tests && ./run.sh


clean-local:
	-rm -rf tests/tmp


libfxtrace_la_SOURCES = src/fxtrace.c
libfxtrace_la_LDFLAGS = -version-info 0:1:0
libfxtrace_la_LIBADD = -ldl
