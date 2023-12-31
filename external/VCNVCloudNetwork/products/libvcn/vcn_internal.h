//
//  vcn_internal.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_internal_h
#define vcn_internal_h

#include "attributes.h"

#define MAX_URL_SIZE 4096
#define SPACE_CHARS " \t\r\n"
#if HAVE_LIBC_MSVCRT
#include <crtversion.h>
#if defined(_VC_CRT_MAJOR_VERSION) && _VC_CRT_MAJOR_VERSION < 14
#pragma comment(linker, "/include:" EXTERN_PREFIX "avpriv_strtod")
#pragma comment(linker, "/include:" EXTERN_PREFIX "avpriv_snprintf")
#endif

#define avpriv_open ff_open
#define avpriv_tempfile ff_tempfile
#define PTRDIFF_SPECIFIER "Id"
#define SIZE_SPECIFIER "Iu"
#else
#define PTRDIFF_SPECIFIER "td"
#define SIZE_SPECIFIER "zu"
#endif
typedef void (*ff_parse_key_val_cb)(void *context, const char *key,
int key_len, char **dest, int *dest_len);

/**
 * A wrapper for open() setting O_CLOEXEC.
 */
av_warn_unused_result
int avpriv_open(const char *filename, int flags, ...);
#endif /* vcn_internal_h */
