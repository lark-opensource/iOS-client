// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/bindings/java_script_element.h"

#include <utility>

#include "base/log/logging.h"
#include "jsbridge/bindings/js_app.h"
#include "jsbridge/utils/utils.h"

namespace lynx {
namespace piper {
Value JavaScriptElement::get(lynx::piper::Runtime *rt,
                             const lynx::piper::PropNameID &name) {
  auto methodName = name.utf8(*rt);

  if (methodName == "animate") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "animate"), 4,
        [this](Runtime &rt, const piper::Value &this_val,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 4) {
            rt.reportJSIException(JSINativeException(
                "NativeElement.animate args count must be 4"));
            return std::optional<piper::Value>();
          }
          auto ptr = native_app_.lock();
          if (ptr) {
            auto props = lepus::CArray::Create();
            auto maybe_operation = args[0].asNumber(rt);
            if (!maybe_operation) {
              return std::optional<piper::Value>();
            }
            int32_t operation = static_cast<int32_t>(*maybe_operation);
            props->push_back(lepus::Value(operation));

            if (args[1].isString()) {
              props->push_back(
                  lepus::Value(args[1].getString(rt).utf8(rt).c_str()));
            }

            if (operation == AnimationOperation::START && args[2].isObject()) {
              auto value = ptr->ParseJSValueToLepusValue(
                  args[2], root_id_ == "card" ? "-1" : root_id_);
              if (!value) {
                rt.reportJSIException(JSINativeException(
                    "ParseJSValueToLepusValue error in animate args[2]"));
                return std::optional<piper::Value>();
              }
              props->push_back(*value);
            }

            if (operation == AnimationOperation::START && args[3].isObject()) {
              auto value = ptr->ParseJSValueToLepusValue(
                  args[3], root_id_ == "card" ? "-1" : root_id_);
              if (!value) {
                rt.reportJSIException(JSINativeException(
                    "ParseJSValueToLepusValue error in animate args[3]"));
                return std::optional<piper::Value>();
              }
              props->push_back(*value);
            }

            ptr->ElementAnimate(root_id_, selector_id_, lepus::Value(props));
          }
          return piper::Value::undefined();
        });
  }

  if (methodName == "setProperty") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "setProperty"), 2,
        [this](Runtime &rt, const piper::Value &this_val,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          auto ptr = native_app_.lock();
          if (count < 1) {
            rt.reportJSIException(JSINativeException(
                "lynx.setProperty args is empty! args count is 0."));
            return std::optional<piper::Value>();
          }
          auto lepus_value_opt =
              ptr->ParseJSValueToLepusValue(std::move(args[0]), PAGE_GROUP_ID);
          if (!lepus_value_opt) {
            rt.reportJSIException(
                JSINativeException("ParseJSValueToLepusValue error in "
                                   "java_script_element setProperty."));
            return std::optional<piper::Value>();
          }
          ptr->SetCSSVariable(root_id_, selector_id_,
                              std::move(*lepus_value_opt));
          return piper::Value::undefined();
        });
  }
  return piper::Value::undefined();
}

void JavaScriptElement::set(Runtime *, const PropNameID &name,
                            const Value &value) {}

std::vector<PropNameID> JavaScriptElement::getPropertyNames(Runtime &rt) {
  std::vector<PropNameID> vec;
  vec.push_back(piper::PropNameID::forUtf8(rt, "animate"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "setProperty"));
  return vec;
}
}  // namespace piper
}  // namespace lynx
