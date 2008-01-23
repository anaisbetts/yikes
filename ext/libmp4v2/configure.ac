AC_INIT(mp4.cpp)
AM_INIT_AUTOMAKE(libmp4v2, 1.5.0.1)

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_PROG_LIBTOOL

AC_CHECK_SIZEOF(long)

AC_CHECK_MEMBERS(fpos_t.__pos,,, [#include <stdio.h>])

AC_CONFIG_HEADERS(config.h)

AC_CONFIG_FILES([Makefile
                 doc/Makefile
                 test/Makefile
                 util/Makefile])
AC_OUTPUT
