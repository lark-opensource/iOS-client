// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_NAPI_SELECT_ELEMENT_RESULT_H_
#define LYNX_HEADLESS_NAPI_SELECT_ELEMENT_RESULT_H_

#include <string>

#include "tasm/radon/radon_node.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {
namespace headless {

class SelectElementResult : public Napi::ObjectWrap<SelectElementResult> {
 public:
  explicit SelectElementResult(const Napi::CallbackInfo& info);
  ~SelectElementResult() override;

  static Napi::Function GetConstructor(Napi::Env env);

  Napi::Value SendTouchEvent(const Napi::CallbackInfo& info);
  Napi::Value SendCustomEvent(const Napi::CallbackInfo& info);
  Napi::Value DumpTree(const Napi::CallbackInfo& info);
  Napi::Value DumpSnapshot(const Napi::CallbackInfo& info);
  Napi::Value DumpComputedStyle(const Napi::CallbackInfo& info);

  Napi::Value TriggerComponentAtIndex(const Napi::CallbackInfo& info);
  Napi::Value TriggerEnqueueComponent(const Napi::CallbackInfo& info);
  Napi::Value SendNodeAppearEvent(const Napi::CallbackInfo& info);
  Napi::Value SendNodeDisappearEvent(const Napi::CallbackInfo& info);

 private:
  Napi::Value SendNodeAppearDisappearEvent(std::string,
                                           const Napi::CallbackInfo& info);

 private:
  Napi::Reference<Napi::Object> lynx_view_;
  int impl_id_;
};

class SelectComponentResult : public Napi::ObjectWrap<SelectComponentResult> {
 public:
  explicit SelectComponentResult(const Napi::CallbackInfo& info);
  ~SelectComponentResult() override;

  static Napi::Function GetConstructor(Napi::Env env);

  Napi::Value GetState(const Napi::CallbackInfo& info);
  Napi::Value GetProps(const Napi::CallbackInfo& info);

 private:
  Napi::Reference<Napi::Object> lynx_view_;
  tasm::RadonNode* node_;
};
}  // namespace headless
}  // namespace lynx

#undef Napi

#endif  // LYNX_HEADLESS_NAPI_SELECT_ELEMENT_RESULT_H_
