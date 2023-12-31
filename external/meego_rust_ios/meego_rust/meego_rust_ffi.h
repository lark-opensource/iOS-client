#ifndef MEEGO_RUST_FFI_H
#define MEEGO_RUST_FFI_H

#pragma once

/*  Generated code. DO NOT EDIT.
 *  source: meego_rust.yaml
 */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct RustBuffer {
  int32_t capacity;
  int32_t len;
  uint8_t *_Nullable data;
} RustBuffer;

typedef struct ForeignBytes
{
  int32_t len;
  const uint8_t *_Nullable data;
} ForeignBytes;

typedef struct RustCallStatus {
  int8_t code;
  struct RustBuffer error_buf;
} RustCallStatus;

struct RustBuffer uniffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus *_Nonnull out_status);
void uniffi_rustbuffer_free(RustBuffer buf, RustCallStatus *_Nonnull out_status);



void molten_ffi_meego_rust_call0(int64_t method, struct RustCallStatus *_Nonnull call_status);
void molten_ffi_meego_rust_call1(int64_t method, struct RustBuffer params, struct RustCallStatus *_Nonnull call_status);
struct RustBuffer molten_ffi_meego_rust_call2(int64_t method, struct RustCallStatus *_Nonnull call_status);
struct RustBuffer molten_ffi_meego_rust_call3(int64_t method, struct RustBuffer params, struct RustCallStatus *_Nonnull call_status);



#endif