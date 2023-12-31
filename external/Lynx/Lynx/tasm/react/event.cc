// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/event.h"

#include "lepus/array.h"
#include "lepus/table.h"

namespace lynx {
namespace tasm {

lepus::Value PiperEventContent::ToLepusValue() const {
  constexpr const static char* kPiperFunctionName = "piperFunctionName";
  constexpr const static char* kPiperFuncArgs = "piperFunctionParameters";

  lepus::Value dict = lepus::Value(lepus::Dictionary::Create());
  dict.SetProperty(kPiperFunctionName, lepus::Value(piper_func_name_.c_str()));
  dict.SetProperty(kPiperFuncArgs, piper_func_args_);

  return dict;
}

bool EventHandler::IsBindEvent() const {
  constexpr const static char* kBindEvent = "bindEvent";
  return type_ == kBindEvent;
}

bool EventHandler::IsCatchEvent() const {
  constexpr const static char* kCatchEvent = "catchEvent";
  return type_ == kCatchEvent;
}

bool EventHandler::IsCaptureBindEvent() const {
  constexpr const static char* kCaptureBind = "capture-bind";
  return type_ == kCaptureBind;
}

bool EventHandler::IsCaptureCatchEvent() const {
  constexpr const static char* kCaptureCatch = "capture-catch";
  return type_ == kCaptureCatch;
}

bool EventHandler::IsGlobalBindEvent() const {
  constexpr const static char* kGlobalBind = "global-bindEvent";
  return type_ == kGlobalBind;
}

// The return value contains name, type, jsFunction, lepusFunction and
// piperEventContent. It must contain name and type, and may contain only one of
// jsFunction, lepusFunction and piperEventContent.
lepus::Value EventHandler::ToLepusValue() const {
  constexpr const static char* kEventName = "name";
  constexpr const static char* kEventType = "type";
  constexpr const static char* kFunctionName = "jsFunction";
  constexpr const static char* kLepusFunction = "lepusFunction";
  constexpr const static char* kPiperEventContent = "piperEventContent";

  lepus::Value dict = lepus::Value(lepus::Dictionary::Create());

  dict.SetProperty(kEventName, lepus::Value(name_.c_str()));
  dict.SetProperty(kEventType, lepus::Value(type_.c_str()));

  if (!function_.str().empty()) {
    dict.SetProperty(kFunctionName, lepus::Value(function_.c_str()));
  }
  if (!lepus_function_.IsEmpty()) {
    dict.SetProperty(kLepusFunction, lepus::Value(lepus_function_));
  }
  if (piper_event_vec_.has_value() && !piper_event_vec_->empty()) {
    const auto& ary = lepus::CArray::Create();
    for (const auto& piper_event : *piper_event_vec_) {
      ary->push_back(piper_event.ToLepusValue());
    }
    dict.SetProperty(kPiperEventContent, lepus::Value(ary));
  }

  return dict;
}

}  // namespace tasm
}  // namespace lynx
