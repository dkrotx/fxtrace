AUTOMAKE_OPTIONS = subdir-objects
ACLOCAL_AMFLAGS = ${ACLOCAL_FLAGS}

bin_SCRIPTS = src/fxtrace
CLEANFILES = $(bin_SCRIPTS)

lib_LTLIBRARIES = libfxtrace.la

do_subst = sed -e 's,[@]FXTRACE_SO_DIR[@],$(libdir),g'

man_MANS = fxtrace.1

TESTS = tests/T-01_usage.sh \
	tests/T-02_longopts.sh \
	tests/T-03_bugfix_relative_log.sh \
	tests/T-04_relprefix.sh \
	tests/T-05_nodirs.sh \
	tests/T-06_access_flags.sh


EXTRA_DIST = $(man_MANS) src/fxtrace.sh $(TESTS) tests/test.incl.sh

installcheck-local:
	@echo Perfoming \`make check\` on installed binaries
	INSTALLCHECK=yes; export INSTALLCHECK; \
				 AUTOTEST_PATH=$(exec_prefix)/bin; export AUTOTEST_PATH; \
				 $(MAKE) check


# We have to re-create src/fxtrace after ./configure with, for example, another prefix
# so depend on config.status. It should be changed every time after ./configure
src/fxtrace: src/fxtrace.sh config.status
	$(do_subst) <$(srcdir)/src/fxtrace.sh >src/fxtrace
	chmod ugo+x src/fxtrace


libfxtrace_la_SOURCES = src/fxtrace.c
libfxtrace_la_LDFLAGS = -version-info 0:3:0
libfxtrace_la_LIBADD = -ldl
