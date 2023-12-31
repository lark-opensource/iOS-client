// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/bindings/lynx.h"

#include <string>
#include <utility>

#include "base/log/logging.h"
#include "jsbridge/bindings/java_script_element.h"
#include "jsbridge/utils/utils.h"

namespace lynx {
namespace piper {
Value LynxProxy::get(lynx::piper::Runtime *rt,
                     const lynx::piper::PropNameID &name) {
  auto methodName = name.utf8(*rt);
  if (methodName == "__globalProps") {
    auto native_app = native_app_.lock();
    if (!native_app) {
      return piper::Value::undefined();
    }
    auto global_props_opt = native_app->getInitGlobalProps();
    if (!global_props_opt) {
      // TODO(wujintian): return optional here.
      return piper::Value::undefined();
    }
    return std::move(*global_props_opt);
  }

  if (methodName == "getI18nResource") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "getI18nResource"), 0,
        [this](Runtime &rt, const piper::Value &this_val,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          auto native_app = native_app_.lock();
          if (!native_app) {
            return piper::Value::undefined();
          }
          return native_app->getI18nResource();
        });
  }

  if (methodName == "getComponentContext") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "getComponentContext"), 3,
        [this](Runtime &rt, const piper::Value &this_val,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 3) {
            rt.reportJSIException(JSINativeException(
                "lynx.getComponentContext args count must be 3"));
            return std::optional<piper::Value>();
          }
          auto ptr = native_app_.lock();
          if (ptr && !ptr->IsDestroying()) {
            std::string id;
            if (args[0].isString()) {
              id = args[0].getString(rt).utf8(rt);
            }
            std::string key;
            if (args[1].isString()) {
              key = args[1].getString(rt).utf8(rt);
            }
            ApiCallBack callback;
            if (args[2].isObject() && args[2].getObject(rt).isFunction(rt)) {
              callback =
                  ptr->CreateCallBack(args[2].getObject(rt).getFunction(rt));
            }
            ptr->getContextDataAsync(id, key, callback);
          }
          return piper::Value::undefined();
        });
  }

  if (methodName == "requestAnimationFrame") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "requestAnimationFrame"), 1,

        [this](Runtime &rt, const piper::Value &thisVal,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count != 1) {
            rt.reportJSIException(JSINativeException(
                "requestAnimationFrame arg count must be 1"));
            return std::optional<piper::Value>();
          }

          if (args[0].isObject()) {
            auto func = args[0].getObject(rt).asFunction(rt);
            if (!func) {
              return std::optional<piper::Value>();
            }
            return RequestAnimationFrame(std::move(*func));
          } else {
            return piper::Value::undefined();
          }
        });
  }

  if (methodName == "cancelAnimationFrame") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "cancelAnimationFrame"), 1,

        [this](Runtime &rt, const piper::Value &thisVal,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count != 1) {
            rt.reportJSIException(
                JSINativeException("cancelAnimationFrame arg count must be 1"));
            return std::optional<piper::Value>();
          }

          // also use clearTimeout
          if (args[0].isNumber()) {
            CancelAnimationFrame(args[0].getNumber());
          }

          return piper::Value::undefined();
        });
  }

  if (methodName == "createElement") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "createElement"), 2,
        [this](Runtime &rt, const piper::Value &this_val,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 2) {
            rt.reportJSIException(JSINativeException(
                "lynx.createNativeElement args count must be 1"));
            return std::optional<piper::Value>();
          }
          std::string root_id;
          if (args[0].isString()) {
            root_id = args[0].getString(rt).utf8(rt);
          }
          std::string id;
          if (args[1].isString()) {
            id = args[1].getString(rt).utf8(rt);
          }
          return piper::Value(Object::createFromHostObject(
              rt, std::make_shared<JavaScriptElement>(rt_, native_app_, root_id,
                                                      id)));
        });
  }

  if (methodName == "fetchDynamicComponent") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "fetchDynamicComponent"), 3,

        [this](Runtime &rt, const piper::Value &thisVal,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 3) {
            rt.reportJSIException(JSINativeException(
                "lynx.fetchDynamicComponent args count must be 3"));
            return std::optional<piper::Value>();
          }

          auto ptr = native_app_.lock();
          if (ptr) {
            std::string url;
            ApiCallBack callback;

            if (!args[0].isString()) {
              rt.reportJSIException(JSINativeException(
                  "lynx.fetchDynamicComponent args0 must be string"));
              return std::optional<piper::Value>();
            }
            url = args[0].getString(rt).utf8(rt).c_str();

            if (!args[2].isObject() || !args[2].getObject(rt).isFunction(rt)) {
              rt.reportJSIException(JSINativeException(
                  "lynx.fetchDynamicComponent args2 must be ApiCallBack"));
              return std::optional<piper::Value>();
            }
            callback =
                ptr->CreateCallBack(args[2].getObject(rt).getFunction(rt));

            ptr->QueryComponent(url, callback);
          }

          return piper::Value::undefined();
        });
  }

  // js reload api
  if (methodName == "reload") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "reload"), 2,
        [this](Runtime &rt, const piper::Value &thisVal,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          auto ptr = native_app_.lock();
          if (ptr) {
            lepus::Value value(lepus::Dictionary::Create());
            ApiCallBack callback;
            if (count > 0 && args[0].isObject()) {
              if (!args[0].isObject()) {
                rt.reportJSIException(JSINativeException(
                    "lynx.reload's first params must be object."));
                return piper::Value::undefined();
              }
              auto lepus_value_opt = ptr->ParseJSValueToLepusValue(
                  std::move(args[0]), PAGE_GROUP_ID);
              if (!lepus_value_opt) {
                rt.reportJSIException(JSINativeException(
                    "ParseJSValueToLepusValue error in lynx.reload."));
                return std::optional<piper::Value>();
              }
              if (!lepus_value_opt->IsObject()) {
                return piper::Value::undefined();
              }
              value = std::move(*lepus_value_opt);
            }

            if (count > 1 && args[1].isObject() &&
                args[1].getObject(rt).isFunction(rt)) {
              if (!args[1].isObject() ||
                  !args[1].getObject(rt).isFunction(rt)) {
                rt.reportJSIException(JSINativeException(
                    "lynx.reload's second params must be function."));
                return piper::Value::undefined();
              }
              // lynx.reload has one optional callback param.
              callback =
                  ptr->CreateCallBack(args[1].getObject(rt).getFunction(rt));
            }
            ptr->ReloadFromJS(value, callback);
          }
          return piper::Value::undefined();
        });
  }

  if (methodName == "QueryComponent") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "QueryComponent"), 2,
        [this](Runtime &rt, const piper::Value &thisVal,
               const piper::Value *args,
               size_t count) -> std::optional<piper::Value> {
          auto ptr = native_app_.lock();
          if (ptr) {
            std::string url;
            ApiCallBack callback;
            if (!args[0].isString()) {
              rt.reportJSIException(JSINativeException(
                  "lynx.QueryComponent's first params must be String."));
              return piper::Value::undefined();
            }
            url = args[0].getString(rt).utf8(rt).c_str();
            if (!args[1].isObject() || !args[1].getObject(rt).isFunction(rt)) {
              rt.reportJSIException(JSINativeException(
                  "lynx.QueryComponent's second params must be function."));
              return piper::Value::undefined();
            }

            callback =
                ptr->CreateCallBack(args[1].getObject(rt).getFunction(rt));
            ptr->QueryComponent(url, callback);
          }

          return piper::Value::undefined();
        });
  }

  return piper::Value::undefined();
}

void LynxProxy::set(Runtime *, const PropNameID &name, const Value &value) {}

std::vector<PropNameID> LynxProxy::getPropertyNames(Runtime &rt) {
  std::vector<PropNameID> vec;
  vec.push_back(piper::PropNameID::forUtf8(rt, "__globalProps"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "getI18nResource"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "getComponentContext"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "requestAnimationFrame"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "cancelAnimationFrame"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "createElement"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "fetchDynamicComponent"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "reload"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "QueryComponent"));
  return vec;
}

piper::Value LynxProxy::RequestAnimationFrame(piper::Function func) {
  if (animation_frame_handler_) {
    // requestVSyncTick
    auto ptr = native_app_.lock();
    if (ptr && !ptr->IsDestroying()) {
      ptr->AsyncRequestVSync(reinterpret_cast<uintptr_t>(this),
                             [this](int64_t frame_start, int64_t frame_end) {
                               DoFrame(frame_start);
                             });
    }

    const int64_t id =
        animation_frame_handler_->RequestAnimationFrame(std::move(func));

    return piper::Value(static_cast<double>(id));
  }
  return piper::Value::undefined();
}

void LynxProxy::CancelAnimationFrame(int64_t id) {
  if (animation_frame_handler_) {
    animation_frame_handler_->CancelAnimationFrame(id);
  }
}

void LynxProxy::DoFrame(int64_t time_stamp) {
  static constexpr int64_t kNanoSecondsPerMilliSecond = 1e+6;
  if (animation_frame_handler_ && !has_paused_animation_frame_) {
    // W3C window.requestAnimationFrame request milliseconds
    animation_frame_handler_->DoFrame(time_stamp / kNanoSecondsPerMilliSecond,
                                      rt_.lock().get());
#ifndef OS_WIN
    fluency_tracer_.Trigger(time_stamp);
#endif
  }
}

void LynxProxy::PauseAnimationFrame() {
  if (animation_frame_handler_ &&
      animation_frame_handler_->HasPendingRequest()) {
    has_paused_animation_frame_ = true;
  }
}

void LynxProxy::ResumeAnimationFrame() {
  if (has_paused_animation_frame_) {
    has_paused_animation_frame_ = false;
    auto ptr = native_app_.lock();
    if (ptr) {
      ptr->AsyncRequestVSync(reinterpret_cast<uintptr_t>(this),
                             [this](int64_t frame_start, int64_t frame_end) {
                               DoFrame(frame_start);
                             });
    }
  }
}

void LynxProxy::Destroy() {
  if (animation_frame_handler_) {
    animation_frame_handler_->Destroy();
  }
}

void LynxProxy::SetPostDoFrameTaskWithFunction(piper::Function func) {
  if (animation_frame_handler_) {
    animation_frame_handler_->SetPostDoFrameTaskWithFunction(std::move(func));
  }
}

}  // namespace piper
}  // namespace lynx
