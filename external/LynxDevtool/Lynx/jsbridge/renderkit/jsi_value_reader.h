// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_JSI_VALUE_READER_H_
#define LYNX_JSBRIDGE_RENDERKIT_JSI_VALUE_READER_H_

#include <string>
#include <unordered_map>
#include <utility>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

template <class T>
inline T ReadValue(Runtime& rt, const lynx::piper::Value& value);

template <>
inline int64_t ReadValue(Runtime& rt, const lynx::piper::Value& value) {
  if (value.isString()) {
    auto string_value = value.getString(rt).utf8(rt);
    int64_t result = 0;
    errno = 0;
    char* end_ptr = nullptr;
    result = std::strtoll(string_value.c_str(), &end_ptr, 10);
    if (end_ptr == string_value.c_str() || errno == ERANGE) {
      errno = 0;
      return 0;
    }
    return result;
  } else if (value.isNumber()) {
    return static_cast<int64_t>(value.getNumber());
  }
  return 0;
}

template <>
inline int ReadValue(Runtime& rt, const lynx::piper::Value& value) {
  return static_cast<int>(ReadValue<int64_t>(rt, value));
}

template <>
inline std::string ReadValue(Runtime& rt, const lynx::piper::Value& value) {
  if (!value.isString()) {
    return "";
  }
  return value.getString(rt).utf8(rt);
}

template <class T>
inline T ReadObjectValue(Runtime& rt, const lynx::piper::Object& obj,
                         const std::string& prop_name) {
  auto value_opt = obj.getProperty(rt, prop_name.data());
  piper::Value value = value_opt ? std::move(*value_opt) : piper::Value();
  return ReadValue<T>(rt, value);
}

template <class T>
inline T ReadObject(Runtime& rt, const lynx::piper::Value& value);

template <>
inline std::unordered_map<std::string, std::string> ReadObject(
    Runtime& rt, const lynx::piper::Value& value) {
  std::unordered_map<std::string, std::string> result;
  if (!value.isObject()) {
    return result;
  }
  auto obj = value.getObject(rt);
  auto array_opt = obj.getPropertyNames(rt);
  if (!array_opt) {
    return result;
  }
  auto size_opt = array_opt->size(rt);
  if (!size_opt) {
    return result;
  }
  for (auto index = 0; index < *size_opt; index++) {
    auto key_opt = array_opt->getValueAtIndex(rt, index);
    if (!key_opt || !key_opt->isString()) {
      continue;
    }
    String key = key_opt->getString(rt);
    auto v_opt = obj.getProperty(rt, key);
    if (!v_opt || !v_opt->isString()) {
      continue;
    }
    result.emplace(key.utf8(rt), v_opt->getString(rt).utf8(rt));
  }
  return result;
}

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_JSI_VALUE_READER_H_
