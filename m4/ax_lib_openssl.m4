# ===========================================================================
#             ax_lib_openssl.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_LIB_OPENSSL([MINIMUM-VERSION])
#
# DESCRIPTION
#
#   This macro provides tests of availability of OpenSSL of
#   particular version or newer. This macros checks for OpenSSL
#   headers and libraries and defines compilation flags
#
#   Macro supports following options and their values:
#
#   1) Single-option usage:
#
#     --with-openssl - yes, no or path to OpenSSL installation prefix
#
#   This macro calls:
#
#     AC_SUBST(OPENSSL_CFLAGS)
#     AC_SUBST(OPENSSL_LDFLAGS)
#     AC_SUBST(OPENSSL_VERSION) - only if version requirement is used
#
#   And sets:
#
#     HAVE_OPENSSL
#
# LAST MODIFICATION
#
#   2008-04-12
#
# COPYLEFT
#
#   Copyright (c) 2008 Mateusz Loskot <mateusz@loskot.net>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved.

AC_DEFUN([AX_LIB_OPENSSL],
[
    AC_ARG_WITH([openssl],
        AC_HELP_STRING([--with-openssl=@<:@ARG@:>@],
            [use OpenSSL from given prefix (ARG=path); check standard prefixes (ARG=yes); disable (ARG=no)]
        ),
        [
        if test "$withval" = "yes"; then
            if test -d /usr/local/ssl/include ; then
                openssl_prefix=/usr/local/ssl
            elif test -d /usr/lib/ssl/include ; then
                openssl_prefix=/usr/lib/ssl
            else
                openssl_prefix=""
            fi
            openssl_requested="yes"
        elif test -d "$withval"; then
            openssl_prefix="$withval"
            openssl_requested="yes"
        else
            openssl_prefix=""
            openssl_requested="no"
        fi
        ],
        [
        dnl Default behavior is implicit yes
        if test -d /usr/local/ssl/include ; then
            openssl_prefix=/usr/local/ssl
        elif test -d /usr/lib/ssl/include ; then
            openssl_prefix=/usr/lib/ssl
        else
            openssl_prefix=""
        fi
        ]
    )

    OPENSSL_CPPFLAGS=""
    OPENSSL_LDFLAGS=""
    OPENSSL_VERSION=""

    dnl
    dnl Collect include/lib paths and flags
    dnl
    run_openssl_test="no"

    if test -n "$openssl_prefix"; then
        openssl_include_dir="$openssl_prefix/include"
        openssl_ldflags="-L$openssl_prefix/lib"
        run_openssl_test="yes"
    elif test "$openssl_requested" = "yes"; then
        if test -n "$openssl_include_dir" -a -n "$openssl_lib_flags"; then
            run_openssl_test="yes"
        fi
    else
        run_openssl_test="no"
    fi

    openssl_libs="-lssl -lcrypto"

    dnl
    dnl Check OpenSSL files
    dnl
    if test "$run_openssl_test" = "yes"; then

        saved_CPPFLAGS="$CPPFLAGS"
        CPPFLAGS="$CPPFLAGS -I$openssl_include_dir"

        saved_LDFLAGS="$LDFLAGS"
        LDFLAGS="$LDFLAGS $openssl_ldflags"

        saved_LIBS="$LIBS"
        LIBS="$openssl_libs $LIBS"

        dnl
        dnl Check OpenSSL headers
        dnl
        AC_MSG_CHECKING([for OpenSSL headers in $openssl_include_dir])

        AC_LANG_PUSH([C])
        AC_COMPILE_IFELSE([
            AC_LANG_PROGRAM(
                [[
@%:@include <openssl/opensslv.h>
@%:@include <openssl/ssl.h>
@%:@include <openssl/crypto.h>
                ]],
                [[]]
            )],
            [
            OPENSSL_CPPFLAGS="-I$openssl_include_dir"
            openssl_header_found="yes"
            AC_MSG_RESULT([found])
            ],
            [
            openssl_header_found="no"
            AC_MSG_RESULT([not found])
            ]
        )
        AC_LANG_POP([C])

        dnl
        dnl Check OpenSSL libraries
        dnl
        if test "$openssl_header_found" = "yes"; then

            AC_MSG_CHECKING([for OpenSSL libraries])

            AC_LANG_PUSH([C])
            AC_LINK_IFELSE([
                AC_LANG_PROGRAM(
                    [[
@%:@include <openssl/opensslv.h>
@%:@include <openssl/ssl.h>
@%:@include <openssl/crypto.h>
#if (OPENSSL_VERSION_NUMBER < 0x0090700f)
deliberate syntax error
#endif
                    ]],
                    [[
SSL_library_init();
SSLeay();
                    ]]
                )],
                [
                OPENSSL_LDFLAGS="$openssl_ldflags"
                OPENSSL_LIBS="$openssl_libs"
                openssl_lib_found="yes"
                AC_MSG_RESULT([found])
                ],
                [
                openssl_lib_found="no"
                AC_MSG_RESULT([not found])
                ]
            )
            AC_LANG_POP([C])
        fi

        CPPFLAGS="$saved_CPPFLAGS"
        LDFLAGS="$saved_LDFLAGS"
        LIBS="$saved_LIBS"
    fi

    AC_MSG_CHECKING([for OpenSSL])

    if test "$run_openssl_test" = "yes"; then
        if test "$openssl_header_found" = "yes" -a "$openssl_lib_found" = "yes"; then

            AC_SUBST([OPENSSL_CPPFLAGS])
            AC_SUBST([OPENSSL_LDFLAGS])
            AC_SUBST([OPENSSL_LIBS])

            HAVE_OPENSSL="yes"
        else
            HAVE_OPENSSL="no"
        fi

        AC_MSG_RESULT([$HAVE_OPENSSL])

        dnl
        dnl Check OpenSSL version
        dnl
        if test "$HAVE_OPENSSL" = "yes"; then

            openssl_version_req=ifelse([$1], [], [], [$1])

            if test  -n "$openssl_version_req"; then

                AC_MSG_CHECKING([if OpenSSL version is >= $openssl_version_req])

                if test -f "$openssl_include_dir/xercesc/util/XercesVersion.hpp"; then

                    openssl_major=`cat $xerces_include_dir/xercesc/util/XercesVersion.hpp | \
                                    grep '^#define.*OPENSSL_VERSION_MAJOR.*[0-9]$' | \
                                    sed -e 's/#define OPENSSL_VERSION_MAJOR.//'`

                    openssl_minor=`cat $xerces_include_dir/xercesc/util/XercesVersion.hpp | \
                                    grep '^#define.*OPENSSL_VERSION_MINOR.*[0-9]$' | \
                                    sed -e 's/#define OPENSSL_VERSION_MINOR.//'`

                    openssl_revision=`cat $xerces_include_dir/xercesc/util/XercesVersion.hpp | \
                                    grep '^#define.*OPENSSL_VERSION_REVISION.*[0-9]$' | \
                                    sed -e 's/#define OPENSSL_VERSION_REVISION.//'`

                    OPENSSL_VERSION="$xerces_major.$xerces_minor.$xerces_revision"
                    AC_SUBST([OPENSSL_VERSION])

                    dnl Decompose required version string and calculate numerical representation
                    xerces_version_req_major=`expr $xerces_version_req : '\([[0-9]]*\)'`
                    xerces_version_req_minor=`expr $xerces_version_req : '[[0-9]]*\.\([[0-9]]*\)'`
                    xerces_version_req_revision=`expr $xerces_version_req : '[[0-9]]*\.[[0-9]]*\.\([[0-9]]*\)'`
                    if test "x$openssl_version_req_revision" = "x"; then
                        openssl_version_req_revision="0"
                    fi

                    openssl_version_req_number=`expr $xerces_version_req_major \* 10000 \
                                               \+ $xerces_version_req_minor \* 100 \
                                               \+ $xerces_version_req_revision`

                    dnl Calculate numerical representation of detected version
                    openssl_version_number=`expr $xerces_major \* 10000 \
                                          \+ $xerces_minor \* 100 \
                                           \+ $xerces_revision`

                    openssl_version_check=`expr $openssl_version_number \>\= $openssl_version_req_number`
                    if test "$openssl_version_check" = "1"; then
                        AC_MSG_RESULT([yes])
                    else
                        AC_MSG_RESULT([no])
                        AC_MSG_WARN([Found OpenSSL $OPENSSL_VERSION, which is older than required. Possible compilation failure.])
                    fi
                else
                    AC_MSG_RESULT([no])
                    AC_MSG_WARN([Missing header XercesVersion.hpp. Unable to determine Xerces version.])
                fi
            fi
        fi

    else
        HAVE_OPENSSL="no"
        AC_MSG_RESULT([$HAVE_OPENSSL])

        if test "$openssl_requested" = "yes"; then
            AC_MSG_WARN([OpenSSL support requested but headers or library not found. Specify valid prefix of OpenSSL using --with-openssl=@<:@DIR@:>@])
        fi
    fi
    if test "$HAVE_OPENSSL" = "yes"; then
        CPPFLAGS="$CPPFLAGS $OPENSSL_CPPFLAGS -DHAVE_SSL=1"
        LDFLAGS="$LDFLAGS $OPENSSL_LDFLAGS $OPENSSL_LIBS"
    fi
])
