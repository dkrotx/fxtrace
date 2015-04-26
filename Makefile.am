AUTOMAKE_OPTIONS = subdir-objects
ACLOCAL_AMFLAGS = ${ACLOCAL_FLAGS}

bin_SCRIPTS = src/fxtrace
CLEANFILES = $(bin_SCRIPTS)

lib_LTLIBRARIES = libfxtrace.la

do_subst = sed -e 's,[@]FXTRACE_SO_DIR[@],$(libdir),g'

man_MANS = fxtrace.1
EXTRA_DIST = fxtrace.1 src/fxtrace.sh


src/fxtrace: src/fxtrace.sh
	$(do_subst) < src/fxtrace.sh > src/fxtrace
	chmod ugo+x src/fxtrace


libfxtrace_la_SOURCES = src/fxtrace.c
libfxtrace_la_LDFLAGS = -version-info 0:1:0
libfxtrace_la_LIBADD = -ldl
