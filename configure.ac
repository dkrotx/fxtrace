AC_PREREQ([2.59])
AC_INIT([fxtrace], [0.3], [https://github.com/dkrotx/fxtrace/])

# This is where autoconf automatically generated files go
AC_CONFIG_AUX_DIR([config])

AC_ENABLE_SHARED
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AM_INIT_AUTOMAKE([1.9.6 no-define])
AC_CONFIG_HEADERS([config.h])

# Checks for programs.

AM_PROG_CC_C_O

# Checks for libraries.
AC_CHECK_LIB([dl], [dlsym], [], AC_MSG_ERROR([Could not find dl library]))

# Checks for header files.
AC_CHECK_HEADERS([dlfcn.h linux/limits.h stdarg.h stdlib.h stdio.h string.h unistd.h fcntl.h assert.h])
AC_CHECK_TYPES([size_t, ssize_t, mode_t])

# Checks for library functions.
AC_HEADER_MAJOR
AC_CHECK_FUNCS([dlsym realpath strncmp strncpy])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
