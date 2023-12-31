// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus/lepus_string.h"

#include <cstring>
#include <iostream>

#include "lepus/common.h"
#include "lepus/string_util.h"
namespace lynx {
namespace lepus {

StringImpl::StringImpl(const char* str)
    : StringImpl(str, str == nullptr ? 0 : strlen(str)) {}

StringImpl::StringImpl(const char* str, std::size_t len) {
  length_ = len;
  str_.resize(len);
  if (str == nullptr || len == 0) {
    utf16_length_ = 0;
    return;
  }
  memcpy(&str_[0], str, len);
  hash_ = std::hash<std::string>()(str_);
  utf16_length_ = 0;
}

StringImpl::StringImpl(std::string str) {
  str_ = std::move(str);
  length_ = str_.size();
  hash_ = std::hash<std::string>()(str_);
  utf16_length_ = 0;
}
size_t StringImpl::size() { return SizeOfUtf8(str_.c_str(), str_.length()); }

size_t StringImpl::size_utf16() {
  if ((utf16_length_ & 0x1) == 0) {
    size_t length = SizeOfUtf16(str_);
    utf16_length_ = (length << 1) | 0x1;
    return length;
  }
  return utf16_length_ >> 1;
}

bool StringConvertHelper::IsMinusZero(double value) {
  return BitCast<int64_t>(value) == BitCast<int64_t>(-0.0);
}

}  // namespace lepus
}  // namespace lynx
