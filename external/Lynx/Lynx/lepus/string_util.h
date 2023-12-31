// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_STRING_UTIL_H_
#define LYNX_LEPUS_STRING_UTIL_H_

#include <codecvt>
#include <locale>
#include <sstream>
#include <string>

#include "base/string/string_utils.h"

namespace lynx {
namespace lepus {
template <typename T>
inline std::string to_string(const T &n) {
  std::ostringstream stm;
  stm << n;
  return stm.str();
}

inline bool EndsWith(const std::string &s, const std::string &ending) {
  if (s.length() >= ending.length()) {
    return (0 ==
            s.compare(s.length() - ending.length(), ending.length(), ending));
  } else {
    return false;
  }
}

inline bool BeginsWith(const std::string &s, const std::string &begin) {
  if (s.length() >= begin.length()) {
    return (0 == s.compare(0, begin.length(), begin));
  } else {
    return false;
  }
}

// Refer from
// https://chromium.googlesource.com/v8/v8/+/master/src/inspector/v8-string-conversions.cc
using UChar = uint16_t;
inline bool IsASCII(UChar c) { return !(c & ~0x7F); }

inline size_t InlineUTF8SequenceLengthNonASCII(char b0) {
  if ((b0 & 0xC0) != 0xC0) return 0;
  if ((b0 & 0xE0) == 0xC0) return 2;
  if ((b0 & 0xF0) == 0xE0) return 3;
  if ((b0 & 0xF8) == 0xF0) return 4;
  return 0;
}

inline size_t InlineUTF8SequenceLength(char b0) {
  return IsASCII(b0) ? 1 : InlineUTF8SequenceLengthNonASCII(b0);
}

inline size_t UTF8IndexToCIndex(const char *utf8, size_t c_length,
                                size_t utf8_index) {
  size_t cur_utf8_index = 0;
  size_t cur_index = 0;
  while (cur_utf8_index != utf8_index && cur_index < c_length) {
    cur_index += InlineUTF8SequenceLength(utf8[cur_index]);
    cur_utf8_index++;
  }
  return cur_index;
}

inline size_t Utf8IndexToCIndexForUtf16(const char *utf8, size_t c_length,
                                        size_t utf16_index) {
  size_t cur_utf16_index = 0, cur_c_index = 0, cur_char_size = 0;

  while (cur_utf16_index < utf16_index && cur_c_index < c_length) {
    cur_char_size = InlineUTF8SequenceLength(utf8[cur_c_index]);
    cur_c_index += cur_char_size;
    // if cur_char_size == 4, the char's length is 2 in utf16.
    cur_utf16_index += (cur_char_size == 4 ? 2 : 1);
  }

  if (cur_utf16_index > utf16_index) {
    return cur_c_index - cur_char_size;
  }
  return cur_c_index;
}

inline size_t CIndexToUTF8Index(const char *utf8, size_t c_length,
                                size_t c_index) {
  size_t cur_c_index = 0;
  size_t cur_utf8_index = 0;
  while (cur_c_index < c_index && cur_c_index < c_length) {
    cur_c_index += InlineUTF8SequenceLength(utf8[cur_c_index]);
    cur_utf8_index++;
  }
  return cur_utf8_index;
}

inline size_t SizeOfUtf8(const char *utf8, size_t c_length) {
  size_t size = 0;
  size_t cur_index = 0;
  while (cur_index < c_length) {
    cur_index += InlineUTF8SequenceLength(utf8[cur_index]);
    size++;
  }
  return size;
}

inline size_t SizeOfUtf16(const std::string &src_u8) {
  std::u16string u16_conv;
  lynx::base::ConvertUtf8StringToUtf16String(src_u8, u16_conv);
  return u16_conv.size();
}
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_STRING_UTIL_H_
