// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_HEADLESS_UTILS_H_
#define LYNX_HEADLESS_HEADLESS_UTILS_H_

#include <string>

#include "lepus/value-inl.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {
namespace headless {

lepus::Value NapiValueToLepusValue(Napi::Value value);
Napi::Value LepusValueToNapiValue(Napi::Env env, lepus::Value value);

Napi::Value JSONToNapiValue(Napi::Env env, std::string json_str);
std::string NapiValueToJSON(Napi::Value value);

}  // namespace headless
}  // namespace lynx

#undef Napi

#endif  // LYNX_HEADLESS_HEADLESS_UTILS_H_
