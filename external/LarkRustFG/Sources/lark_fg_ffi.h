#ifndef LARK_FG_FFI_H
#define LARK_FG_FFI_H

#pragma once

/*  Generated code. DO NOT EDIT.
 *  source: lark-fg.yaml
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



struct RustBuffer molten_ffi_lark_fg_get_immutable_feature_gating_d544(struct RustBuffer params, struct RustCallStatus *_Nonnull call_status);




#endif