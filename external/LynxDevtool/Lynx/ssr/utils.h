// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_UTILS_H_
#define LYNX_SSR_UTILS_H_
#include "lepus/array.h"
#include "lepus/value.h"
#include "napi.h"

namespace lynx {
namespace ssr {
lepus::Value NapiValueToLepusValue(const Napi::Value& value);
Napi::Value LepusValueToNapiValue(Napi::Env env, const lepus::Value& value);
}  // namespace ssr
}  // namespace lynx

#endif  // LYNX_SSR_UTILS_H_
