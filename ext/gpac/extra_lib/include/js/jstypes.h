/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/*
 * The contents of this file are subject to the Netscape Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/NPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code is Mozilla Communicator client code, released
 * March 31, 1998.
 *
 * The Initial Developer of the Original Code is Netscape
 * Communications Corporation.  Portions created by Netscape are
 * Copyright (C) 1998 Netscape Communications Corporation. All
 * Rights Reserved.
 *
 * Contributor(s): 
 *
 * Alternatively, the contents of this file may be used under the
 * terms of the GNU Public License (the "GPL"), in which case the
 * provisions of the GPL are applicable instead of those above.
 * If you wish to allow use of your version of this file only
 * under the terms of the GPL and not to allow others to use your
 * version of this file under the NPL, indicate your decision by
 * deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL.  If you do not delete
 * the provisions above, a recipient may use your version of this
 * file under either the NPL or the GPL.
 *
 * This Original Code has been modified by IBM Corporation.
 * Modifications made by IBM described herein are
 * Copyright (c) International Business Machines
 * Corporation, 2000
 *
 * Modifications to Mozilla code or documentation
 * identified per MPL Section 3.3
 *
 * Date             Modified by     Description of modification
 * 04/20/2000       IBM Corp.      OS/2 VisualAge build.
 */

/*
** File:                jstypes.h
** Description: Definitions of NSPR's basic types
**
** Prototypes and macros used to make up for deficiencies in ANSI environments
** that we have found.
**
** Since we do not wrap <stdlib.h> and all the other standard headers, authors
** of portable code will not know in general that they need these definitions.
** Instead of requiring these authors to find the dependent uses in their code
** and take the following steps only in those C files, we take steps once here
** for all C files.
**/

#ifndef jstypes_h___
#define jstypes_h___

#if defined(WIN32) && defined(EXPORT_JS_API)
#include "jsstddef.h"
#else
#include <stddef.h>
#endif

/***********************************************************************
** MACROS:      JS_EXTERN_API
**              JS_EXPORT_API
** DESCRIPTION:
**      These are only for externally visible routines and globals.  For
**      internal routines, just use "extern" for type checking and that
**      will not export internal cross-file or forward-declared symbols.
**      Define a macro for declaring procedures return types. We use this to
**      deal with windoze specific type hackery for DLL definitions. Use
**      JS_EXTERN_API when the prototype for the method is declared. Use
**      JS_EXPORT_API for the implementation of the method.
**
** Example:
**   in dowhim.h
**     JS_EXTERN_API( void ) DoWhatIMean( void );
**   in dowhim.c
**     JS_EXPORT_API( void ) DoWhatIMean( void ) { return; }
**
**
***********************************************************************/
#ifdef WIN32
/* These also work for __MWERKS__ */
#define JS_EXTERN_API(__type) extern _declspec(dllexport) __type
#define JS_EXPORT_API(__type) _declspec(dllexport) __type
#define JS_EXTERN_DATA(__type) extern _declspec(dllexport) __type
#define JS_EXPORT_DATA(__type) _declspec(dllexport) __type

#define JS_DLL_CALLBACK
#define JS_STATIC_DLL_CALLBACK(__x) static __x

#elif defined(WIN16)

#ifdef _WINDLL
#define JS_EXTERN_API(__type) extern __type _cdecl _export _loadds
#define JS_EXPORT_API(__type) __type _cdecl _export _loadds
#define JS_EXTERN_DATA(__type) extern __type _export
#define JS_EXPORT_DATA(__type) __type _export

#define JS_DLL_CALLBACK             __cdecl __loadds
#define JS_STATIC_DLL_CALLBACK(__x) static __x CALLBACK

#else /* this must be .EXE */
#define JS_EXTERN_API(__type) extern __type _cdecl _export
#define JS_EXPORT_API(__type) __type _cdecl _export
#define JS_EXTERN_DATA(__type) extern __type _export
#define JS_EXPORT_DATA(__type) __type _export

#define JS_DLL_CALLBACK             __cdecl __loadds
#define JS_STATIC_DLL_CALLBACK(__x) __x JS_DLL_CALLBACK
#endif /* _WINDLL */

#elif defined(XP_MAC)
#define JS_EXTERN_API(__type) extern __declspec(export) __type
#define JS_EXPORT_API(__type) __declspec(export) __type
#define JS_EXTERN_DATA(__type) extern __declspec(export) __type
#define JS_EXPORT_DATA(__type) __declspec(export) __type

#define JS_DLL_CALLBACK
#define JS_STATIC_DLL_CALLBACK(__x) static __x

#elif defined(XP_OS2_VACPP) 
#define JS_EXTERN_API(__type) extern __type
#define JS_EXPORT_API(__type) __type
#define JS_EXTERN_DATA(__type) extern __type
#define JS_EXPORT_DATA(__type) __type
#define JS_DLL_CALLBACK  _Optlink
#define JS_STATIC_DLL_CALLBACK(__x) static __x JS_DLL_CALLBACK

#else /* Unix */

#define JS_EXTERN_API(__type) extern __type
#define JS_EXPORT_API(__type) __type
#define JS_EXTERN_DATA(__type) extern __type
#define JS_EXPORT_DATA(__type) __type

#define JS_DLL_CALLBACK
#define JS_STATIC_DLL_CALLBACK(__x) static __x

#endif

#ifdef _WIN32
#  ifdef __MWERKS__
#    define JS_IMPORT_API(__x)      __x
#  else
#    define JS_IMPORT_API(__x)      _declspec(dllimport) __x
#  endif
#else
#    define JS_IMPORT_API(__x)      JS_EXPORT_API (__x)
#endif

#if defined(_WIN32) && !defined(__MWERKS__)
#    define JS_IMPORT_DATA(__x)      _declspec(dllimport) __x
#else
#    define JS_IMPORT_DATA(__x)     __x
#endif

/*
 * The linkage of JS API functions differs depending on whether the file is
 * used within the JS library or not.  Any source file within the JS
 * interpreter should define EXPORT_JS_API whereas any client of the library
 * should not.
 */
#ifdef EXPORT_JS_API
#define JS_PUBLIC_API(t)    JS_EXPORT_API(t)
#define JS_PUBLIC_DATA(t)   JS_EXPORT_DATA(t)
#else
#define JS_PUBLIC_API(t)    JS_IMPORT_API(t)
#define JS_PUBLIC_DATA(t)   JS_IMPORT_DATA(t)
#endif

#define JS_FRIEND_API(t)    JS_PUBLIC_API(t)
#define JS_FRIEND_DATA(t)   JS_PUBLIC_DATA(t)

#ifdef _WIN32
#   define JS_INLINE __inline
#elif defined(__GNUC__)
#   define JS_INLINE
#else
#   define JS_INLINE
#endif

/***********************************************************************
** MACROS:      JS_BEGIN_MACRO
**              JS_END_MACRO
** DESCRIPTION:
**      Macro body brackets so that macros with compound statement definitions
**      behave syntactically more like functions when called.
***********************************************************************/
#define JS_BEGIN_MACRO  do {
#define JS_END_MACRO    } while (0)

/***********************************************************************
** MACROS:      JS_BEGIN_EXTERN_C
**              JS_END_EXTERN_C
** DESCRIPTION:
**      Macro shorthands for conditional C++ extern block delimiters.
***********************************************************************/
#ifdef __cplusplus
#define JS_BEGIN_EXTERN_C       extern "C" {
#define JS_END_EXTERN_C         }
#else
#define JS_BEGIN_EXTERN_C
#define JS_END_EXTERN_C
#endif

/***********************************************************************
** MACROS:      JS_BIT
**              JS_BITMASK
** DESCRIPTION:
** Bit masking macros.  XXX n must be <= 31 to be portable
***********************************************************************/
#define JS_BIT(n)       ((JSUint32)1 << (n))
#define JS_BITMASK(n)   (JS_BIT(n) - 1)

/***********************************************************************
** MACROS:      JS_HOWMANY
**              JS_ROUNDUP
**              JS_MIN
**              JS_MAX
** DESCRIPTION:
**      Commonly used macros for operations on compatible types.
***********************************************************************/
#define JS_HOWMANY(x,y) (((x)+(y)-1)/(y))
#define JS_ROUNDUP(x,y) (JS_HOWMANY(x,y)*(y))
#define JS_MIN(x,y)     ((x)<(y)?(x):(y))
#define JS_MAX(x,y)     ((x)>(y)?(x):(y))

#if (defined(XP_MAC) || (defined(XP_PC) && !defined(XP_OS2))) && !defined(CROSS_COMPILE)
#    include "jscpucfg.h"        /* Use standard Mac or Windows configuration */
#elif defined(XP_UNIX) || defined(XP_BEOS) || defined(XP_OS2) || defined(CROSS_COMPILE)
#    include "jsautocfg.h"       /* Use auto-detected configuration */
#    include "jsosdep.h"         /* ...and platform-specific flags */
#else
#    error "Must define one of XP_PC, XP_MAC or XP_UNIX"
#endif

JS_BEGIN_EXTERN_C

/************************************************************************
** TYPES:       JSUint8
**              JSInt8
** DESCRIPTION:
**  The int8 types are known to be 8 bits each. There is no type that
**      is equivalent to a plain "char". 
************************************************************************/
#if JS_BYTES_PER_BYTE == 1
typedef unsigned char JSUint8;
typedef signed char JSInt8;
#else
#error No suitable type for JSInt8/JSUint8
#endif

/************************************************************************
** TYPES:       JSUint16
**              JSInt16
** DESCRIPTION:
**  The int16 types are known to be 16 bits each. 
************************************************************************/
#if JS_BYTES_PER_SHORT == 2
typedef unsigned short JSUint16;
typedef short JSInt16;
#else
#error No suitable type for JSInt16/JSUint16
#endif

/************************************************************************
** TYPES:       JSUint32
**              JSInt32
** DESCRIPTION:
**  The int32 types are known to be 32 bits each. 
************************************************************************/
#if JS_BYTES_PER_INT == 4
typedef unsigned int JSUint32;
typedef int JSInt32;
#define JS_INT32(x)  x
#define JS_UINT32(x) x ## U
#elif JS_BYTES_PER_LONG == 4
typedef unsigned long JSUint32;
typedef long JSInt32;
#define JS_INT32(x)  x ## L
#define JS_UINT32(x) x ## UL
#else
#error No suitable type for JSInt32/JSUint32
#endif

/************************************************************************
** TYPES:       JSUint64
**              JSInt64
** DESCRIPTION:
**  The int64 types are known to be 64 bits each. Care must be used when
**      declaring variables of type JSUint64 or JSInt64. Different hardware
**      architectures and even different compilers have varying support for
**      64 bit values. The only guaranteed portability requires the use of
**      the JSLL_ macros (see jslong.h).
************************************************************************/
#ifdef JS_HAVE_LONG_LONG
#if JS_BYTES_PER_LONG == 8
typedef long JSInt64;
typedef unsigned long JSUint64;
#elif defined(WIN16)
typedef __int64 JSInt64;
typedef unsigned __int64 JSUint64;
#elif defined(__MINGW32__)
typedef long long int JSInt64;
typedef unsigned long long int JSUint64;
#elif defined(WIN32)
typedef __int64  JSInt64;
typedef unsigned __int64 JSUint64;
#else
typedef long long JSInt64;
typedef unsigned long long JSUint64;
#endif /* JS_BYTES_PER_LONG == 8 */
#else  /* !JS_HAVE_LONG_LONG */
typedef struct {
#ifdef IS_LITTLE_ENDIAN
    JSUint32 lo, hi;
#else
    JSUint32 hi, lo;
#endif
} JSInt64;
typedef JSInt64 JSUint64;
#endif /* !JS_HAVE_LONG_LONG */

/************************************************************************
** TYPES:       JSUintn
**              JSIntn
** DESCRIPTION:
**  The JSIntn types are most appropriate for automatic variables. They are
**      guaranteed to be at least 16 bits, though various architectures may
**      define them to be wider (e.g., 32 or even 64 bits). These types are
**      never valid for fields of a structure. 
************************************************************************/
#if JS_BYTES_PER_INT >= 2
typedef int JSIntn;
typedef unsigned int JSUintn;
#else
#error 'sizeof(int)' not sufficient for platform use
#endif

/************************************************************************
** TYPES:       JSFloat64
** DESCRIPTION:
**  NSPR's floating point type is always 64 bits. 
************************************************************************/
typedef double          JSFloat64;

/************************************************************************
** TYPES:       JSSize
** DESCRIPTION:
**  A type for representing the size of objects. 
************************************************************************/
typedef size_t JSSize;

/************************************************************************
** TYPES:       JSPtrDiff
** DESCRIPTION:
**  A type for pointer difference. Variables of this type are suitable
**      for storing a pointer or pointer sutraction. 
************************************************************************/
typedef ptrdiff_t JSPtrdiff;

/************************************************************************
** TYPES:       JSUptrdiff
** DESCRIPTION:
**  A type for pointer difference. Variables of this type are suitable
**      for storing a pointer or pointer sutraction. 
************************************************************************/
typedef unsigned long JSUptrdiff;

/************************************************************************
** TYPES:       JSBool
** DESCRIPTION:
**  Use JSBool for variables and parameter types. Use JS_FALSE and JS_TRUE
**      for clarity of target type in assignments and actual arguments. Use
**      'if (bool)', 'while (!bool)', '(bool) ? x : y' etc., to test booleans
**      juast as you would C int-valued conditions. 
************************************************************************/
typedef JSIntn JSBool;
#define JS_TRUE (JSIntn)1
#define JS_FALSE (JSIntn)0

/************************************************************************
** TYPES:       JSPackedBool
** DESCRIPTION:
**  Use JSPackedBool within structs where bitfields are not desireable
**      but minimum and consistant overhead matters.
************************************************************************/
typedef JSUint8 JSPackedBool;

/*
** A JSWord is an integer that is the same size as a void*
*/
typedef long JSWord;
typedef unsigned long JSUword;

#include "jsotypes.h"

JS_END_EXTERN_C

#endif /* jstypes_h___ */

