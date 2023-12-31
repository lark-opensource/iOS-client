// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_CONTEXT_H_
#define LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_CONTEXT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace test {

using piper::BridgeBase;
using piper::ImplBase;

class TestContext;

class NapiTestContext : public BridgeBase {
 public:
  NapiTestContext(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  TestContext* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<TestContext>, Napi::Env);

  void Init(std::unique_ptr<TestContext>);

  // Attributes

  // Methods
  Napi::Value TestPlusOneMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "TestContext";
  }

 private:
  std::unique_ptr<TestContext> impl_;
};

}  // namespace test
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_CONTEXT_H_
