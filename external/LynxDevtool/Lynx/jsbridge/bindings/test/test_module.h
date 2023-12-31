// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_TEST_TEST_MODULE_H_
#define LYNX_JSBRIDGE_BINDINGS_TEST_TEST_MODULE_H_

#include "jsbridge/napi/napi_environment.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace test {

class TestModule : public piper::NapiEnvironment::Module {
 public:
  TestModule() = default;

  void OnLoad(Napi::Object& target) override;
};

}  // namespace test
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_TEST_TEST_MODULE_H_
