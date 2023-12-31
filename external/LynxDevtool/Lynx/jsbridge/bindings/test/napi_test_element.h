// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_ELEMENT_H_
#define LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_ELEMENT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace test {

using piper::BridgeBase;
using piper::ImplBase;

class TestElement;

class NapiTestElement : public BridgeBase {
 public:
  NapiTestElement(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  TestElement* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<TestElement>, Napi::Env);

  void Init(std::unique_ptr<TestElement>);

  // Attributes

  // Methods
  Napi::Value GetContextMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "TestElement";
  }

 private:
  void Init(const Napi::CallbackInfo&);
  std::unique_ptr<TestElement> impl_;
};

}  // namespace test
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_TEST_NAPI_TEST_ELEMENT_H_
