/*
 * QuickJS C library
 *
 * Copyright (c) 2017-2019 Fabrice Bellard
 * Copyright (c) 2017-2019 Charlie Gordon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32)
#include <io.h>
#if defined(_MSC_VER)
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif
#include <winsock.h>
#else
#if !defined(__WASI_SDK__)
#include <dlfcn.h>
#include <termios.h>
#endif
#include <sys/ioctl.h>
#include <sys/time.h>
#include <unistd.h>
#if defined(__APPLE__)
typedef sig_t sighandler_t;
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include "cutils.h"
#include "list.h"
#include "quickjs-libc.h"
#ifdef __cplusplus
}
#endif

#if defined(_WIN32)
int gettimeofday(struct timeval *tp, void *tzp) {
  static const uint64_t EPOCH = ((uint64_t)116444736000000000ULL);

  SYSTEMTIME system_time;
  FILETIME file_time;
  uint64_t time;

  GetSystemTime(&system_time);
  SystemTimeToFileTime(&system_time, &file_time);
  time = ((uint64_t)file_time.dwLowDateTime);
  time += ((uint64_t)file_time.dwHighDateTime) << 32;

  tp->tv_sec = (long)((time - EPOCH) / 10000000L);
  tp->tv_usec = (long)(system_time.wMilliseconds * 1000);
  return 0;
}
#endif

#if LYNX_SIMPLIFY
static void lepus_std_dbuf_init(LEPUSContext *ctx, DynBuf *s) {
  dbuf_init2(s, LEPUS_GetRuntime(ctx), (DynBufReallocFunc *)lepus_realloc_rt);
}

/* TODO:
   - add exec() wrapper
   - add minimal VT100 emulation for win32
   - add socket calls
*/

typedef struct {
  struct list_head link;
  int fd;
  LEPUSValue rw_func[2];
} LEPUSOSRWHandler;

typedef struct {
  struct list_head link;
  int sig_num;
  LEPUSValue func;
} LEPUSOSSignalHandler;
#endif

typedef struct {
  struct list_head link;
  BOOL has_object;
  int64_t timeout;
  LEPUSValue func;
} LEPUSOSTimer;

/* initialize the lists so lepus_std_free_handlers() can always be called */
#if LYNX_SIMPLIFY
static struct list_head os_rw_handlers = LIST_HEAD_INIT(os_rw_handlers);
static struct list_head os_signal_handlers = LIST_HEAD_INIT(os_signal_handlers);
#endif
static struct list_head os_timers = LIST_HEAD_INIT(os_timers);
static uint64_t os_pending_signals;
#if LYNX_SIMPLIFY
static int eval_script_recurse;
#endif

static int (*os_poll_func)(LEPUSContext *ctx);

#if LYNX_SIMPLIFY
static LEPUSValue lepus_printf_internal(LEPUSContext *ctx, int argc,
                                        LEPUSValueConst *argv, FILE *fp) {
  char fmtbuf[32];
  uint8_t cbuf[UTF8_CHAR_LEN_MAX + 1];
  LEPUSValue res;
  DynBuf dbuf;
  const char *fmt_str;
  const uint8_t *fmt, *fmt_end;
  const uint8_t *p;
  char *q;
  int i, c, len;
  size_t fmt_len;
  int32_t int32_arg;
  int64_t int64_arg;
  double double_arg;
  const char *string_arg;
  enum { PART_FLAGS, PART_WIDTH, PART_DOT, PART_PREC, PART_MODIFIER } part;
  int modsize;
  /* Use indirect call to dbuf_printf to prevent gcc warning */
  int (*dbuf_printf_fun)(DynBuf * s, const char *fmt, ...) = dbuf_printf;

  lepus_std_dbuf_init(ctx, &dbuf);

  if (argc > 0) {
    fmt_str = LEPUS_ToCStringLen(ctx, &fmt_len, argv[0]);
    if (!fmt_str) goto fail;

    i = 1;
    fmt = (const uint8_t *)fmt_str;
    fmt_end = fmt + fmt_len;
    while (fmt < fmt_end) {
      for (p = fmt; fmt < fmt_end && *fmt != '%'; fmt++) continue;
      dbuf_put(&dbuf, p, fmt - p);
      if (fmt >= fmt_end) break;
      q = fmtbuf;
      *q++ = *fmt++; /* copy '%' */
      part = PART_FLAGS;
      modsize = 0;
      for (;;) {
        if (q >= fmtbuf + sizeof(fmtbuf) - 1) goto invalid;

        c = *fmt++;
        *q++ = c;
        *q = '\0';

        switch (c) {
          case '1':
          case '2':
          case '3':
          case '4':
          case '5':
          case '6':
          case '7':
          case '8':
          case '9':
            if (part != PART_PREC) {
              if (part <= PART_WIDTH)
                part = PART_WIDTH;
              else
                goto invalid;
            }
            continue;

          case '0':
          case '#':
          case '+':
          case '-':
          case ' ':
          case '\'':
            if (part > PART_FLAGS) goto invalid;
            continue;

          case '.':
            if (part > PART_DOT) goto invalid;
            part = PART_DOT;
            continue;

          case '*':
            if (part < PART_WIDTH)
              part = PART_DOT;
            else if (part == PART_DOT)
              part = PART_MODIFIER;
            else
              goto invalid;

            if (i >= argc) goto missing;

            if (LEPUS_ToInt32(ctx, &int32_arg, argv[i++])) goto fail;
            q--;
            q += snprintf(q, fmtbuf + sizeof(fmtbuf) - q, "%d", int32_arg);
            continue;

          case 'h':
            if (modsize != 0 && modsize != -1) goto invalid;
            modsize--;
            part = PART_MODIFIER;
            continue;
          case 'l':
            q--;
            if (modsize != 0 && modsize != 1) goto invalid;
            modsize++;
            part = PART_MODIFIER;
            continue;

          case 'c':
            if (i >= argc) goto missing;
            if (LEPUS_IsString(argv[i])) {
              string_arg = LEPUS_ToCString(ctx, argv[i++]);
              if (!string_arg) goto fail;
              int32_arg = unicode_from_utf8((uint8_t *)string_arg,
                                            UTF8_CHAR_LEN_MAX, &p);
              LEPUS_FreeCString(ctx, string_arg);
            } else {
              if (LEPUS_ToInt32(ctx, &int32_arg, argv[i++])) goto fail;
            }
            /* handle utf-8 encoding explicitly */
            if ((unsigned)int32_arg > 0x10FFFF) int32_arg = 0xFFFD;
            /* ignore conversion flags, width and precision */
            len = unicode_to_utf8(cbuf, int32_arg);
            dbuf_put(&dbuf, cbuf, len);
            break;

          case 'd':
          case 'i':
          case 'o':
          case 'u':
          case 'x':
          case 'X':
            if (i >= argc) goto missing;
            if (modsize > 0) {
              if (LEPUS_ToInt64(ctx, &int64_arg, argv[i++])) goto fail;
              q[1] = q[-1];
              q[-1] = q[0] = 'l';
              q[2] = '\0';
              dbuf_printf_fun(&dbuf, fmtbuf, (long long)int64_arg);
            } else {
              if (LEPUS_ToInt32(ctx, &int32_arg, argv[i++])) goto fail;
              dbuf_printf_fun(&dbuf, fmtbuf, int32_arg);
            }
            break;

          case 's':
            if (i >= argc) goto missing;
            string_arg = LEPUS_ToCString(ctx, argv[i++]);
            if (!string_arg) goto fail;
            dbuf_printf_fun(&dbuf, fmtbuf, string_arg);
            LEPUS_FreeCString(ctx, string_arg);
            break;

          case 'e':
          case 'f':
          case 'g':
          case 'a':
          case 'E':
          case 'F':
          case 'G':
          case 'A':
            if (i >= argc) goto missing;
            if (LEPUS_ToFloat64(ctx, &double_arg, argv[i++])) goto fail;
            dbuf_printf_fun(&dbuf, fmtbuf, double_arg);
            break;

          case '%':
            dbuf_putc(&dbuf, '%');
            break;

          default:
            /* XXX: should support an extension mechanism */
          invalid:
            LEPUS_ThrowTypeError(
                ctx, "invalid conversion specifier in format string");
            goto fail;
          missing:
            LEPUS_ThrowReferenceError(
                ctx, "missing argument for conversion specifier");
            goto fail;
        }
        break;
      }
    }
    LEPUS_FreeCString(ctx, fmt_str);
  }
  if (dbuf.error) {
    res = LEPUS_ThrowOutOfMemory(ctx);
  } else {
    if (fp) {
      len = fwrite(dbuf.buf, 1, dbuf.size, fp);
      res = LEPUS_NewInt32(ctx, len);
    } else {
      res = LEPUS_NewStringLen(ctx, (char *)dbuf.buf, dbuf.size);
    }
  }
  dbuf_free(&dbuf);
  return res;

fail:
  dbuf_free(&dbuf);
  return LEPUS_EXCEPTION;
}

uint8_t *lepus_load_file(LEPUSContext *ctx, size_t *pbuf_len,
                         const char *filename) {
  FILE *f;
  uint8_t *buf;
  size_t buf_len;

  f = fopen(filename, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  buf_len = ftell(f);
  fseek(f, 0, SEEK_SET);
  if (ctx)
    buf = static_cast<uint8_t *>(lepus_malloc(ctx, buf_len + 1));
  else
    buf = static_cast<uint8_t *>(malloc(buf_len + 1));
  fread(buf, 1, buf_len, f);
  buf[buf_len] = '\0';
  fclose(f);
  *pbuf_len = buf_len;
  return buf;
}
/* load and evaluate a file */
static LEPUSValue lepus_loadScript(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  uint8_t *buf;
  const char *filename;
  LEPUSValue ret;
  size_t buf_len;

  filename = LEPUS_ToCString(ctx, argv[0]);
  if (!filename) return LEPUS_EXCEPTION;
  buf = lepus_load_file(ctx, &buf_len, filename);
  if (!buf) {
    LEPUS_ThrowReferenceError(ctx, "could not load '%s'", filename);
    LEPUS_FreeCString(ctx, filename);
    return LEPUS_EXCEPTION;
  }
  ret = LEPUS_Eval(ctx, (char *)buf, buf_len, filename, LEPUS_EVAL_TYPE_GLOBAL);
  lepus_free(ctx, buf);
  LEPUS_FreeCString(ctx, filename);
  return ret;
}

#endif

typedef LEPUSModuleDef *(LEPUSInitModuleFunc)(LEPUSContext *ctx,
                                              const char *module_name);

#if LYNX_SIMPLIFY
static LEPUSModuleDef *lepus_module_loader_so(LEPUSContext *ctx,
                                              const char *module_name) {
  LEPUS_ThrowReferenceError(ctx,
                            "shared library modules are not supported yet");
  return NULL;
}

LEPUSModuleDef *lepus_module_loader(LEPUSContext *ctx, const char *module_name,
                                    void *opaque) {
  LEPUSModuleDef *m;

  if (has_suffix(module_name, ".so")) {
    m = lepus_module_loader_so(ctx, module_name);
  } else {
    size_t buf_len;
    uint8_t *buf;
    LEPUSValue func_val;

    buf = lepus_load_file(ctx, &buf_len, module_name);
    if (!buf) {
      LEPUS_ThrowReferenceError(ctx, "could not load module filename '%s'",
                                module_name);
      return NULL;
    }

    /* compile the module */
    func_val =
        LEPUS_Eval(ctx, (char *)buf, buf_len, module_name,
                   LEPUS_EVAL_TYPE_MODULE | LEPUS_EVAL_FLAG_COMPILE_ONLY);
    lepus_free(ctx, buf);
    if (LEPUS_IsException(func_val)) return NULL;
    /* the module is already referenced, so we must free it */
    m = static_cast<LEPUSModuleDef *>(LEPUS_VALUE_GET_PTR(func_val));
    LEPUS_FreeValue(ctx, func_val);
  }
  return m;
}

static LEPUSValue lepus_std_exit(LEPUSContext *ctx, LEPUSValueConst this_val,
                                 int argc, LEPUSValueConst *argv) {
  int status;
  if (LEPUS_ToInt32(ctx, &status, argv[0])) status = -1;
  exit(status);
  return LEPUS_UNDEFINED;
}

static LEPUSValue lepus_std_getenv(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  const char *name, *str;
  name = LEPUS_ToCString(ctx, argv[0]);
  if (!name) return LEPUS_EXCEPTION;
  str = getenv(name);
  LEPUS_FreeCString(ctx, name);
  if (!str)
    return LEPUS_UNDEFINED;
  else
    return LEPUS_NewString(ctx, str);
}

static LEPUSValue lepus_std_gc(LEPUSContext *ctx, LEPUSValueConst this_val,
                               int argc, LEPUSValueConst *argv) {
  LEPUS_RunGC(LEPUS_GetRuntime(ctx));
  return LEPUS_UNDEFINED;
}

static int interrupt_handler(LEPUSRuntime *rt, void *opaque) {
  return (os_pending_signals >> SIGINT) & 1;
}

static LEPUSValue lepus_evalScript(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  const char *str;
  size_t len;
  LEPUSValue ret;
  str = LEPUS_ToCStringLen(ctx, &len, argv[0]);
  if (!str) return LEPUS_EXCEPTION;
  if (++eval_script_recurse == 1) {
    /* install the interrupt handler */
    LEPUS_SetInterruptHandler(LEPUS_GetRuntime(ctx), interrupt_handler, NULL);
  }
  ret = LEPUS_Eval(ctx, str, len, "<evalScript>", LEPUS_EVAL_TYPE_GLOBAL);
  LEPUS_FreeCString(ctx, str);
  if (--eval_script_recurse == 0) {
    /* remove the interrupt handler */
    LEPUS_SetInterruptHandler(LEPUS_GetRuntime(ctx), NULL, NULL);
    os_pending_signals &= ~((uint64_t)1 << SIGINT);
    /* convert the uncatchable "interrupted" error into a normal error
       so that it can be caught by the REPL */
    if (LEPUS_IsException(ret)) LEPUS_ResetUncatchableError(ctx);
  }
  return ret;
}

static LEPUSClassID lepus_std_file_class_id;

typedef struct {
  FILE *f;
  BOOL close_in_finalizer;
} LEPUSSTDFile;

static void lepus_std_file_finalizer(LEPUSRuntime *rt, LEPUSValue val) {
  LEPUSSTDFile *s = static_cast<LEPUSSTDFile *>(
      LEPUS_GetOpaque(val, lepus_std_file_class_id));
  if (s) {
    if (s->f && s->close_in_finalizer) fclose(s->f);
    lepus_free_rt(rt, s);
  }
}

static LEPUSValue lepus_new_std_error(LEPUSContext *ctx, int err) {
  LEPUSValue obj;
  /* XXX: could add a specific Error prototype */
  obj = LEPUS_NewError(ctx);
  LEPUS_DefinePropertyValueStr(ctx, obj, "message",
                               LEPUS_NewString(ctx, strerror(err)),
                               LEPUS_PROP_WRITABLE | LEPUS_PROP_CONFIGURABLE);
  LEPUS_DefinePropertyValueStr(ctx, obj, "errno", LEPUS_NewInt32(ctx, err),
                               LEPUS_PROP_WRITABLE | LEPUS_PROP_CONFIGURABLE);
  return obj;
}

static LEPUSValue lepus_std_error_constructor(LEPUSContext *ctx,
                                              LEPUSValueConst new_target,
                                              int argc, LEPUSValueConst *argv) {
  int err;
  if (LEPUS_ToInt32(ctx, &err, argv[0])) return LEPUS_EXCEPTION;
  return lepus_new_std_error(ctx, err);
}

static LEPUSValue lepus_std_error_strerror(LEPUSContext *ctx,
                                           LEPUSValueConst this_val, int argc,
                                           LEPUSValueConst *argv) {
  int err;
  if (LEPUS_ToInt32(ctx, &err, argv[0])) return LEPUS_EXCEPTION;
  return LEPUS_NewString(ctx, strerror(err));
}

static LEPUSValue lepus_std_throw_errno(LEPUSContext *ctx, int err) {
  LEPUSValue obj;
  obj = lepus_new_std_error(ctx, err);
  if (LEPUS_IsException(obj)) obj = LEPUS_NULL;
  return LEPUS_Throw(ctx, obj);
}

static LEPUSValue lepus_new_std_file(LEPUSContext *ctx, FILE *f,
                                     BOOL close_in_finalizer) {
  LEPUSSTDFile *s;
  LEPUSValue obj;
  obj = LEPUS_NewObjectClass(ctx, lepus_std_file_class_id);
  if (LEPUS_IsException(obj)) return obj;
  s = static_cast<LEPUSSTDFile *>(lepus_mallocz(ctx, sizeof(*s)));
  if (!s) {
    LEPUS_FreeValue(ctx, obj);
    return LEPUS_EXCEPTION;
  }
  s->close_in_finalizer = close_in_finalizer;
  s->f = f;
  LEPUS_SetOpaque(obj, s);
  return obj;
}

static LEPUSValue lepus_std_open(LEPUSContext *ctx, LEPUSValueConst this_val,
                                 int argc, LEPUSValueConst *argv) {
  const char *filename, *mode = NULL;
  FILE *f;

  filename = LEPUS_ToCString(ctx, argv[0]);
  if (!filename) goto fail;
  mode = LEPUS_ToCString(ctx, argv[1]);
  if (!mode) goto fail;
  if (mode[strspn(mode, "rwa+b")] != '\0') {
    lepus_std_throw_errno(ctx, EINVAL);
    goto fail;
  }

  f = fopen(filename, mode);
  LEPUS_FreeCString(ctx, filename);
  LEPUS_FreeCString(ctx, mode);
  if (!f) return lepus_std_throw_errno(ctx, errno);
  return lepus_new_std_file(ctx, f, TRUE);
fail:
  LEPUS_FreeCString(ctx, filename);
  LEPUS_FreeCString(ctx, mode);
  return LEPUS_EXCEPTION;
}

static LEPUSValue lepus_std_tmpfile(LEPUSContext *ctx, LEPUSValueConst this_val,
                                    int argc, LEPUSValueConst *argv) {
  FILE *f;
  f = tmpfile();
  if (!f) return lepus_std_throw_errno(ctx, errno);
  return lepus_new_std_file(ctx, f, TRUE);
}

static LEPUSValue lepus_std_sprintf(LEPUSContext *ctx, LEPUSValueConst this_val,
                                    int argc, LEPUSValueConst *argv) {
  return lepus_printf_internal(ctx, argc, argv, NULL);
}

static LEPUSValue lepus_std_printf(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  return lepus_printf_internal(ctx, argc, argv, stdout);
}

static FILE *lepus_std_file_get(LEPUSContext *ctx, LEPUSValueConst obj) {
  LEPUSSTDFile *s = static_cast<LEPUSSTDFile *>(
      LEPUS_GetOpaque2(ctx, obj, lepus_std_file_class_id));
  if (!s) return NULL;
  if (!s->f) {
    lepus_std_throw_errno(ctx, EBADF);
    return NULL;
  }
  return s->f;
}

static LEPUSValue lepus_std_file_puts(LEPUSContext *ctx,
                                      LEPUSValueConst this_val, int argc,
                                      LEPUSValueConst *argv, int magic) {
  FILE *f;
  int i;
  const char *str;

  if (magic == 0) {
    f = stdout;
  } else {
    f = lepus_std_file_get(ctx, this_val);
    if (!f) return LEPUS_EXCEPTION;
  }

  for (i = 0; i < argc; i++) {
    str = LEPUS_ToCString(ctx, argv[i]);
    if (!str) return LEPUS_EXCEPTION;
    fputs(str, f);
    LEPUS_FreeCString(ctx, str);
  }
  return LEPUS_UNDEFINED;
}

static LEPUSValue lepus_std_file_close(LEPUSContext *ctx,
                                       LEPUSValueConst this_val, int argc,
                                       LEPUSValueConst *argv) {
  LEPUSSTDFile *s = static_cast<LEPUSSTDFile *>(
      LEPUS_GetOpaque2(ctx, this_val, lepus_std_file_class_id));
  if (!s) return LEPUS_EXCEPTION;
  if (!s->f) return lepus_std_throw_errno(ctx, EBADF);
  fclose(s->f);
  s->f = NULL;
  return LEPUS_UNDEFINED;
}

static LEPUSValue lepus_std_file_printf(LEPUSContext *ctx,
                                        LEPUSValueConst this_val, int argc,
                                        LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  if (!f) return LEPUS_EXCEPTION;
  return lepus_printf_internal(ctx, argc, argv, f);
}

static LEPUSValue lepus_std_file_flush(LEPUSContext *ctx,
                                       LEPUSValueConst this_val, int argc,
                                       LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  if (!f) return LEPUS_EXCEPTION;
  fflush(f);
  return LEPUS_UNDEFINED;
}

static LEPUSValue lepus_std_file_tell(LEPUSContext *ctx,
                                      LEPUSValueConst this_val, int argc,
                                      LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  int64_t pos;
  if (!f) return LEPUS_EXCEPTION;
#if defined(__linux__)
  pos = ftello(f);
#else
  pos = ftell(f);
#endif
  return LEPUS_NewInt64(ctx, pos);
}

static LEPUSValue lepus_std_file_seek(LEPUSContext *ctx,
                                      LEPUSValueConst this_val, int argc,
                                      LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  int64_t pos;
  int whence, ret;
  if (!f) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt64(ctx, &pos, argv[0])) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt32(ctx, &whence, argv[1])) return LEPUS_EXCEPTION;
#if defined(__linux__)
  ret = fseeko(f, pos, whence);
#else
  ret = fseek(f, pos, whence);
#endif
  if (ret < 0) return lepus_std_throw_errno(ctx, EBADF);
  return LEPUS_UNDEFINED;
}

static LEPUSValue lepus_std_file_eof(LEPUSContext *ctx,
                                     LEPUSValueConst this_val, int argc,
                                     LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  if (!f) return LEPUS_EXCEPTION;
  return LEPUS_NewBool(ctx, feof(f));
}

static LEPUSValue lepus_std_file_fileno(LEPUSContext *ctx,
                                        LEPUSValueConst this_val, int argc,
                                        LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  if (!f) return LEPUS_EXCEPTION;
  return LEPUS_NewInt32(ctx, fileno(f));
}

static LEPUSValue lepus_std_file_read_write(LEPUSContext *ctx,
                                            LEPUSValueConst this_val, int argc,
                                            LEPUSValueConst *argv, int magic) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  uint64_t pos, len;
  size_t size, ret;
  uint8_t *buf;

  if (!f) return LEPUS_EXCEPTION;
  if (LEPUS_ToIndex(ctx, &pos, argv[1])) return LEPUS_EXCEPTION;
  if (LEPUS_ToIndex(ctx, &len, argv[2])) return LEPUS_EXCEPTION;
  buf = LEPUS_GetArrayBuffer(ctx, &size, argv[0]);
  if (!buf) return LEPUS_EXCEPTION;
  if (pos + len > size)
    return LEPUS_ThrowRangeError(ctx, "read/write array buffer overflow");
  if (magic)
    ret = fwrite(buf + pos, 1, len, f);
  else
    ret = fread(buf + pos, 1, len, f);
  return LEPUS_NewInt64(ctx, ret);
}

/* XXX: could use less memory and go faster */
static LEPUSValue lepus_std_file_getline(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  int c;
  DynBuf dbuf;
  LEPUSValue obj;

  if (!f) return LEPUS_EXCEPTION;

  lepus_std_dbuf_init(ctx, &dbuf);
  for (;;) {
    c = fgetc(f);
    if (c == EOF) {
      if (dbuf.size == 0) {
        /* EOF */
        dbuf_free(&dbuf);
        return LEPUS_NULL;
      } else {
        break;
      }
    }
    if (c == '\n') break;
    if (dbuf_putc(&dbuf, c)) {
      dbuf_free(&dbuf);
      return LEPUS_ThrowOutOfMemory(ctx);
    }
  }
  obj = LEPUS_NewStringLen(ctx, (const char *)dbuf.buf, dbuf.size);
  dbuf_free(&dbuf);
  return obj;
}

/* XXX: could use less memory and go faster */
static LEPUSValue lepus_std_file_readAsString(LEPUSContext *ctx,
                                              LEPUSValueConst this_val,
                                              int argc, LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  int c;
  DynBuf dbuf;
  LEPUSValue obj;
  uint64_t max_size64;
  size_t max_size;
  LEPUSValueConst max_size_val;

  if (!f) return LEPUS_EXCEPTION;

  if (argc >= 1)
    max_size_val = argv[0];
  else
    max_size_val = LEPUS_UNDEFINED;
  max_size = (size_t)-1;
  if (!LEPUS_IsUndefined(max_size_val)) {
    if (LEPUS_ToIndex(ctx, &max_size64, max_size_val)) return LEPUS_EXCEPTION;
    if (max_size64 < max_size) max_size = max_size64;
  }

  lepus_std_dbuf_init(ctx, &dbuf);
  while (max_size != 0) {
    c = fgetc(f);
    if (c == EOF) break;
    if (dbuf_putc(&dbuf, c)) {
      dbuf_free(&dbuf);
      return LEPUS_EXCEPTION;
    }
    max_size--;
  }
  obj = LEPUS_NewStringLen(ctx, (const char *)dbuf.buf, dbuf.size);
  dbuf_free(&dbuf);
  return obj;
}

static LEPUSValue lepus_std_file_getByte(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  if (!f) return LEPUS_EXCEPTION;
  return LEPUS_NewInt32(ctx, fgetc(f));
}

static LEPUSValue lepus_std_file_putByte(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv) {
  FILE *f = lepus_std_file_get(ctx, this_val);
  int c;
  if (!f) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt32(ctx, &c, argv[0])) return LEPUS_EXCEPTION;
  c = fputc(c, f);
  return LEPUS_NewInt32(ctx, c);
}

/* urlGet */

#define URL_GET_PROGRAM "curl -s -i"
#define URL_GET_BUF_SIZE 4096

static int http_get_header_line(FILE *f, char *buf, size_t buf_size,
                                DynBuf *dbuf) {
  int c;
  char *p;

  p = buf;
  for (;;) {
    c = fgetc(f);
    if (c < 0) return -1;
    if ((p - buf) < buf_size - 1) *p++ = c;
    if (dbuf) dbuf_putc(dbuf, c);
    if (c == '\n') break;
  }
  *p = '\0';
  return 0;
}

static int http_get_status(const char *buf) {
  const char *p = buf;
  while (*p != ' ' && *p != '\0') p++;
  if (*p != ' ') return 0;
  while (*p == ' ') p++;
  return atoi(p);
}

#ifdef _WIN32
static LEPUSValue lepus_std_urlGet(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  return LEPUS_UNDEFINED;
}
#else
static LEPUSValue lepus_std_urlGet(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv) {
  const char *url;
  DynBuf cmd_buf;
  DynBuf data_buf_s, *data_buf = &data_buf_s;
  DynBuf header_buf_s, *header_buf = &header_buf_s;
  char *buf;
  size_t i, len;
  int c, status;
  LEPUSValue val, response = LEPUS_UNDEFINED, ret_obj;
  LEPUSValueConst options_obj;
  FILE *f;
  BOOL binary_flag, full_flag;

  url = LEPUS_ToCString(ctx, argv[0]);
  if (!url) return LEPUS_EXCEPTION;

  binary_flag = FALSE;
  full_flag = FALSE;

  if (argc >= 2) {
    options_obj = argv[1];

    val = LEPUS_GetPropertyStr(ctx, options_obj, "binary");
    if (LEPUS_IsException(val)) goto fail_opt;
    binary_flag = LEPUS_ToBool(ctx, val);
    LEPUS_FreeValue(ctx, val);

    val = LEPUS_GetPropertyStr(ctx, options_obj, "full");
    if (LEPUS_IsException(val)) {
    fail_opt:
      LEPUS_FreeCString(ctx, url);
      return LEPUS_EXCEPTION;
    }
    full_flag = LEPUS_ToBool(ctx, val);
    LEPUS_FreeValue(ctx, val);
  }

  lepus_std_dbuf_init(ctx, &cmd_buf);
  dbuf_printf(&cmd_buf, "%s ''", URL_GET_PROGRAM);
  len = strlen(url);
  for (i = 0; i < len; i++) {
    c = url[i];
    if (c == '\'' || c == '\\') dbuf_putc(&cmd_buf, '\\');
    dbuf_putc(&cmd_buf, c);
  }
  LEPUS_FreeCString(ctx, url);
  dbuf_putstr(&cmd_buf, "''");
  dbuf_putc(&cmd_buf, '\0');
  if (dbuf_error(&cmd_buf)) {
    dbuf_free(&cmd_buf);
    return LEPUS_EXCEPTION;
  }
  //    printf("%s\n", (char *)cmd_buf.buf);
  f = popen((char *)cmd_buf.buf, "r");
  dbuf_free(&cmd_buf);
  if (!f) {
    return lepus_std_throw_errno(ctx, errno);
  }

  lepus_std_dbuf_init(ctx, data_buf);
  lepus_std_dbuf_init(ctx, header_buf);

  buf = static_cast<char *>(lepus_malloc(ctx, URL_GET_BUF_SIZE));
  if (!buf) goto fail;

  /* get the HTTP status */
  if (http_get_header_line(f, buf, URL_GET_BUF_SIZE, NULL) < 0) goto bad_header;
  status = http_get_status(buf);
  if (!full_flag && !(status >= 200 && status <= 299)) {
    lepus_std_throw_errno(ctx, ENOENT);
    goto fail;
  }

  /* wait until there is an empty line */
  for (;;) {
    if (http_get_header_line(f, buf, URL_GET_BUF_SIZE, header_buf) < 0) {
    bad_header:
      lepus_std_throw_errno(ctx, EINVAL);
      goto fail;
    }
    if (!strcmp(buf, "\r\n")) break;
  }
  if (dbuf_error(header_buf)) goto fail;
  header_buf->size -= 2; /* remove the trailing CRLF */

  /* download the data */
  for (;;) {
    len = fread(buf, 1, URL_GET_BUF_SIZE, f);
    if (len == 0) break;
    dbuf_put(data_buf, (uint8_t *)buf, len);
  }
  lepus_free(ctx, buf);
  buf = NULL;
  pclose(f);
  f = NULL;

  if (dbuf_error(data_buf)) goto fail;
  if (binary_flag) {
    response = LEPUS_NewArrayBufferCopy(ctx, data_buf->buf, data_buf->size);
  } else {
    response = LEPUS_NewStringLen(ctx, (char *)data_buf->buf, data_buf->size);
  }
  dbuf_free(data_buf);
  data_buf = NULL;
  if (LEPUS_IsException(response)) goto fail;

  if (full_flag) {
    ret_obj = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(ret_obj)) goto fail;
    LEPUS_DefinePropertyValueStr(ctx, ret_obj, "response", response,
                                 LEPUS_PROP_C_W_E);
    LEPUS_DefinePropertyValueStr(
        ctx, ret_obj, "responseHeaders",
        LEPUS_NewStringLen(ctx, (char *)header_buf->buf, header_buf->size),
        LEPUS_PROP_C_W_E);
    LEPUS_DefinePropertyValueStr(ctx, ret_obj, "status",
                                 LEPUS_NewInt32(ctx, status), LEPUS_PROP_C_W_E);
  } else {
    ret_obj = response;
  }
  dbuf_free(header_buf);
  return ret_obj;
fail:
  if (f) pclose(f);
  lepus_free(ctx, buf);
  if (data_buf) dbuf_free(data_buf);
  if (header_buf) dbuf_free(header_buf);
  LEPUS_FreeValue(ctx, response);
  return LEPUS_EXCEPTION;
}
#endif

static LEPUSClassDef lepus_std_file_class = {
    "FILE",
    .finalizer = lepus_std_file_finalizer,
};

#endif

static const LEPUSCFunctionListEntry lepus_std_funcs[] = {

#if LYNX_SIMPLIFY
    LEPUS_CFUNC_DEF("exit", 1, lepus_std_exit),
    LEPUS_CFUNC_DEF("gc", 0, lepus_std_gc),
    LEPUS_CFUNC_DEF("evalScript", 1, lepus_evalScript),
    LEPUS_CFUNC_DEF("loadScript", 1, lepus_loadScript),
    LEPUS_CFUNC_DEF("getenv", 1, lepus_std_getenv),
    LEPUS_CFUNC_DEF("urlGet", 1, lepus_std_urlGet),

    /* FILE I/O */
    LEPUS_CFUNC_DEF("open", 2, lepus_std_open),
    LEPUS_CFUNC_DEF("tmpfile", 0, lepus_std_tmpfile),
    LEPUS_CFUNC_MAGIC_DEF("puts", 1, lepus_std_file_puts, 0),
    LEPUS_CFUNC_DEF("printf", 1, lepus_std_printf),
    LEPUS_CFUNC_DEF("sprintf", 1, lepus_std_sprintf),
    LEPUS_PROP_INT32_DEF("SEEK_SET", SEEK_SET, LEPUS_PROP_CONFIGURABLE),
    LEPUS_PROP_INT32_DEF("SEEK_CUR", SEEK_CUR, LEPUS_PROP_CONFIGURABLE),
    LEPUS_PROP_INT32_DEF("SEEK_END", SEEK_END, LEPUS_PROP_CONFIGURABLE),

/* setenv, ... */
#endif
};
#if LYNX_SIMPLIFY
static const LEPUSCFunctionListEntry lepus_std_error_funcs[] = {
    LEPUS_CFUNC_DEF("strerror", 1, lepus_std_error_strerror),
/* various errno values */
#define DEF(x) LEPUS_PROP_INT32_DEF(#x, x, LEPUS_PROP_CONFIGURABLE)
    DEF(EINVAL),
    DEF(EIO),
    DEF(EACCES),
    DEF(EEXIST),
    DEF(ENOSPC),
    DEF(ENOSYS),
    DEF(EBUSY),
    DEF(ENOENT),
    DEF(EPERM),
    DEF(EPIPE),
    DEF(EBADF),
#undef DEF
};

static const LEPUSCFunctionListEntry lepus_std_file_proto_funcs[] = {
    LEPUS_CFUNC_DEF("close", 0, lepus_std_file_close),
    LEPUS_CFUNC_MAGIC_DEF("puts", 1, lepus_std_file_puts, 1),
    LEPUS_CFUNC_DEF("printf", 1, lepus_std_file_printf),
    LEPUS_CFUNC_DEF("flush", 0, lepus_std_file_flush),
    LEPUS_CFUNC_DEF("tell", 0, lepus_std_file_tell),
    LEPUS_CFUNC_DEF("seek", 2, lepus_std_file_seek),
    LEPUS_CFUNC_DEF("eof", 0, lepus_std_file_eof),
    LEPUS_CFUNC_DEF("fileno", 0, lepus_std_file_fileno),
    LEPUS_CFUNC_MAGIC_DEF("read", 3, lepus_std_file_read_write, 0),
    LEPUS_CFUNC_MAGIC_DEF("write", 3, lepus_std_file_read_write, 1),
    LEPUS_CFUNC_DEF("getline", 0, lepus_std_file_getline),
    LEPUS_CFUNC_DEF("readAsString", 0, lepus_std_file_readAsString),
    LEPUS_CFUNC_DEF("getByte", 0, lepus_std_file_getByte),
    LEPUS_CFUNC_DEF("putByte", 1, lepus_std_file_putByte),
    /* setvbuf, ferror, clearerr, ...  */
};

#endif

static int lepus_std_init(LEPUSContext *ctx, LEPUSModuleDef *m) {
#if LYNX_SIMPLIFY
  LEPUSValue proto, obj;

  /* FILE class */
  /* the class ID is created once */
  LEPUS_NewClassID(&lepus_std_file_class_id);
  /* the class is created once per runtime */
  LEPUS_NewClass(LEPUS_GetRuntime(ctx), lepus_std_file_class_id,
                 &lepus_std_file_class);
  proto = LEPUS_NewObject(ctx);
  LEPUS_SetPropertyFunctionList(ctx, proto, lepus_std_file_proto_funcs,
                                countof(lepus_std_file_proto_funcs));
  LEPUS_SetClassProto(ctx, lepus_std_file_class_id, proto);

  LEPUS_SetModuleExportList(ctx, m, lepus_std_funcs, countof(lepus_std_funcs));
  LEPUS_SetModuleExport(ctx, m, "in", lepus_new_std_file(ctx, stdin, FALSE));
  LEPUS_SetModuleExport(ctx, m, "out", lepus_new_std_file(ctx, stdout, FALSE));
  LEPUS_SetModuleExport(ctx, m, "err", lepus_new_std_file(ctx, stderr, FALSE));

  obj = LEPUS_NewCFunction2(ctx, lepus_std_error_constructor, "Error", 1,
                            LEPUS_CFUNC_constructor, 0);
  LEPUS_SetPropertyFunctionList(ctx, obj, lepus_std_error_funcs,
                                countof(lepus_std_error_funcs));
  LEPUS_SetModuleExport(ctx, m, "Error", obj);

#endif
  /* global object */
  LEPUS_SetModuleExport(ctx, m, "global", LEPUS_GetGlobalObject(ctx));
  return 0;
}

LEPUSModuleDef *lepus_init_module_std(LEPUSContext *ctx,
                                      const char *module_name) {
  LEPUSModuleDef *m;
  m = LEPUS_NewCModule(ctx, module_name, lepus_std_init);
  if (!m) return NULL;
  LEPUS_AddModuleExportList(ctx, m, lepus_std_funcs, countof(lepus_std_funcs));
#if LYNX_SIMPLIFY
  LEPUS_AddModuleExport(ctx, m, "in");
  LEPUS_AddModuleExport(ctx, m, "out");
  LEPUS_AddModuleExport(ctx, m, "err");
  LEPUS_AddModuleExport(ctx, m, "Error");
#endif
  LEPUS_AddModuleExport(ctx, m, "global");
  return m;
}

/**********************************************************/
/* 'os' object */
#if LYNX_SIMPLIFY
static LEPUSValue lepus_os_return(LEPUSContext *ctx, ssize_t ret) {
  if (ret < 0) ret = -errno;
  return LEPUS_NewInt64(ctx, ret);
}

static LEPUSValue lepus_os_open(LEPUSContext *ctx, LEPUSValueConst this_val,
                                int argc, LEPUSValueConst *argv) {
  const char *filename;
  int flags, mode, ret;

  filename = LEPUS_ToCString(ctx, argv[0]);
  if (!filename) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt32(ctx, &flags, argv[1])) goto fail;
  if (argc >= 3 && !LEPUS_IsUndefined(argv[2])) {
    if (LEPUS_ToInt32(ctx, &mode, argv[2])) {
    fail:
      LEPUS_FreeCString(ctx, filename);
      return LEPUS_EXCEPTION;
    }
  } else {
    mode = 0666;
  }
#if defined(_WIN32)
  /* force binary mode by default */
  if (!(flags & O_TEXT)) flags |= O_BINARY;
#endif
  ret = open(filename, flags, mode);
  LEPUS_FreeCString(ctx, filename);
  return lepus_os_return(ctx, ret);
}

static LEPUSValue lepus_os_close(LEPUSContext *ctx, LEPUSValueConst this_val,
                                 int argc, LEPUSValueConst *argv) {
  int fd, ret;
  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  ret = close(fd);
  return lepus_os_return(ctx, ret);
}

static LEPUSValue lepus_os_seek(LEPUSContext *ctx, LEPUSValueConst this_val,
                                int argc, LEPUSValueConst *argv) {
  int fd, whence, ret;
  int64_t pos;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt64(ctx, &pos, argv[1])) return LEPUS_EXCEPTION;
  if (LEPUS_ToInt32(ctx, &whence, argv[2])) return LEPUS_EXCEPTION;
  ret = lseek(fd, pos, whence);
  return lepus_os_return(ctx, ret);
}

static LEPUSValue lepus_os_read_write(LEPUSContext *ctx,
                                      LEPUSValueConst this_val, int argc,
                                      LEPUSValueConst *argv, int magic) {
  int fd;
  uint64_t pos, len;
  size_t size;
  ssize_t ret;
  uint8_t *buf;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  if (LEPUS_ToIndex(ctx, &pos, argv[2])) return LEPUS_EXCEPTION;
  if (LEPUS_ToIndex(ctx, &len, argv[3])) return LEPUS_EXCEPTION;
  buf = LEPUS_GetArrayBuffer(ctx, &size, argv[1]);
  if (!buf) return LEPUS_EXCEPTION;
  if (pos + len > size)
    return LEPUS_ThrowRangeError(ctx, "read/write array buffer overflow");
  if (magic)
    ret = write(fd, buf + pos, len);
  else
    ret = read(fd, buf + pos, len);
  return lepus_os_return(ctx, ret);
}

static LEPUSValue lepus_os_isatty(LEPUSContext *ctx, LEPUSValueConst this_val,
                                  int argc, LEPUSValueConst *argv) {
  int fd;
  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  return LEPUS_NewBool(ctx, isatty(fd) == 1);
}

#if defined(_WIN32)
static LEPUSValue lepus_os_ttyGetWinSize(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv) {
  int fd;
  HANDLE handle;
  CONSOLE_SCREEN_BUFFER_INFO info;
  LEPUSValue obj;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  handle = (HANDLE)_get_osfhandle(fd);

  if (!GetConsoleScreenBufferInfo(handle, &info)) return LEPUS_NULL;
  obj = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(obj)) return obj;
  LEPUS_DefinePropertyValueUint32(
      ctx, obj, 0, LEPUS_NewInt32(ctx, info.dwSize.X), LEPUS_PROP_C_W_E);
  LEPUS_DefinePropertyValueUint32(
      ctx, obj, 1, LEPUS_NewInt32(ctx, info.dwSize.Y), LEPUS_PROP_C_W_E);
  return obj;
}

static LEPUSValue lepus_os_ttySetRaw(LEPUSContext *ctx,
                                     LEPUSValueConst this_val, int argc,
                                     LEPUSValueConst *argv) {
  int fd;
  HANDLE handle;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  handle = (HANDLE)_get_osfhandle(fd);

  SetConsoleMode(handle, ENABLE_WINDOW_INPUT);
  return LEPUS_UNDEFINED;
}
#else
static LEPUSValue lepus_os_ttyGetWinSize(LEPUSContext *ctx,
                                         LEPUSValueConst this_val, int argc,
                                         LEPUSValueConst *argv) {
  int fd;
  struct winsize ws;
  LEPUSValue obj;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  if (ioctl(fd, TIOCGWINSZ, &ws) == 0 && ws.ws_col >= 4 && ws.ws_row >= 4) {
    obj = LEPUS_NewArray(ctx);
    if (LEPUS_IsException(obj)) return obj;
    LEPUS_DefinePropertyValueUint32(ctx, obj, 0, LEPUS_NewInt32(ctx, ws.ws_col),
                                    LEPUS_PROP_C_W_E);
    LEPUS_DefinePropertyValueUint32(ctx, obj, 1, LEPUS_NewInt32(ctx, ws.ws_row),
                                    LEPUS_PROP_C_W_E);
    return obj;
  } else {
    return LEPUS_NULL;
  }
}

static struct termios oldtty;

static void term_exit(void) { tcsetattr(0, TCSANOW, &oldtty); }

/* XXX: should add a way to go back to normal mode */
static LEPUSValue lepus_os_ttySetRaw(LEPUSContext *ctx,
                                     LEPUSValueConst this_val, int argc,
                                     LEPUSValueConst *argv) {
  struct termios tty;
  int fd;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;

  memset(&tty, 0, sizeof(tty));
  tcgetattr(fd, &tty);
  oldtty = tty;

  tty.c_iflag &=
      ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
  tty.c_oflag |= OPOST;
  tty.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN);
  tty.c_cflag &= ~(CSIZE | PARENB);
  tty.c_cflag |= CS8;
  tty.c_cc[VMIN] = 1;
  tty.c_cc[VTIME] = 0;

  tcsetattr(fd, TCSANOW, &tty);

  atexit(term_exit);
  return LEPUS_UNDEFINED;
}

#endif /* !_WIN32 */

static LEPUSValue lepus_os_remove(LEPUSContext *ctx, LEPUSValueConst this_val,
                                  int argc, LEPUSValueConst *argv) {
  const char *filename;
  int ret;

  filename = LEPUS_ToCString(ctx, argv[0]);
  if (!filename) return LEPUS_EXCEPTION;
  ret = remove(filename);
  LEPUS_FreeCString(ctx, filename);
  return lepus_os_return(ctx, ret);
}

static LEPUSValue lepus_os_rename(LEPUSContext *ctx, LEPUSValueConst this_val,
                                  int argc, LEPUSValueConst *argv) {
  const char *oldpath, *newpath;
  int ret;

  oldpath = LEPUS_ToCString(ctx, argv[0]);
  if (!oldpath) return LEPUS_EXCEPTION;
  newpath = LEPUS_ToCString(ctx, argv[1]);
  if (!newpath) {
    LEPUS_FreeCString(ctx, oldpath);
    return LEPUS_EXCEPTION;
  }
  ret = rename(oldpath, newpath);
  LEPUS_FreeCString(ctx, oldpath);
  LEPUS_FreeCString(ctx, newpath);
  return lepus_os_return(ctx, ret);
}

static LEPUSOSRWHandler *find_rh(int fd) {
  LEPUSOSRWHandler *rh;
  struct list_head *el;
  list_for_each(el, &os_rw_handlers) {
    rh = list_entry(el, LEPUSOSRWHandler, link);
    if (rh->fd == fd) return rh;
  }
  return NULL;
}

static void free_rw_handler(LEPUSRuntime *rt, LEPUSOSRWHandler *rh) {
  int i;
  list_del(&rh->link);
  for (i = 0; i < 2; i++) {
    LEPUS_FreeValueRT(rt, rh->rw_func[i]);
  }
  lepus_free_rt(rt, rh);
}

static LEPUSValue lepus_os_setReadHandler(LEPUSContext *ctx,
                                          LEPUSValueConst this_val, int argc,
                                          LEPUSValueConst *argv, int magic) {
  LEPUSOSRWHandler *rh;
  int fd;
  LEPUSValueConst func;

  if (LEPUS_ToInt32(ctx, &fd, argv[0])) return LEPUS_EXCEPTION;
  func = argv[1];
  if (LEPUS_IsNull(func)) {
    rh = find_rh(fd);
    if (rh) {
      LEPUS_FreeValue(ctx, rh->rw_func[magic]);
      rh->rw_func[magic] = LEPUS_NULL;
      if (LEPUS_IsNull(rh->rw_func[0]) && LEPUS_IsNull(rh->rw_func[1])) {
        /* remove the entry */
        free_rw_handler(LEPUS_GetRuntime(ctx), rh);
      }
    }
  } else {
    if (!LEPUS_IsFunction(ctx, func))
      return LEPUS_ThrowTypeError(ctx, "not a function");
    rh = find_rh(fd);
    if (!rh) {
      rh = static_cast<LEPUSOSRWHandler *>(lepus_mallocz(ctx, sizeof(*rh)));
      if (!rh) return LEPUS_EXCEPTION;
      rh->fd = fd;
      rh->rw_func[0] = LEPUS_NULL;
      rh->rw_func[1] = LEPUS_NULL;
      list_add_tail(&rh->link, &os_rw_handlers);
    }
    LEPUS_FreeValue(ctx, rh->rw_func[magic]);
    rh->rw_func[magic] = LEPUS_DupValue(ctx, func);
  }
  return LEPUS_UNDEFINED;
}

static LEPUSOSSignalHandler *find_sh(int sig_num) {
  LEPUSOSSignalHandler *sh;
  struct list_head *el;
  list_for_each(el, &os_signal_handlers) {
    sh = list_entry(el, LEPUSOSSignalHandler, link);
    if (sh->sig_num == sig_num) return sh;
  }
  return NULL;
}

static void free_sh(LEPUSRuntime *rt, LEPUSOSSignalHandler *sh) {
  list_del(&sh->link);
  LEPUS_FreeValueRT(rt, sh->func);
  lepus_free_rt(rt, sh);
}

static void os_signal_handler(int sig_num) {
  os_pending_signals |= ((uint64_t)1 << sig_num);
}

#if defined(_WIN32)
typedef void (*sighandler_t)(int sig_num);
#endif

static LEPUSValue lepus_os_signal(LEPUSContext *ctx, LEPUSValueConst this_val,
                                  int argc, LEPUSValueConst *argv) {
  LEPUSOSSignalHandler *sh;
  uint32_t sig_num;
  LEPUSValueConst func;
  sighandler_t handler;

  if (LEPUS_ToUint32(ctx, &sig_num, argv[0])) return LEPUS_EXCEPTION;
  if (sig_num >= 64) return LEPUS_ThrowRangeError(ctx, "invalid signal number");
  func = argv[1];
  /* func = null: SIG_DFL, func = undefined, SIG_IGN */
  if (LEPUS_IsNull(func) || LEPUS_IsUndefined(func)) {
    sh = find_sh(sig_num);
    if (sh) {
      free_sh(LEPUS_GetRuntime(ctx), sh);
    }
    if (LEPUS_IsNull(func))
      handler = SIG_DFL;
    else
      handler = SIG_IGN;
    signal(sig_num, handler);
  } else {
    if (!LEPUS_IsFunction(ctx, func))
      return LEPUS_ThrowTypeError(ctx, "not a function");
    sh = find_sh(sig_num);
    if (!sh) {
      sh = static_cast<LEPUSOSSignalHandler *>(lepus_mallocz(ctx, sizeof(*sh)));
      if (!sh) return LEPUS_EXCEPTION;
      sh->sig_num = sig_num;
      list_add_tail(&sh->link, &os_signal_handlers);
    }
    LEPUS_FreeValue(ctx, sh->func);
    sh->func = LEPUS_DupValue(ctx, func);
    signal(sig_num, os_signal_handler);
  }
  return LEPUS_UNDEFINED;
}

#endif

#if defined(__linux__) || defined(__APPLE__)
static int64_t get_time_ms(void) {
  struct timespec ts;
  if (__builtin_available(iOS 10.0, *)) {
    clock_gettime(CLOCK_MONOTONIC, &ts);
  } else {
    // Fallback on earlier versions
  }
  return (uint64_t)ts.tv_sec * 1000 + (ts.tv_nsec / 1000000);
}
#else
/* more portable, but does not work if the date is updated */
static int64_t get_time_ms(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (int64_t)tv.tv_sec * 1000 + (tv.tv_usec / 1000);
}
#endif

static void unlink_timer(LEPUSRuntime *rt, LEPUSOSTimer *th) {
  if (th->link.prev) {
    list_del(&th->link);
    th->link.prev = th->link.next = NULL;
  }
}

static void free_timer(LEPUSRuntime *rt, LEPUSOSTimer *th) {
  LEPUS_FreeValueRT(rt, th->func);
  lepus_free_rt(rt, th);
}

static LEPUSClassID lepus_os_timer_class_id;

static void lepus_os_timer_finalizer(LEPUSRuntime *rt, LEPUSValue val) {
  LEPUSOSTimer *th = static_cast<LEPUSOSTimer *>(
      LEPUS_GetOpaque(val, lepus_os_timer_class_id));
  if (th) {
    th->has_object = FALSE;
    if (!th->link.prev) free_timer(rt, th);
  }
}

static void lepus_os_timer_mark(LEPUSRuntime *rt, LEPUSValueConst val,
                                LEPUS_MarkFunc *mark_func) {
  LEPUSOSTimer *th = static_cast<LEPUSOSTimer *>(
      LEPUS_GetOpaque(val, lepus_os_timer_class_id));
  if (th) {
    LEPUS_MarkValue(rt, th->func, mark_func);
  }
}

static LEPUSValue lepus_os_setTimeout(LEPUSContext *ctx,
                                      LEPUSValueConst this_val, int argc,
                                      LEPUSValueConst *argv) {
  int64_t delay;
  LEPUSValueConst func;
  LEPUSOSTimer *th;
  LEPUSValue obj;

  func = argv[0];
  if (!LEPUS_IsFunction(ctx, func))
    return LEPUS_ThrowTypeError(ctx, "not a function");
  if (LEPUS_ToInt64(ctx, &delay, argv[1])) return LEPUS_EXCEPTION;
  obj = LEPUS_NewObjectClass(ctx, lepus_os_timer_class_id);
  if (LEPUS_IsException(obj)) return obj;
  th = static_cast<LEPUSOSTimer *>(lepus_mallocz(ctx, sizeof(*th)));
  if (!th) {
    LEPUS_FreeValue(ctx, obj);
    return LEPUS_EXCEPTION;
  }
  th->has_object = TRUE;
  th->timeout = get_time_ms() + delay;
  th->func = LEPUS_DupValue(ctx, func);
  list_add_tail(&th->link, &os_timers);
  LEPUS_SetOpaque(obj, th);
  return obj;
}

static LEPUSValue lepus_os_clearTimeout(LEPUSContext *ctx,
                                        LEPUSValueConst this_val, int argc,
                                        LEPUSValueConst *argv) {
  LEPUSOSTimer *th = static_cast<LEPUSOSTimer *>(
      LEPUS_GetOpaque2(ctx, argv[0], lepus_os_timer_class_id));
  if (!th) return LEPUS_EXCEPTION;
  unlink_timer(LEPUS_GetRuntime(ctx), th);
  return LEPUS_UNDEFINED;
}

static LEPUSClassDef lepus_os_timer_class = {
    "OSTimer",
    .finalizer = lepus_os_timer_finalizer,
    .gc_mark = lepus_os_timer_mark,
};

static void call_handler(LEPUSContext *ctx, LEPUSValueConst func) {
  LEPUSValue ret, func1;
  /* 'func' might be destroyed when calling itself (if it frees the
     handler), so must take extra care */
  func1 = LEPUS_DupValue(ctx, func);
  ret = LEPUS_Call(ctx, func1, LEPUS_UNDEFINED, 0, NULL);
  LEPUS_FreeValue(ctx, func1);
  if (LEPUS_IsException(ret)) lepus_std_dump_error(ctx);
  LEPUS_FreeValue(ctx, ret);
}

#if defined(_WIN32)

static int lepus_os_poll(LEPUSContext *ctx) {
  int min_delay;
#if LYNX_SIMPLIFY
  int console_fd;
  LEPUSOSRWHandler *rh;
#endif
  int64_t cur_time, delay;
  struct list_head *el;

#if LYNX_SIMPLIFY
  console_fd = -1;
  list_for_each(el, &os_rw_handlers) {
    rh = list_entry(el, LEPUSOSRWHandler, link);
    if (rh->fd == 0 && !LEPUS_IsNull(rh->rw_func[0])) {
      console_fd = rh->fd;
      break;
    }
  }

  if (console_fd >= 0) {
    DWORD ti, ret;
    HANDLE handle;
    if (min_delay == -1)
      ti = INFINITE;
    else
      ti = min_delay;
    handle = (HANDLE)_get_osfhandle(console_fd);
    ret = WaitForSingleObject(handle, ti);
    if (ret == WAIT_OBJECT_0) {
      list_for_each(el, &os_rw_handlers) {
        rh = list_entry(el, LEPUSOSRWHandler, link);
        if (rh->fd == console_fd && !LEPUS_IsNull(rh->rw_func[0])) {
          call_handler(ctx, rh->rw_func[0]);
          /* must stop because the list may have been modified */
          break;
        }
      }
    }
  } else {
    Sleep(min_delay);
  }
#endif

  if (list_empty(&os_timers)) return -1; /* no more events */

  /* XXX: only timers and basic console input are supported */
  if (!list_empty(&os_timers)) {
    cur_time = get_time_ms();
    min_delay = 10000;
    list_for_each(el, &os_timers) {
      LEPUSOSTimer *th = list_entry(el, LEPUSOSTimer, link);
      delay = th->timeout - cur_time;
      if (delay <= 0) {
        LEPUSValue func;
        /* the timer expired */
        func = th->func;
        th->func = LEPUS_UNDEFINED;
        unlink_timer(LEPUS_GetRuntime(ctx), th);
        if (!th->has_object) free_timer(LEPUS_GetRuntime(ctx), th);
        call_handler(ctx, func);
        LEPUS_FreeValue(ctx, func);
        return 0;
      } else if (delay < min_delay) {
        min_delay = delay;
      }
    }
  } else {
    min_delay = -1;
  }
  return 0;
}
#else
static int lepus_os_poll(LEPUSContext *ctx) {
  int min_delay;
  int64_t cur_time, delay;
  struct list_head *el;
  struct timeval tv, *tvp;
#if LYNX_SIMPLIFY
  int ret, fd_max;
  LEPUSOSRWHandler *rh;
  fd_set rfds, wfds;

  if (unlikely(os_pending_signals != 0)) {
    LEPUSOSSignalHandler *sh;
    uint64_t mask;

    list_for_each(el, &os_signal_handlers) {
      sh = list_entry(el, LEPUSOSSignalHandler, link);
      mask = (uint64_t)1 << sh->sig_num;
      if (os_pending_signals & mask) {
        os_pending_signals &= ~mask;
        call_handler(ctx, sh->func);
        return 0;
      }
    }
  }
#endif

  if (/*list_empty(&os_rw_handlers) && */ list_empty(&os_timers))
    return -1; /* no more events */

  if (!list_empty(&os_timers)) {
    cur_time = get_time_ms();
    min_delay = 10000;
    list_for_each(el, &os_timers) {
      LEPUSOSTimer *th = list_entry(el, LEPUSOSTimer, link);
      delay = th->timeout - cur_time;
      if (delay <= 0) {
        LEPUSValue func;
        /* the timer expired */
        func = th->func;
        th->func = LEPUS_UNDEFINED;
        unlink_timer(LEPUS_GetRuntime(ctx), th);
        if (!th->has_object) free_timer(LEPUS_GetRuntime(ctx), th);
        call_handler(ctx, func);
        LEPUS_FreeValue(ctx, func);
        return 0;
      } else if (delay < min_delay) {
        min_delay = delay;
      }
    }
    tv.tv_sec = min_delay / 1000;
    tv.tv_usec = (min_delay % 1000) * 1000;
    tvp = &tv;
  } else {
    tvp = NULL;
  }

#if LYNX_SIMPLIFY
  FD_ZERO(&rfds);
  FD_ZERO(&wfds);
  fd_max = -1;
  list_for_each(el, &os_rw_handlers) {
    rh = list_entry(el, LEPUSOSRWHandler, link);
    fd_max = max_int(fd_max, rh->fd);
    if (!LEPUS_IsNull(rh->rw_func[0])) FD_SET(rh->fd, &rfds);
    if (!LEPUS_IsNull(rh->rw_func[1])) FD_SET(rh->fd, &wfds);
  }

  ret = select(fd_max + 1, &rfds, &wfds, NULL, tvp);
  if (ret > 0) {
    list_for_each(el, &os_rw_handlers) {
      rh = list_entry(el, LEPUSOSRWHandler, link);
      if (!LEPUS_IsNull(rh->rw_func[0]) && FD_ISSET(rh->fd, &rfds)) {
        call_handler(ctx, rh->rw_func[0]);
        /* must stop because the list may have been modified */
        break;
      }
      if (!LEPUS_IsNull(rh->rw_func[1])) {
        FD_SET(rh->fd, &wfds);
        call_handler(ctx, rh->rw_func[1]);
        /* must stop because the list may have been modified */
        break;
      }
    }
  }
#endif
  return 0;
}
#endif /* !_WIN32 */

#if defined(_WIN32)
#define OS_PLATFORM "win32"
#elif defined(__APPLE__)
#define OS_PLATFORM "darwin"
#elif defined(EMSCRIPTEN)
#define OS_PLATFORM "lepus"
#else
#define OS_PLATFORM "linux"
#endif

#define OS_FLAG(x) LEPUS_PROP_INT32_DEF(#x, x, LEPUS_PROP_CONFIGURABLE)

static const LEPUSCFunctionListEntry lepus_os_funcs[] = {
#if LYNX_SIMPLIFY
    LEPUS_CFUNC_DEF("open", 2, lepus_os_open),
    OS_FLAG(O_RDONLY),
    OS_FLAG(O_WRONLY),
    OS_FLAG(O_RDWR),
    OS_FLAG(O_APPEND),
    OS_FLAG(O_CREAT),
    OS_FLAG(O_EXCL),
    OS_FLAG(O_TRUNC),
#if defined(_WIN32)
    OS_FLAG(O_BINARY),
    OS_FLAG(O_TEXT),
#endif
    LEPUS_CFUNC_DEF("close", 1, lepus_os_close),
    LEPUS_CFUNC_DEF("seek", 3, lepus_os_seek),
    LEPUS_CFUNC_MAGIC_DEF("read", 4, lepus_os_read_write, 0),
    LEPUS_CFUNC_MAGIC_DEF("write", 4, lepus_os_read_write, 1),
    LEPUS_CFUNC_DEF("isatty", 1, lepus_os_isatty),
    LEPUS_CFUNC_DEF("ttyGetWinSize", 1, lepus_os_ttyGetWinSize),
    LEPUS_CFUNC_DEF("ttySetRaw", 1, lepus_os_ttySetRaw),
    LEPUS_CFUNC_DEF("remove", 1, lepus_os_remove),
    LEPUS_CFUNC_DEF("rename", 2, lepus_os_rename),
    LEPUS_CFUNC_MAGIC_DEF("setReadHandler", 2, lepus_os_setReadHandler, 0),
    LEPUS_CFUNC_MAGIC_DEF("setWriteHandler", 2, lepus_os_setReadHandler, 1),
    LEPUS_CFUNC_DEF("signal", 2, lepus_os_signal),
    OS_FLAG(SIGINT),
    OS_FLAG(SIGABRT),
    OS_FLAG(SIGFPE),
    OS_FLAG(SIGILL),
    OS_FLAG(SIGSEGV),
    OS_FLAG(SIGTERM),
#endif
    LEPUS_CFUNC_DEF("setTimeout", 2, lepus_os_setTimeout),
    LEPUS_CFUNC_DEF("clearTimeout", 1, lepus_os_clearTimeout),

#if LYNX_SIMPLIFY
    LEPUS_PROP_STRING_DEF("platform", OS_PLATFORM, 0),
#endif
    /* stat, readlink, opendir, closedir, ... */
};

static int lepus_os_init(LEPUSContext *ctx, LEPUSModuleDef *m) {
  os_poll_func = lepus_os_poll;

  /* OSTimer class */
  LEPUS_NewClassID(&lepus_os_timer_class_id);
  LEPUS_NewClass(LEPUS_GetRuntime(ctx), lepus_os_timer_class_id,
                 &lepus_os_timer_class);

  return LEPUS_SetModuleExportList(ctx, m, lepus_os_funcs,
                                   countof(lepus_os_funcs));
}

LEPUSModuleDef *lepus_init_module_os(LEPUSContext *ctx,
                                     const char *module_name) {
  LEPUSModuleDef *m;
  m = LEPUS_NewCModule(ctx, module_name, lepus_os_init);
  if (!m) return NULL;
  LEPUS_AddModuleExportList(ctx, m, lepus_os_funcs, countof(lepus_os_funcs));
  return m;
}

/**********************************************************/

static LEPUSValue lepus_print(LEPUSContext *ctx, LEPUSValueConst this_val,
                              int argc, LEPUSValueConst *argv) {
  int i;
  const char *str;

  for (i = 0; i < argc; i++) {
    if (i != 0) putchar(' ');
    str = LEPUS_ToCString(ctx, argv[i]);
    if (!str) return LEPUS_EXCEPTION;
    fputs(str, stdout);
    LEPUS_FreeCString(ctx, str);
  }
  putchar('\n');
  return LEPUS_UNDEFINED;
}

void lepus_std_add_helpers(LEPUSContext *ctx, int argc, char **argv) {
#if LYNX_SIMPLIFY
  LEPUSValue global_obj;
  LEPUSValue args;
  LEPUSValue console;
  int i;

  /* XXX: should these global definitions be enumerable? */
  global_obj = LEPUS_GetGlobalObject(ctx);

  console = LEPUS_NewObject(ctx);
  LEPUS_SetPropertyStr(ctx, console, "log",
                       LEPUS_NewCFunction(ctx, lepus_print, "log", 1));
  LEPUS_SetPropertyStr(ctx, global_obj, "console", console);

  /* same methods as the mozilla LEPUS shell */
  args = LEPUS_NewArray(ctx);
  for (i = 0; i < argc; i++) {
    LEPUS_SetPropertyUint32(ctx, args, i, LEPUS_NewString(ctx, argv[i]));
  }
  LEPUS_SetPropertyStr(ctx, global_obj, "scriptArgs", args);

  LEPUS_SetPropertyStr(ctx, global_obj, "print",
                       LEPUS_NewCFunction(ctx, lepus_print, "print", 1));
  LEPUS_SetPropertyStr(
      ctx, global_obj, "__loadScript",
      LEPUS_NewCFunction(ctx, lepus_loadScript, "__loadScript", 1));
  LEPUS_FreeValue(ctx, global_obj);

  /* XXX: not multi-context */
  init_list_head(&os_rw_handlers);
  init_list_head(&os_signal_handlers);

#endif
  init_list_head(&os_timers);
  os_pending_signals = 0;
}

void lepus_std_free_handlers(LEPUSRuntime *rt) {
  struct list_head *el, *el1;
#if LYNX_SIMPLIFY
  list_for_each_safe(el, el1, &os_rw_handlers) {
    LEPUSOSRWHandler *rh = list_entry(el, LEPUSOSRWHandler, link);
    free_rw_handler(rt, rh);
  }

  list_for_each_safe(el, el1, &os_signal_handlers) {
    LEPUSOSSignalHandler *sh = list_entry(el, LEPUSOSSignalHandler, link);
    free_sh(rt, sh);
  }
#endif

  list_for_each_safe(el, el1, &os_timers) {
    LEPUSOSTimer *th = list_entry(el, LEPUSOSTimer, link);
    unlink_timer(rt, th);
    if (!th->has_object) free_timer(rt, th);
  }
}

void lepus_std_dump_error(LEPUSContext *ctx) {
  LEPUSValue exception_val, val;
  const char *stack;
  BOOL is_error;

  exception_val = LEPUS_GetException(ctx);
  is_error = LEPUS_IsError(ctx, exception_val);
  if (!is_error) printf("Throw: ");
  lepus_print(ctx, LEPUS_NULL, 1, (LEPUSValueConst *)&exception_val);
  if (is_error) {
    val = LEPUS_GetPropertyStr(ctx, exception_val, "stack");
    if (!LEPUS_IsUndefined(val)) {
      stack = LEPUS_ToCString(ctx, val);
      printf("%s\n", stack);
      LEPUS_FreeCString(ctx, stack);
    }
    LEPUS_FreeValue(ctx, val);
  }
  LEPUS_FreeValue(ctx, exception_val);
}

/* main loop which calls the user LEPUS callbacks */
void lepus_std_loop(LEPUSContext *ctx) {
  LEPUSContext *ctx1;
  int err;

  for (;;) {
    /* execute the pending jobs */
    for (;;) {
      err = LEPUS_ExecutePendingJob(LEPUS_GetRuntime(ctx), &ctx1);
      if (err <= 0) {
        if (err < 0) {
          lepus_std_dump_error(ctx1);
        }
        break;
      }
    }

    if (!os_poll_func || os_poll_func(ctx)) break;
  }
}
#if LYNX_SIMPLIFY
void lepus_std_eval_binary(LEPUSContext *ctx, const uint8_t *buf,
                           size_t buf_len, int flags) {
  LEPUSValue val;
  val = LEPUS_EvalBinary(ctx, buf, buf_len, flags);
  if (LEPUS_IsException(val)) {
    lepus_std_dump_error(ctx);
    exit(1);
  }
  LEPUS_FreeValue(ctx, val);
}
#endif
