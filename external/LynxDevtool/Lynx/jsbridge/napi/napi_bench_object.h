// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_JSBRIDGE_NAPI_NAPI_BENCH_OBJECT_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_BENCH_OBJECT_H_

#include <string>
#include <vector>

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {
namespace testing {

class BenchObject : public Napi::ScriptWrappable {
 public:
  BenchObject(const Napi::CallbackInfo& info) {}

  Napi::Value Method(const Napi::CallbackInfo& info) {
    auto val = info[0];
    if (!val.IsNumber()) {
      return Napi::Number::New(info.Env(), 0);
    }
    num++;
    return Napi::Number::New(info.Env(),
                             val.As<Napi::Number>().Uint32Value() + num);
  }

  int num = 0;

  static Napi::Function Create(Napi::Env env, size_t methodCount) {
    using Wrapped = Napi::ObjectWrap<BenchObject>;
    std::vector<std::string> names(methodCount);
    std::vector<Wrapped::PropertyDescriptor> props;

    for (size_t i = 0; i < methodCount; i++) {
      names[i] = std::string("method") + std::to_string(i);
      props.push_back(
          Wrapped::InstanceMethod(names[i].c_str(), &BenchObject::Method));
    }
    return Wrapped::DefineClass(env, "BenchObject", props).Get(env);
  }

  static void Install(Napi::Env env, Napi::Object& target, size_t methodCount) {
    if (target.Has("BenchObject")) {
      return;
    }
    target.Set("BenchObject", Create(env, methodCount));
  }
};

}  // namespace testing
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_BENCH_OBJECT_H_
