// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_UTILS_H_
#define CANVAS_UTIL_UTILS_H_

#include "jsbridge/bindings/canvas/napi_canvas_element.h"

namespace lynx {
namespace canvas {

namespace Base64 {
inline size_t dec_size(size_t src_size) { return (src_size + 3) / 4 * 3; }
int decode(const char *str, uint32_t len, uint8_t *ret, uint32_t dst_size);
void encode(const uint8_t *bytes, uint32_t len, char *chars);

inline uint32_t encode_buflen(uint32_t input_len) {
  return (input_len + 2) / 3 << 2;
}
};  // namespace Base64

namespace string_util {
// Get the length of the longest valid utf-16 substring, when it is possible
// that the caller passes a truncated or messed-up string and passing it
// directly to codecvt may crash.
// Following https://unicode.org/faq/utf_bom.html#utf16-4
uint32_t GetLongestValidSubStringLength(const std::u16string &str);
}  // namespace string_util

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_UTILS_H_
