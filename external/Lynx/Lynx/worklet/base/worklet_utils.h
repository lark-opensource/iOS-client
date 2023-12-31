// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_WORKLET_BASE_WORKLET_UTILS_H_
#define LYNX_WORKLET_BASE_WORKLET_UTILS_H_

#include "jsbridge/napi/shim/shim_napi.h"
#include "lepus/value.h"

namespace lynx {
namespace worklet {

class ValueConverter {
 public:
  static Napi::String ConvertLepusStringToNapiString(
      Napi::Env env, const lepus::String& value);
  static Napi::Boolean ConvertLepusBoolToNapiBoolean(Napi::Env env, bool value);
  static Napi::Number ConvertLepusInt32ToNapiNumber(Napi::Env env,
                                                    int32_t value);
  static Napi::Number ConvertLepusUInt32ToNapiNumber(Napi::Env env,
                                                     uint32_t value);
  static Napi::Number ConvertLepusInt64ToNapiNumber(Napi::Env env,
                                                    int64_t value);
  static Napi::Number ConvertLepusUInt64ToNapiNumber(Napi::Env env,
                                                     uint64_t value);
  static Napi::Number ConvertLepusNumberToNapiNumber(Napi::Env env,
                                                     const lepus::Value& value);
  static Napi::Array ConvertLepusValueToNapiArray(Napi::Env env,
                                                  const lepus::Value& value);
  static Napi::Object ConvertLepusValueToNapiObject(Napi::Env env,
                                                    const lepus::Value& value);
  static Napi::Value ConvertLepusValueToNapiValue(Napi::Env env,
                                                  const lepus::Value& value);

  static lepus::Value ConvertNapiValueToLepusValue(const Napi::Value& value);
};

}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_WORKLET_BASE_WORKLET_UTILS_H_
