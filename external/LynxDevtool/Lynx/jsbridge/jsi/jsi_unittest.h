/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the current directory.
 */
// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSI_JSI_UNITTEST_H_
#define LYNX_JSBRIDGE_JSI_JSI_UNITTEST_H_

#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gtest/gtest.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/quickjs/quickjs_runtime.h"

#ifdef OS_OSX
#include "jsbridge/jsc/jsc_runtime.h"
#endif

namespace lynx::piper {
class Runtime;
namespace test {

using RuntimeFactory = std::function<std::unique_ptr<Runtime>()>;

template <typename T,
          typename = std::enable_if_t<std::is_base_of_v<Runtime, T>>>
std::unique_ptr<Runtime> MakeRuntimeFactory() {
  auto rt = std::make_unique<T>();

  auto vm = rt->createVM(nullptr);
  auto context = rt->createContext(vm);

  rt->InitRuntime(context, nullptr);
  return rt;
}

inline std::vector<RuntimeFactory> runtimeGenerators() {
  std::vector<RuntimeFactory> runtime_factories{};

  runtime_factories.emplace_back(MakeRuntimeFactory<QuickjsRuntime>);
#ifdef OS_OSX
  runtime_factories.emplace_back(MakeRuntimeFactory<JSCRuntime>);
#endif
  // TODO(wangqingyu): add V8 runtime

  return runtime_factories;
}

class JSITestBase : public ::testing::TestWithParam<RuntimeFactory> {
 public:
  JSITestBase() : factory(GetParam()), runtime(factory()), rt(*runtime) {}

  std::optional<Value> eval(const char* code) {
    return rt.global().getPropertyAsFunction(rt, "eval")->call(rt, code);
  }

  Function function(const std::string& code) {
    return eval(("(" + code + ")").c_str())->getObject(rt).getFunction(rt);
  }

  bool checkValue(const Value& value, const std::string& jsValue) {
    return function("function(value) { return value == " + jsValue + "; }")
        .call(rt, std::move(value))
        ->getBool();
  }

  RuntimeFactory factory;
  std::unique_ptr<Runtime> runtime;
  Runtime& rt;
};

}  // namespace test
}  // namespace lynx::piper

#endif  // LYNX_JSBRIDGE_JSI_JSI_UNITTEST_H_
