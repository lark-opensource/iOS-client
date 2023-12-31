// Copyright 2017 The Lynx Authors. All rights reserved.

#include "jsbridge/bindings/js_app.h"

#include <tasm/template_assembler.h>
#include <time.h>

#include <algorithm>
#include <cmath>
#include <memory>
#include <string>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/string/string_number_convert.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/bindings/console.h"
#include "jsbridge/bindings/lynx.h"
#include "jsbridge/bindings/lynx_error.h"
#include "jsbridge/platform_value.h"
#include "jsbridge/runtime/lynx_api_handler.h"
#include "jsbridge/runtime/runtime_constant.h"
#include "jsbridge/utils/utils.h"
#include "lepus/lepus_string.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/lynx_view_data_manager.h"
#include "tasm/radon/base_component.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/value_utils.h"
#include "third_party/rapidjson/document.h"
#include "third_party/rapidjson/error/en.h"
#include "third_party/rapidjson/reader.h"
#include "third_party/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/writer.h"
namespace lynx {
namespace piper {

namespace {

// TODO(douyanlin): corejs uses this map
inline std::unordered_map<std::string, std::string>& GetJSAssetsMap() {
  static base::NoDestructor<std::unordered_map<std::string, std::string>>
      js_assets_map_;
  return *js_assets_map_;
}

}  // namespace

Value AppProxy::get(Runtime* rt, const PropNameID& name) {
  auto methodName = name.utf8(*rt);
  if (methodName == "id") {
    auto native_app = native_app_.lock();
    if (!native_app || native_app->IsDestroying()) {
      return piper::Value::undefined();
    }
    auto guid =
        piper::String::createFromUtf8(*rt, native_app->getAppGUID().c_str());
    return piper::Value(*rt, guid);
  } else if (methodName == "loadScript") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "loadScript"), 1,
        [this](Runtime& rt, const Value& thisVal, const Value* args,
               size_t count) -> std::optional<piper::Value> {
          std::shared_ptr<Runtime> js_runtime = rt_.lock();
          if (!js_runtime) {
            return Value::undefined();
          }

          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("loadScript arg count must > 0"));
            return std::optional<piper::Value>();
          }

          auto sourceURL = args[0].asString(rt);
          if (!sourceURL) {
            return std::optional<piper::Value>();
          }
          std::string entryName = tasm::DEFAULT_ENTRY_NAME;
          if (count > 1 && args[1].isString()) {
            entryName = args[1].getString(rt).utf8(rt);
          }
          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            return piper::Value::undefined();
          }
          return native_app->loadScript(entryName, sourceURL->utf8(rt));
        });
  } else if (methodName == "readScript") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "readScript"), 1,
        [this](Runtime& rt, const Value& thisVal, const Value* args,
               size_t count) -> std::optional<piper::Value> {
          std::shared_ptr<Runtime> js_runtime = rt_.lock();
          if (!js_runtime) {
            return Value::undefined();
          }

          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("readScript arg count must > 0"));
            return std::optional<piper::Value>();
          }

          auto sourceURL = args[0].asString(rt);
          if (!sourceURL) {
            return std::optional<piper::Value>();
          }
          std::string entry_name = tasm::DEFAULT_ENTRY_NAME;
          if (count > 1 && args[1].isObject()) {
            auto entry_opt =
                args[1].getObject(rt).getProperty(rt, "dynamicComponentEntry");
            if (!entry_opt) {
              return std::optional<piper::Value>();
            }
            auto entry_name_opt = entry_opt->asString(rt);
            if (!entry_name_opt) {
              return std::optional<piper::Value>();
            }
            entry_name = entry_name_opt->utf8(rt);
          }
          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            return piper::Value::undefined();
          }
          return native_app->readScript(entry_name, sourceURL->utf8(rt));
        });
  } else if (methodName == "readDynamicComponentScripts") {
    // deprecated
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "readDynamicComponentScripts"), 1,
        [](Runtime& rt, const Value& thisVal, const Value* args,
           size_t count) -> std::optional<piper::Value> {
          return piper::Value::undefined();
        });
  } else if (methodName == "updateData") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "updateData"), 2,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "updateData");
          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("updateData arg count must be 1"));
            return std::optional<piper::Value>();
          }

          auto ptr = native_app_.lock();
          if (!ptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          auto lepus_value_opt =
              ptr->ParseJSValueToLepusValue(std::move(args[0]), PAGE_GROUP_ID);
          if (!lepus_value_opt) {
            rt.reportJSIException(JSINativeException(
                "ParseJSValueToLepusValue error in updateData"));
            return std::optional<piper::Value>();
          }
          if (!lepus_value_opt->IsObject()) {
            return piper::Value::undefined();
          }

          runtime::UpdateDataType update_data_type;
          if (count >= 2 && args[1].isNumber()) {
            // updateDataType here is an optional argument
            // updateData(data, updateDataType);
            update_data_type = runtime::UpdateDataType(args[1].getNumber());
          }

          ApiCallBack callback;
          if (count >= 2 && args[1].isObject() &&
              args[1].getObject(rt).isFunction(rt)) {
            // mini-app do not has updateDataType, keep behavior of 2.4
            // callback here are optional arguments
            // updateData(data, callback);
            callback =
                ptr->CreateCallBack(args[1].getObject(rt).getFunction(rt));
          }
          if (count >= 3 && args[2].isObject() &&
              args[2].getObject(rt).isFunction(rt)) {
            // updateDataType and callback here are optional arguments
            // updateData(data, updateDataType, callback);
            callback =
                ptr->CreateCallBack(args[2].getObject(rt).getFunction(rt));
          }
          TRACE_EVENT_BEGIN(
              LYNX_TRACE_CATEGORY, "UpdateDataToTASM",
              [&](lynx::perfetto::EventContext ctx) {
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("CallbackID");
                debug->set_string_value(std::to_string(callback.id()));
              });
          ptr->appDataChange(std::move(*lepus_value_opt), callback,
                             std::move(update_data_type));
          TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
          return piper::Value::undefined();
        });
  } else if (methodName == "batchedUpdateData") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "batchedUpdateData"), 1,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("batchedUpdateData arg count must be 1"));
            return std::optional<piper::Value>();
          }

          auto native_app = native_app_.lock();
          if (native_app && !native_app->IsDestroying()) {
            if (!native_app->batchedUpdateData(args[0])) {
              return std::optional<piper::Value>();
            }
          }
          return piper::Value::undefined();
        });
  } else if (methodName == "setCard") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "setCard"), 1,

        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX PageProxy get -> setCard");
          if (count != 1) {
            rt.reportJSIException(
                JSINativeException("setCard arg count must be 1"));
            return std::optional<piper::Value>();
          }

          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            return piper::Value::undefined();
          }

          if (args[0].isObject()) {
            native_app->setJsAppObj(args[0].getObject(rt));
          }

          return piper::Value::undefined();
        });
  } else if (methodName == "setTimeout") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "setTimeout"), 1,

        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGV("LYNX App get -> setTimeout");

          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("setTimeout args count must >= 1"));
            return std::optional<piper::Value>();
          }
          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            return piper::Value::undefined();
          }
          if (args[0].isObject()) {
            int interval =
                (count >= 2 && args[1].isNumber())
                    ? std::max(static_cast<int>(args[1].getNumber()), 0)
                    : 0;

            auto callback = args[0].getObject(rt).asFunction(rt);
            if (!callback) {
              return std::optional<piper::Value>();
            }
            return native_app->setTimeout(std::move(*callback), interval);
          } else {
            return piper::Value::undefined();
          }
        });
  } else if (methodName == "setInterval") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "setInterval"), 2,

        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGV("LYNX App get -> setInterval");
          if (count != 2) {
            rt.reportJSIException(
                JSINativeException("setInterval arg count must be 2"));
            return std::optional<piper::Value>();
          }
          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            return piper::Value::undefined();
          }
          if (args[0].isObject() && args[1].isNumber()) {
            auto callback = args[0].getObject(rt).asFunction(rt);
            if (!callback) {
              return std::optional<piper::Value>();
            }
            int interval = std::max(static_cast<int>(args[1].getNumber()), 0);
            return native_app->setInterval(std::move(*callback), interval);
          } else {
            return piper::Value::undefined();
          }
        });
  } else if (methodName == "clearTimeout") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "clearTimeout"), 1,

        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGV("LYNX App get -> clearTimeout");
          if (count != 1) {
            rt.reportJSIException(
                JSINativeException("clearTimeout arg count must be 1"));
            return std::optional<piper::Value>();
          }
          auto native_app = native_app_.lock();
          if (!native_app) {
            return piper::Value::undefined();
          }

          if (args[0].isNumber()) {
            native_app->clearTimeout(args[0].getNumber());
          }

          return piper::Value::undefined();
        });
  } else if (methodName == "clearInterval") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "clearInterval"), 1,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGV("LYNX App get -> clearInterval");
          if (count != 1) {
            rt.reportJSIException(
                JSINativeException("clearInterval arg count must be 1"));
            return std::optional<piper::Value>();
          }
          auto native_app = native_app_.lock();
          if (!native_app) {
            return piper::Value::undefined();
          }

          // also use clearTimeout
          if (args[0].isNumber()) {
            native_app->clearTimeout(args[0].getNumber());
          }

          return piper::Value::undefined();
        });
  } else if (methodName == "nativeModuleProxy") {
    auto native_app = native_app_.lock();
    if (!native_app) {
      return piper::Value::undefined();
    }

    return native_app->nativeModuleProxy();
  } else if (methodName == "reportException") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "reportException"), 3,
        [this](Runtime& rt, const Value& thisVal, const Value* args,
               size_t count) -> std::optional<piper::Value> {
          std::shared_ptr<Runtime> js_runtime = rt_.lock();
          if (!js_runtime) {
            return Value::undefined();
          }

          if (count < 1) {
            rt.reportJSIException(
                JSINativeException("the arg count of reportException must be "
                                   "greater than or equal to 2"));
            return std::optional<piper::Value>();
          }

          std::string msg("msg is empty");
          if (args[0].isString()) {
            msg = args[0].getString(rt).utf8(rt);
          }

          std::string stack("stack is empty");
          if (count >= 2 && args[1].isString()) {
            stack = args[1].getString(rt).utf8(rt);
          }

          int32_t error_code = LYNX_ERROR_CODE_JAVASCRIPT;
          if (count >= 3 && args[2].isNumber()) {
            error_code = static_cast<int32_t>(std::round(args[2].getNumber()));
          }

          auto native_app = native_app_.lock();
          if (!native_app || native_app->IsDestroying()) {
            LOGE("js_app reportException when native_app is destroying: "
                 << msg);
            return piper::Value::undefined();
          }

          native_app->reportException(msg, stack, error_code);
          return piper::Value::undefined();
        });
  } else if (methodName == "updateComponentData") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "updateComponentData"), 4,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX PageProxy get -> updateComponentData" << this);
          if (count < 3) {
            rt.reportJSIException(
                JSINativeException("updateComponentData arg count must >= 3"));
            return std::optional<piper::Value>();
          }
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "updateComponentData");
          auto ptr = native_app_.lock();
          if (!ptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          std::string id;
          if (args[0].isString()) {
            id = args[0].getString(rt).utf8(rt);
          }
          auto lepus_value_opt = ptr->ParseJSValueToLepusValue(args[1], id);
          if (!lepus_value_opt) {
            rt.reportJSIException(JSINativeException(
                "ParseJSValueToLepusValue error in updateComponentData"));
            return std::optional<piper::Value>();
          }
          if (lepus_value_opt->IsObject()) {
            ApiCallBack callback;
            if (args[2].isObject() && args[2].getObject(rt).isFunction(rt)) {
              // callback here is a required argument
              // updateComponentData(id, data, callback);
              callback =
                  ptr->CreateCallBack(args[2].getObject(rt).getFunction(rt));
            }

            runtime::UpdateDataType update_data_type;
            if (count >= 4) {
              // there are two ways to call updateComponentData
              // - updateComponentData(id, data, callback);
              // - updateComponentData(id, data, callback, updateDataType);
              if (args[3].isNumber()) {
                // updateDataType here is a optional argument
                update_data_type = runtime::UpdateDataType(args[3].getNumber());
              }
            }

            TRACE_EVENT_BEGIN(
                LYNX_TRACE_CATEGORY, "updateComponentDataToTASM",
                [&](lynx::perfetto::EventContext ctx) {
                  auto* debug = ctx.event()->add_debug_annotations();
                  debug->set_name("CallbackID");
                  debug->set_string_value(std::to_string(callback.id()));
                  auto* type_annotation = ctx.event()->add_debug_annotations();
                  type_annotation->set_name("update_data_type");
                  type_annotation->set_string_value(
                      std::to_string(static_cast<uint32_t>(update_data_type)));
                });
            ptr->updateComponentData(id, std::move(*lepus_value_opt), callback,
                                     std::move(update_data_type));
            TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
          }

          return piper::Value::undefined();
        });
  } else if (methodName == "triggerLepusGlobalEvent") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "triggerLepusGlobalEvent"), 2,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX PageProxy get -> triggerLepusGlobalEvent" << this);
          if (count != 2) {
            rt.reportJSIException(JSINativeException(
                "triggerLepusGlobalEvent arg count must be 2"));
            return std::optional<piper::Value>();
          }
          std::string event;
          if (args[0].isString()) {
            event = args[0].getString(rt).utf8(rt);
          }
          if (!args[1].isObject()) {
            rt.reportJSIException(
                JSINativeException("triggerLepusGlobalEvent arg error"));
            return std::optional<piper::Value>();
          }
          auto ptr = native_app_.lock();
          if (ptr && !ptr->IsDestroying()) {
            auto lepus_value_opt = ptr->ParseJSValueToLepusValue(
                std::move(args[1]), PAGE_GROUP_ID);
            if (!lepus_value_opt) {
              rt.reportJSIException(JSINativeException(
                  "ParseJSValueToLepusValue error in triggerLepusGlobalEvent"));
              return std::optional<piper::Value>();
            }
            ptr->triggerLepusGlobalEvent(event, std::move(*lepus_value_opt));
          }
          return piper::Value::undefined();
        });
  } else if (methodName == "triggerComponentEvent") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "triggerComponentEvent"), 2,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX PageProxy get -> triggerComponentEvent" << this);
          if (count != 2) {
            rt.reportJSIException(JSINativeException(
                "triggerComponentEvent arg count must be 2"));
            return std::optional<piper::Value>();
          }
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "triggerComponentEvent");
          std::string id;
          if (args[0].isString()) {
            id = args[0].getString(rt).utf8(rt);
          }

          auto ptr = native_app_.lock();
          if (ptr && !ptr->IsDestroying()) {
            auto lepus_value_opt = ptr->ParseJSValueToLepusValue(
                std::move(args[1]), PAGE_GROUP_ID);
            if (!lepus_value_opt) {
              rt.reportJSIException(JSINativeException(
                  "ParseJSValueToLepusValue error in triggerComponentEvent"));
              return std::optional<piper::Value>();
            }
            TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY,
                              "triggerComponentEventToTASM");
            ptr->triggerComponentEvent(id, std::move(*lepus_value_opt));
            TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
          }

          return piper::Value::undefined();
        });
  } else if (methodName == "selectComponent") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "selectComponent"), 0,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> selectComponent");
          if (count < 4) {
            rt.reportJSIException(
                JSINativeException("selectComponent args count must be 4"));
            return std::optional<piper::Value>();
          }

          TRACE_EVENT(LYNX_TRACE_CATEGORY, "selectComponent");
          auto ptr = native_app_.lock();
          if (!ptr) {
            return piper::Value::undefined();
          }

          std::string comp_id;
          if (args[0].isString()) {
            comp_id = args[0].getString(rt).utf8(rt);
          }

          std::string id_selector;
          if (args[1].isString()) {
            id_selector = args[1].getString(rt).utf8(rt);
          }

          bool single = true;
          if (args[2].isBool()) {
            single = args[2].getBool();
          }

          ApiCallBack callback;
          if (count >= 4 && args[3].isObject() &&
              args[3].getObject(rt).isFunction(rt)) {
            callback =
                ptr->CreateCallBack(args[3].getObject(rt).getFunction(rt));
          }
          ptr->selectComponent(comp_id, id_selector, single, callback);
          return piper::Value::undefined();
        });
  } else if (methodName == "loadScriptAsync") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "loadScriptAsync"), 2,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> loadScriptAsync" << this);
          if (count != 2) {
            rt.reportJSIException(
                JSINativeException("loadScriptAsync arg count must be 2"));
            return std::optional<piper::Value>();
          }

          auto ptr = native_app_.lock();
          // not allow invoke when destroy lifecycle
          if (ptr == nullptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          std::string url;
          if (args[0].isString()) {
            url = args[0].getString(rt).utf8(rt);
          }

          ApiCallBack callback;
          if (args[1].isObject() && args[1].getObject(rt).isFunction(rt)) {
            callback =
                ptr->CreateCallBack(args[1].getObject(rt).getFunction(rt));
          }

          ptr->LoadScriptAsync(url, callback);
          return piper::Value::undefined();
        });
  } else if (methodName == "onPiperInvoked") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "onPiperInvoked"), 1,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> onPiperInvoked" << this);
          if (count != 2) {
            rt.reportJSIException(
                JSINativeException("onPiperInvoked arg count must be 2"));
            return std::optional<Value>();
          }

          auto ptr = native_app_.lock();
          // not allow invoke when destroy lifecycle
          if (ptr == nullptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }
          std::string module_name, method_name;
          if (args[0].isString()) {
            module_name = args[0].getString(rt).utf8(rt);
          }
          if (args[1].isString()) {
            method_name = args[1].getString(rt).utf8(rt);
          }

          ptr->onPiperInvoked(module_name, method_name);
          return piper::Value::undefined();
        });
  } else if (methodName == "getPathInfo") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "getPathInfo"), 5,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> getPathInfo");
          if (count < 5) {
            rt.reportJSIException(
                JSINativeException("getPathInfo args count must be 5"));
            return std::optional<Value>();
          }

          TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::getPathInfo");
          auto ptr = native_app_.lock();
          if (!ptr) {
            return piper::Value::undefined();
          }
          if (!(args[0].isNumber() && args[1].isString() &&
                args[2].isString() && args[3].isBool() && args[4].isObject() &&
                args[4].getObject(rt).isFunction(rt))) {
            rt.reportJSIException(
                JSINativeException("getPathInfo args type is error"));
            return std::optional<Value>();
          }
          tasm::NodeSelectOptions::IdentifierType identifier_type =
              static_cast<tasm::NodeSelectOptions::IdentifierType>(
                  args[0].getNumber());
          std::string identifier = args[1].getString(rt).utf8(rt);
          std::string component_id = args[2].getString(rt).utf8(rt);
          bool first_only = args[3].getBool();
          ApiCallBack callback =
              ptr->CreateCallBack(args[4].getObject(rt).getFunction(rt));
          auto info = tasm::NodeSelectOptions(identifier_type, identifier);
          info.component_only = false;
          info.only_current_component = true;
          info.first_only = first_only;
          tasm::NodeSelectRoot root =
              count >= 6 && args[5].isNumber()
                  ? tasm::NodeSelectRoot::ByUniqueId(args[5].getNumber())
                  : tasm::NodeSelectRoot::ByComponentId(component_id);
          ptr->GetPathInfo(std::move(root), std::move(info), callback);
          return piper::Value::undefined();
        });
  } else if (methodName == "invokeUIMethod") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "invokeUIMethod"), 6,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> invokeUIMethod");
          if (count < 6) {
            rt.reportJSIException(
                JSINativeException("invokeUIMethod args count must be 6"));
            return std::optional<Value>();
          }

          TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::invokeUIMethod");

          auto ptr = native_app_.lock();
          if (!ptr) {
            return piper::Value::undefined();
          }
          tasm::NodeSelectOptions::IdentifierType identifier_type =
              static_cast<tasm::NodeSelectOptions::IdentifierType>(
                  args[0].getNumber());
          std::string identifier = args[1].getString(rt).utf8(rt);
          std::string component_id = args[2].getString(rt).utf8(rt);
          std::string method = args[3].getString(rt).utf8(rt);
          const piper::Value* params = &args[4];
          ApiCallBack callback =
              ptr->CreateCallBack(args[5].getObject(rt).getFunction(rt));
          auto options = tasm::NodeSelectOptions(identifier_type, identifier);
          options.component_only = false;
          options.only_current_component = true;
          options.first_only = true;
          tasm::NodeSelectRoot root =
              count >= 7 && args[6].isNumber()
                  ? tasm::NodeSelectRoot::ByUniqueId(args[6].getNumber())
                  : tasm::NodeSelectRoot::ByComponentId(component_id);
          ptr->InvokeUIMethod(std::move(root), std::move(options),
                              std::move(method), params, callback);
          return piper::Value::undefined();
        });
  } else if (methodName == "getFields") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "getFields"), 6,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          LOGI("LYNX App get -> getFields");
          if (count < 6) {
            rt.reportJSIException(
                JSINativeException("getFields args count must be 6"));
            return std::optional<Value>();
          }

          TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::getFields");
          auto ptr = native_app_.lock();
          if (!ptr) {
            return piper::Value::undefined();
          }
          tasm::NodeSelectOptions::IdentifierType identifier_type =
              static_cast<tasm::NodeSelectOptions::IdentifierType>(
                  args[0].getNumber());
          std::string identifier = args[1].getString(rt).utf8(rt);
          std::string component_id = args[2].getString(rt).utf8(rt);
          bool first_only = args[3].getBool();
          piper::Array fields = args[4].getObject(rt).getArray(rt);
          std::vector<std::string> fields_native;
          for (size_t i = 0; i < fields.length(rt); i++) {
            fields_native.push_back(
                fields.getValueAtIndex(rt, i)->getString(rt).utf8(rt));
          }

          ApiCallBack callback =
              ptr->CreateCallBack(args[5].getObject(rt).getFunction(rt));
          auto info = tasm::NodeSelectOptions(identifier_type, identifier);
          info.component_only = false;
          info.only_current_component = true;
          info.first_only = first_only;
          tasm::NodeSelectRoot root =
              count >= 7 && args[6].isNumber()
                  ? tasm::NodeSelectRoot::ByUniqueId(args[6].getNumber())
                  : tasm::NodeSelectRoot::ByComponentId(component_id);
          ptr->GetFields(std::move(root), std::move(info),
                         std::move(fields_native), callback);
          return piper::Value::undefined();
        });
  } else if (methodName == "setNativeProps") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "setNativeProps"), 5,
        [this](Runtime& rt, const piper::Value& this_val,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          if (count < 5) {
            rt.reportJSIException(
                JSINativeException("lynx.setNativeProps args count must be 5"));
            return std::optional<Value>();
          }
          auto ptr = native_app_.lock();
          if (!(args[0].isNumber() && args[1].isString() &&
                args[2].isString() && args[3].isBool())) {
            rt.reportJSIException(
                JSINativeException("setNativeProps args type is error"));
            return std::optional<Value>();
          }
          tasm::NodeSelectOptions::IdentifierType identifier_type =
              static_cast<tasm::NodeSelectOptions::IdentifierType>(
                  args[0].getNumber());
          std::string identifier = args[1].getString(rt).utf8(rt);
          std::string component_id = args[2].getString(rt).utf8(rt);
          bool first_only = args[3].getBool();
          auto info = tasm::NodeSelectOptions(identifier_type, identifier);
          info.component_only = false;
          info.only_current_component = true;
          info.first_only = first_only;
          auto lepus_value_opt =
              ptr->ParseJSValueToLepusValue(std::move(args[4]), PAGE_GROUP_ID);
          if (!lepus_value_opt) {
            rt.reportJSIException(JSINativeException(
                "ParseJSValueToLepusValue error in setNativeProps"));
            return std::optional<piper::Value>();
          }
          tasm::NodeSelectRoot root =
              count >= 6 && args[5].isNumber()
                  ? tasm::NodeSelectRoot::ByUniqueId(args[5].getNumber())
                  : tasm::NodeSelectRoot::ByComponentId(component_id);
          ptr->SetNativeProps(std::move(root), std::move(info),
                              std::move(*lepus_value_opt));
          return piper::Value::undefined();
        });
  } else if (methodName == "enableCanvasOptimization") {
    auto native_app = native_app_.lock();
    if (!native_app || native_app->IsDestroying()) {
      return piper::Value::undefined();
    }
    return piper::Value(*rt, native_app->EnableCanvasOptimization());
  } else if (methodName == "callLepusMethod") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "callLepusMethod"), 2,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          // parameter size >= 2
          // [0] method name -> String
          // [1] args -> Object
          // [2] optional JS callback -> Function
          // [3] optional group_id -> String
          LOGI("LYNX PageProxy get -> callLepusMethod" << this);
          if (count < 2) {
            rt.reportJSIException(
                JSINativeException("callLepusMethod arg count must >= 2"));
            return std::optional<piper::Value>();
          }
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "callLepusMethod");
          auto ptr = native_app_.lock();
          if (!ptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          std::string method_name;
          if (args[0].isString()) {
            method_name = args[0].getString(rt).utf8(rt);
          }

          // PAGE_GROUP_ID (-1) is the root component. If you want to avoid
          // overlapping with the function of the root component, use a negative
          // number other than -1, such as -2
          std::string group_id = PAGE_GROUP_ID;
          if (count >= 4 && args[3].isString()) {
            group_id = args[3].getString(rt).utf8(rt);
          }

          auto lepus_value_opt =
              ptr->ParseJSValueToLepusValue(args[1], group_id);
          if (!lepus_value_opt) {
            rt.reportJSIException(JSINativeException(
                "ParseJSValueToLepusValue error in callLepusMethod"));
            return std::optional<piper::Value>();
          }
          if (lepus_value_opt->IsObject()) {
            ApiCallBack callback;
            if (count >= 3 && args[2].isObject() &&
                args[2].getObject(rt).isFunction(rt)) {
              // callback here is a optional argument
              callback =
                  ptr->CreateCallBack(args[2].getObject(rt).getFunction(rt));
            }

            ptr->CallLepusMethod(method_name, std::move(*lepus_value_opt),
                                 std::move(callback));
          }
          return piper::Value::undefined();
        });
  } else if (methodName == "markTiming") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "MarkTiming"), 2,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          // parameter size == 2
          // [0] Timing flag -> String
          // [1] key -> String
          LOGI("LYNX PageProxy get -> MarkTiming" << this);
          if (count != 2) {
            rt.reportJSIException(
                JSINativeException("MarkTiming arg count must == 2"));
            return std::optional<piper::Value>();
          }
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "MarkTiming");
          auto ptr = native_app_.lock();
          if (!ptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          std::string timing_flag;
          if (args[0].isString()) {
            timing_flag = args[0].getString(rt).utf8(rt);
          }

          // PAGE_GROUP_ID (-1) is the root component. If you want to avoid
          // overlapping with the function of the root component, use a negative
          // number other than -1, such as -2
          std::string key;
          if (args[1].isString()) {
            key = args[1].getString(rt).utf8(rt);
          }
          ptr->MarkTiming(timing_flag, key);
          return piper::Value::undefined();
        });
  } else if (methodName == "triggerWorkletFunction") {
    return Function::createFromHostFunction(
        *rt, PropNameID::forAscii(*rt, "triggerWorkletFunction"), 5,
        [this](Runtime& rt, const piper::Value& thisVal,
               const piper::Value* args,
               size_t count) -> std::optional<piper::Value> {
          // parameter size >= 3
          // [0] component_id -> string
          // [1] worklet_module_name -> string
          // [2] method_name -> string
          // [3] args -> Object
          // [4] optional JS callback -> Function

          if (count < 3) {
            rt.reportJSIException(JSINativeException(
                "triggerWorkletFunction arg count must >= 3"));
            return std::optional<piper::Value>();
          }
          TRACE_EVENT(LYNX_TRACE_CATEGORY, "triggerWorkletFunction");
          auto ptr = native_app_.lock();
          if (!ptr || ptr->IsDestroying()) {
            return piper::Value::undefined();
          }

          if (!(args[0].isString() && args[1].isString() &&
                args[2].isString())) {
            rt.reportJSIException(
                JSINativeException("triggerWorkletFunction args error"));
            return piper::Value::undefined();
          }

          std::string component_id = args[0].getString(rt).utf8(rt);
          std::string worklet_module_name = args[1].getString(rt).utf8(rt);
          std::string method_name = args[2].getString(rt).utf8(rt);

          std::optional<lepus::Value> lepus_value_opt = lepus::Value();
          ApiCallBack callback;

          if (count > 3) {
            lepus_value_opt =
                ptr->ParseJSValueToLepusValue(args[3], component_id);
            if (!lepus_value_opt) {
              rt.reportJSIException(JSINativeException(
                  "ParseJSValueToLepusValue error in triggerWorkletFunction"));
              return std::optional<piper::Value>();
            }
          }

          if (count > 4 && args[4].isObject() &&
              args[4].getObject(rt).isFunction(rt)) {
            // callback here is a optional argument
            callback =
                ptr->CreateCallBack(args[4].getObject(rt).getFunction(rt));
          }

          ptr->triggerWorkletFunction(
              std::move(component_id), std::move(worklet_module_name),
              std::move(method_name), std::move(*lepus_value_opt),
              std::move(callback));

          return piper::Value::undefined();
        });
  }

  return piper::Value::undefined();
}

void AppProxy::set(Runtime* rt, const PropNameID& name, const Value& value) {}

std::vector<PropNameID> AppProxy::getPropertyNames(Runtime& rt) {
  std::vector<PropNameID> vec;
  vec.push_back(piper::PropNameID::forUtf8(rt, "id"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "loadScript"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "readScript"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "readDynamicComponentScripts"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "updateData"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "batchedUpdateData"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "setCard"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "setTimeout"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "setInterval"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "clearTimeout"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "clearInterval"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "nativeModuleProxy"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "reportException"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "updateComponentData"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "triggerLepusGlobalEvent"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "triggerComponentEvent"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "selectComponent"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "loadScriptAsync"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "onPiperInvoked"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "getPathInfo"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "invokeUIMethod"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "getFields"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "setNativeProps"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "enableCanvasOptimization"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "callLepusMethod"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "markTiming"));
  vec.push_back(piper::PropNameID::forUtf8(rt, "triggerWorkletFunction"));
  return vec;
}

void App::AsyncRequestVSync(
    uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback) {
  auto rt = rt_.lock();
  if (!rt) {
    return;
  }
  delegate_->AsyncRequestVSync(id, std::move(callback));
}

void App::SetCSSVariable(const std::string& component_id,
                         const std::string& id_selector,
                         const lepus::Value& properties) {
  auto rt = rt_.lock();
  if (!rt) {
    return;
  }
  delegate_->SetCSSVariables(component_id, id_selector, properties);
}

void App::destroy() {
  auto rt = rt_.lock();
  if (rt && js_app_.isObject()) {
    LOGI("App::destroy " << this);

    Scope scope(*rt);

    piper::Object global = rt->global();

    auto destroyCard = global.getPropertyAsFunction(*rt, "destroyCard");
    if (destroyCard) {
      size_t count = 1;
      piper::String id_str = piper::String::createFromUtf8(*rt, app_guid_);
      piper::Value id_value(*rt, id_str);
      const Value args[1] = {std::move(id_value)};
      destroyCard->call(*rt, args, count);
      LOGI("App::destroy end " << this);
    }
  }

  if (jsi_object_wrapper_manager_) {
    jsi_object_wrapper_manager_->DestroyOnJSThread();
  }

  exception_handler_->Destroy();
}

void App::CallDestroyLifetimeFun() {
  state_ = State::kDestroying;

  LOGI(" App::CallDestroyLifetimeFun start " << this);
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CardLifeTimeCallback:onDestroy");
  auto rt = rt_.lock();
  if (rt && js_app_.isObject()) {
    Scope scope(*rt);

    piper::Object global = rt->global();

    auto on_destroy =
        global.getPropertyAsFunction(*rt, "callDestroyLifetimeFun");
    if (on_destroy) {
      size_t count = 1;
      piper::String id_str = piper::String::createFromUtf8(*rt, app_guid_);
      piper::Value id_value(*rt, id_str);
      const Value args[1] = {std::move(id_value)};
      on_destroy->call(*rt, args, count);
    }
  }
  // when destroy, internal js api callbacks, timed task callbacks, and
  // animation frame callbacks are not necessory to handle.
  api_callback_manager_.Destroy();
  timed_task_adapter_.RemoveAllTasks();
  if (lynx_proxy_) {
    lynx_proxy_->Destroy();
  }
  LOGI(" App::CallDestroyLifetimeFun end " << this);
}

void App::loadApp(const std::string& appOriginName,
                  tasm::PackageInstanceDSL dsl,
                  tasm::PackageInstanceBundleModuleMode bundle_module_mode,
                  const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY_VITALS, JS_LOAD_APP);
  app_origin_name_ = appOriginName;
  app_dsl_ = dsl;
  bundle_module_mode_ = bundle_module_mode;
  url_ = url;

  auto rt = rt_.lock();
  if (!rt) {
    handleLoadAppFailed("js runtime is null!");
    return;
  }

  Scope scope(*rt.get());
  state_ = State::kStarted;
  LOGI(" App::loadApp start " << this);
  piper::Object global = rt->global();
  auto load_app_func = global.getPropertyAsFunction(*rt, "loadCard");
  if (!load_app_func) {
    handleLoadAppFailed("LoadApp fail: get loadCard from js global fail!");
    return;
  }

  auto page_proxy = std::make_shared<piper::AppProxy>(rt, shared_from_this());
  piper::Object page_object =
      piper::Object::createFromHostObject(*rt, page_proxy);

  lepus::Value encoded_data = delegate_->GetTasmEncodedData();
  lepus::Value init_data = delegate_->GetNativeInitData();
  lepus::Value init_card_config_data = delegate_->GetNativeCardConfigData();

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
  auto js_encoded_data = valueFromLepus(*rt, encoded_data);
  if (!js_encoded_data) {
    handleLoadAppFailed(
        " App::loadApp error! js_encoded_data valueFromLepus fail. ");
    return;
  }
  auto js_init_data = valueFromLepus(*rt, init_data);
  if (!js_init_data) {
    handleLoadAppFailed(
        " App::loadApp error! js_init_data valueFromLepus fail. ");
    return;
  }
  auto js_init_card_config_data = valueFromLepus(*rt, init_card_config_data);
  if (!js_init_card_config_data) {
    handleLoadAppFailed(
        " App::loadApp error! js_init_card_config_data "
        "valueFromLepus fail. ");
    return;
  }

  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  const char* str_dsl = tasm::GetDSLName(dsl);
  piper::Value card_type(piper::String::createFromUtf8(*rt, str_dsl));

  piper::Object params(*rt);

  // As long as there is a return value of `setProperty` is false, we consider
  // the `loadApp` failed.
  bool is_successful =
      params.setProperty(*rt, "initData", *js_encoded_data) &&
      params.setProperty(*rt, "updateData", *js_init_data) &&
      params.setProperty(*rt, "initConfig", *js_init_card_config_data) &&
      params.setProperty(*rt, "cardType", card_type) &&
      params.setProperty(*rt, "appGUID", getAppGUID()) &&
      params.setProperty(
          *rt, "bundleSupportLoadScript",
          bundle_module_mode ==
              tasm::PackageInstanceBundleModuleMode::RETURN_BY_FUNCTION_MODE);
  if (!is_successful) {
    handleLoadAppFailed("LoadApp fail: setProperty fail!");
    return;
  }

  lynx_proxy_ = std::make_shared<piper::LynxProxy>(rt, shared_from_this());
  piper::Object lynx_object =
      piper::Object::createFromHostObject(*rt, lynx_proxy_);

  piper::Value pageValue(*rt, page_object);
  piper::Value paramValue(*rt, params);
  piper::Value lynxValue(*rt, lynx_object);
  const Value args[3] = {std::move(pageValue), std::move(paramValue),
                         std::move(lynxValue)};
  size_t count = 3;
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
  auto ret = load_app_func->call(*rt, args, count);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  if (!ret) {
    handleLoadAppFailed("LoadApp fail: call load_app_func fail!");
    return;
  }
  LOGI(" App::loadApp end " << this);
}

void App::handleLoadAppFailed(std::string error_msg) {
  state_ = State::kAppLoadFailed;
  auto rt = rt_.lock();
  if (rt) {
    rt->reportJSIException(JSINativeException(error_msg));
  }
}

void App::OnDynamicJSSourcePrepared(const std::string& component_url) {
  auto rt = rt_.lock();
  if (!rt) {
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "loadDynamicComponent");
  Scope scope(*rt.get());
  piper::Object global = rt->global();
  auto load_app_func =
      global.getPropertyAsFunction(*rt, "loadDynamicComponent");
  if (!load_app_func) {
    return;
  }

  auto js_app = js_app_.asObject(*rt);
  if (!js_app) {
    return;
  }
  piper::String url = piper::String::createFromUtf8(*rt, component_url);
  const Value args[2] = {std::move(*js_app), std::move(url)};

  size_t count = 2;
  load_app_func->call(*rt, args, count);
}

void App::LoadScriptAsync(const std::string& url, ApiCallBack callback) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "loadExternalJSAsync");
  LOGI("App::LoadScriptAsync " << url << " " << this);
  delegate_->LoadScriptAsync(url, callback);
}

void App::EvaluateScript(const std::string& url, std::string script,
                         ApiCallBack callback) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "evaluateExternalJS");
  LOGI("App::EvaluateScript:" << url);

  auto rt = rt_.lock();
  if (rt) {
    Scope scope(*rt);
    piper::Value js_error_value;
    auto prepared_script = rt->prepareJavaScript(
        std::make_shared<StringBuffer>(std::move(script)), url);
    if (!rt->evaluatePreparedJavaScript(prepared_script)) {
      js_error_value = piper::Value(piper::String::createFromUtf8(
          *rt, "load external js script failed! url: " + url));
      rt->reportJSIException(
          JSINativeException("load external js script failed! url: " + url));
    }

    api_callback_manager_.InvokeWithValue(rt.get(), callback.id(),
                                          std::move(js_error_value));
  }
}

void App::onNativeAppReady() {
  LOGI(" App::onNativeAppReady " << this);
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CardLifeTimeCallback:onReady()");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);

    Object js_app = js_app_.getObject(*rt);
    auto onNativeAppReady =
        js_app.getPropertyAsFunction(*rt, "onNativeAppReady");
    if (!onNativeAppReady) {
      return;
    }

    size_t count = 0;
    {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "RunningInJS");
      onNativeAppReady->callWithThis(*rt, js_app, nullptr, count);
    }
  }
}

void App::onAppEnterBackground() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CardLifeTimeCallback:onHide()");
  if (lynx_proxy_) {
    lynx_proxy_->PauseAnimationFrame();
  }

  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    LOGI("App::onAppEnterBackground " << this);
    Scope scope(*rt);

    Object js_app = js_app_.getObject(*rt);
    auto onAppEnterBackground =
        js_app.getPropertyAsFunction(*rt, "onAppEnterBackground");
    if (!onAppEnterBackground) {
      return;
    }

    size_t count = 0;
    {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "RunningInJS");
      onAppEnterBackground->callWithThis(*rt, js_app, nullptr, count);
    }
  }
}

void App::onAppEnterForeground() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CardLifeTimeCallback:onShow()");
  if (lynx_proxy_) {
    lynx_proxy_->ResumeAnimationFrame();
  }

  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    LOGI("App::onAppEnterForeground " << this);
    Scope scope(*rt);

    Object js_app = js_app_.getObject(*rt);
    auto onAppEnterForeground =
        js_app.getPropertyAsFunction(*rt, "onAppEnterForeground");
    if (!onAppEnterForeground) {
      return;
    }
    size_t count = 0;
    {
      TRACE_EVENT(LYNX_TRACE_CATEGORY, "RunningInJS");
      onAppEnterForeground->callWithThis(*rt, js_app, nullptr, count);
    }
  }
}

void App::onAppFirstScreen() {
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);

    Object js_app = js_app_.getObject(*rt);
    auto on_app_first_screen =
        js_app.getPropertyAsFunction(*rt, "onAppFirstScreen");
    if (!on_app_first_screen) {
      return;
    }

    size_t count = 0;
    on_app_first_screen->callWithThis(*rt, js_app, nullptr, count);
  }
}

void App::onAppReload(const lepus::Value& init_data) {
  auto rt = rt_.lock();
  if (rt && js_app_.isObject()) {
    Scope scope(*rt);
    auto js_app = js_app_.getObject(*rt);

    auto on_app_reload = js_app.getPropertyAsFunction(*rt, "onAppReload");
    if (!on_app_reload) {
      return;
    }
    auto js_init_data =
        valueFromLepus(*rt, init_data, jsi_object_wrapper_manager_.get());
    if (!js_init_data) {
      return;
    }

    size_t count = 1;
    const Value args[1] = {std::move(*js_init_data)};
    on_app_reload->callWithThis(*rt, js_app, args, count);
  }
}

void App::OnLifecycleEvent(const lepus::Value& args) {
  auto rt = rt_.lock();
  if (rt && js_app_.isObject()) {
    Scope scope(*rt);
    auto js_app = js_app_.getObject(*rt);
    auto on_lifecycle_event =
        js_app.getPropertyAsFunction(*rt, "OnLifecycleEvent");
    if (!on_lifecycle_event) {
      return;
    }
    auto js_args = valueFromLepus(*rt, args, jsi_object_wrapper_manager_.get());
    if (!js_args) {
      return;
    }

    size_t count = 1;
    const Value args[1] = {std::move(*js_args)};
    on_lifecycle_event->callWithThis(*rt, js_app, args, count);
  }
}

void App::CallJSFunctionInLepusEvent(const int64_t component_id,
                                     const std::string& name,
                                     const lepus::Value& params) {
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "CallbackToLepusEvent");
  LOGI("App::CallJSFunctionInLepusEvent,func name: " << name << " " << this);
  std::optional<Value> res;
  if (component_id == 0) {
    res = SendPageEvent("", name, params);
  } else {
    res = publicComponentEvent(std::to_string(component_id), name, params);
  }
  constexpr const static char* kEventCallbackId = "callbackId";

  // if need callback(in worklet), it need to callback to lepus event
  // function
  int32_t callbackId = params.Table().Get()->GetValue(kEventCallbackId).Int32();
  // if callback id is negative, means no need to callback
  if (callbackId >= 0) {
    if (res.has_value()) {
      auto rt = rt_.lock();
      auto data_lepusValue = ParseJSValueToLepusValue(*res, PAGE_GROUP_ID);
      if (data_lepusValue.has_value()) {
        delegate_->InvokeLepusComponentCallback(
            callbackId, tasm::DEFAULT_ENTRY_NAME, *data_lepusValue);
      }
    } else {
      // if not have return value, it also need to callback,
      // because the callback is stored in set wait for callback to remove
      delegate_->InvokeLepusComponentCallback(
          callbackId, tasm::DEFAULT_ENTRY_NAME, lepus::Value());
    }
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
}

std::optional<Value> App::SendPageEvent(const std::string& page_name,
                                        const std::string& handler,
                                        const lepus::Value& info) {
  LOGI("App::SendPageEvent,handler: " << handler << " " << this);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
                [&](lynx::perfetto::EventContext ctx) {
                  ctx.event()->set_name("PageEvent:" + handler);
                });
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto publishEvent = js_app.getPropertyAsFunction(*rt, "publishEvent");
    if (!publishEvent) {
      return std::nullopt;
    }

    piper::String strName = piper::String::createFromUtf8(*rt, handler);
    piper::Value jsName(*rt, strName);
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto data = valueFromLepus(*rt, info, jsi_object_wrapper_manager_.get());
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    if (!data) {
      return std::nullopt;
    }
    piper::Value id(0);

    const Value args[3] = {std::move(jsName), std::move(*data), std::move(id)};
    size_t count = 3;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    auto res = publishEvent->callWithThis(*rt, thisObj, args, count);
    // get js function return value
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    return res;
  }
  return std::nullopt;
}

void App::SendGlobalEvent(const std::string& name,
                          const lepus::Value& arguments) {
  constexpr char kGlobalEventModuleName[] = "GlobalEventEmitter";
  constexpr char kGlobalEventMethodName[] = "emit";
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);
    auto param = Array::createWithLength(*rt, 1);
    if (!param) {
      return;
    }
    auto arg = Array::createWithLength(*rt, 2);
    if (!arg) {
      return;
    }
    auto element =
        valueFromLepus(*rt, arguments, jsi_object_wrapper_manager_.get());
    if (!element) {
      return;
    }
    // As long as there is a return value of `setValueAtIndex` is false, we
    // consider the `SendGlobalEvent` failed.
    bool is_successful = (*param).setValueAtIndex(*rt, 0, *element) &&
                         (*arg).setValueAtIndex(*rt, 0, name) &&
                         (*arg).setValueAtIndex(*rt, 1, std::move(*param));
    if (!is_successful) {
      return;
    }
    CallFunction(kGlobalEventModuleName, kGlobalEventMethodName,
                 std::move(*arg));
  }
}

void App::SetupSsrJsEnv() {
  constexpr char kCreateGlobalEventEmitter[] = "__createEventEmitter";
  auto rt = rt_.lock();
  if (rt) {
    Scope scope(*rt);
    piper::Object global = rt->global();
    auto create_event_emitterFunc =
        global.getPropertyAsFunction(*rt, kCreateGlobalEventEmitter);
    if (!create_event_emitterFunc) {
      rt->reportJSIException(
          JSINativeException("SSR: exception has happened in getting function "
                             "__createEventEmitter"));
      return;
    }
    // Create SSR global Event Emitter
    auto ret = create_event_emitterFunc->call(*rt, nullptr, 0);
    if (ret) {
      ssr_global_event_emitter_ = piper::Value(*rt, *ret);
    } else {
      rt->reportJSIException(JSINativeException(
          "SSR: exception has happened in creating ssr global event emit"));
    }
  }
}

// SSR script be like:
// (function(){ return {func : function(SsrGlobalEventEmitter,SsrNativeModules){
//         //Captured Scripts
//  }}})();
void App::LoadSsrScript(const std::string& script) {
  LOGI("LoadSsrScript: " << script);
  auto rt = rt_.lock();
  if (rt) {
    Scope scope(*rt);
    auto script_result = rt->evaluateJavaScript(
        std::make_shared<StringBuffer>(std::move(script)), "ssr-script.js");
    if (!script_result) {
      rt->reportJSIException(
          JSINativeException("SSR: exception has happened in getting "
                             "ssr-script.js returned object"));
      return;
    }

    auto ssr_returned_object = (*script_result).asObject(*rt);
    auto ssr_returned_function =
        ssr_returned_object->getPropertyAsFunction(*rt, "func");

    if (!ssr_returned_function) {
      rt->reportJSIException(
          JSINativeException("SSR: exception has happened in getting "
                             "ssr-script.js returned function"));
      return;
    }

    size_t count = 2;
    piper::Value global_event_emit(*rt, ssr_global_event_emitter_);
    piper::Value native_modules(*rt, nativeModuleProxy());
    const Value args[2] = {std::move(global_event_emit),
                           std::move(native_modules)};

    auto ret = ssr_returned_function->call(*rt, args, count);
    if (!ret) {
      rt->reportJSIException(
          JSINativeException("SSR: exception has happened in calling "
                             "ssr-script.js returned function"));
      return;
    }
  }
}

void App::SendSsrGlobalEvent(const std::string& name,
                             const lepus::Value& arguments) {
  constexpr char kSsrGlobalEventEmitterFun[] = "emit";
  auto rt = rt_.lock();
  if (rt) {
    Scope scope(*rt);

    if (ssr_global_event_emitter_.isNull()) {
      LOGE(
          "SSR: exception has happened in getting native "
          "ssr_global_event_emitter_ "
          << name << "  " << this);
      return;
    }

    auto ssr_event_emitter = ssr_global_event_emitter_.asObject(*rt);

    auto emit_func = ssr_event_emitter->getPropertyAsFunction(
        *rt, kSsrGlobalEventEmitterFun);
    if (!emit_func) {
      LOGE("SSR: exception has happened in getting SSR global event emitter"
           << name << "  " << this);
      return;
    }

    auto piper_arguments =
        valueFromLepus(*rt, arguments, jsi_object_wrapper_manager_.get());
    if (!piper_arguments) {
      LOGE("SSR: exception has happened in parsing ssr global event arguments"
           << name << "  " << this);
      return;
    }

    piper::Value event_name(piper::String::createFromUtf8(*rt, name));
    const Value args[2] = {std::move(event_name), std::move(*piper_arguments)};
    size_t count = 2;

    const piper::Object& ssr_event_emitter_obj = *ssr_event_emitter;

    auto ret = emit_func->callWithThis(*rt, ssr_event_emitter_obj, args, count);
    if (!ret) {
      LOGE("SSR: exception has happened in emitting ssr global event:"
           << name << "  " << this);
      return;
    }
    LOGI("SSR: end emit ssr global event:" << name << "  " << this);
  }
}

void App::CallFunction(const std::string& module_id,
                       const std::string& method_id,
                       const piper::Array& arguments) {
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    std::string first_arg_str;
    std::optional<piper::Value> first_arg_opt;
    if (arguments.length(*rt) > 0) {
      first_arg_opt = arguments.getValueAtIndex(*rt, 0);
    }
    if (first_arg_opt && first_arg_opt->isString()) {
      first_arg_str = first_arg_opt->getString(*rt).utf8(*rt);
    }
    LOGI("call jsmodule:" << module_id << "." << method_id << "."
                          << first_arg_str << " " << this);

    auto publishEvent = js_app.getPropertyAsFunction(*rt, "callFunction");
    if (!publishEvent) {
      return;
    }

    piper::String str_module = piper::String::createFromUtf8(*rt, module_id);
    piper::Value jsName(*rt, str_module);
    piper::String str_method = piper::String::createFromUtf8(*rt, method_id);
    piper::Value jsMethod(*rt, str_method);

    piper::Value args[3];
    args[0] = std::move(jsName);
    args[1] = std::move(jsMethod);
    piper::Value method_args(*rt, arguments);
    args[2] = std::move(method_args);
    const piper::Object& thisObj = js_app;
    auto ret = publishEvent->callWithThis(*rt, thisObj, args, 3);
    if (!ret) {
      LOGI("exception has happened in call jsmodule. module:"
           << module_id << " method:" << method_id << this);
      return;
    }
    LOGV("end  call jsmodule. module:" << module_id << " method:" << method_id
                                       << "." << first_arg_str << " " << this);
  }
}

void App::InvokeApiCallBack(ApiCallBack id) {
  api_callback_manager_.Invoke(rt_.lock().get(), id);
}

void App::InvokeApiCallBackWithValue(ApiCallBack id,
                                     const lepus::Value& value) {
  api_callback_manager_.InvokeWithValue(rt_.lock().get(), id, value);
}

void App::InvokeApiCallBackWithValue(ApiCallBack id, piper::Value value) {
  api_callback_manager_.InvokeWithValue(rt_.lock().get(), id, std::move(value));
}

ApiCallBack App::CreateCallBack(piper::Function func) {
  return api_callback_manager_.createCallbackImpl(std::move(func));
}

void App::NotifyUpdatePageData() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::updateCardData");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    auto updated_card_data = delegate_->FetchUpdatedCardData();

    // for react, don't need update data, react use "onReactCardRender"
    if (app_dsl_ == tasm::PackageInstanceDSL::REACT) {
      return;
    }

    for (const auto& data : updated_card_data) {
      Scope scope(*rt);
      LOGI("App::updateCardData" << this);

      Object js_app = js_app_.getObject(*rt);
      auto publishEvent = js_app.getPropertyAsFunction(*rt, "updateCardData");
      if (!publishEvent) {
        continue;
      }
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
      auto jsValue = valueFromLepus(*rt, data.GetValue(),
                                    jsi_object_wrapper_manager_.get());
      if (!jsValue) {
        return;
      }
      auto op_type =
          valueFromLepus(*rt, lepus::Value(static_cast<int>(data.GetType())),
                         jsi_object_wrapper_manager_.get());
      if (!op_type) {
        return;
      }
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
      const Value args[2] = {std::move(*jsValue), std::move(*op_type)};
      size_t count = 2;
      const piper::Object& thisObj = js_app;
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
      publishEvent->callWithThis(*rt, thisObj, args, count);
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    }  // end for
  }
}

void App::NotifyUpdateCardConfigData() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::NotifyJSUpdateCardConfigData");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);
    LOGI("App::updateCardConfigData" << this);

    Object js_app = js_app_.getObject(*rt);

    auto publishEvent = js_app.getPropertyAsFunction(*rt, "processCardConfig");
    if (!publishEvent) {
      return;
    }
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");

    lepus::Value card_config_data = delegate_->GetNativeCardConfigData();
    auto jsValue = valueFromLepus(*rt, card_config_data,
                                  jsi_object_wrapper_manager_.get());
    if (!jsValue) {
      return;
    }
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    const Value args[1] = {std::move(*jsValue)};
    size_t count = 1;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    publishEvent->callWithThis(*rt, thisObj, args, count);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  }
}

void App::NotifyGlobalPropsUpdated(const lepus::Value& props) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "App::NotifyGlobalPropsUpdated");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);
    LOGI("App:NotifyGlobalPropsUpdated: " << this);
    auto js_app = js_app_.getObject(*rt);
    auto updateGlobalPropsFunction =
        js_app.getPropertyAsFunction(*rt, "updateGlobalProps");
    if (!updateGlobalPropsFunction) {
      return;
    }
    auto jsValue =
        valueFromLepus(*rt, props, jsi_object_wrapper_manager_.get());
    if (!jsValue) {
      return;
    }

    size_t count = 1;
    const Value args[1] = {std::move(*jsValue)};
    const piper::Object& thisObj = js_app;
    updateGlobalPropsFunction->callWithThis(*rt, thisObj, args, count);
  }
}

void App::OnAppJSError(const piper::JSIException& exception) {
  const std::string& msg = exception.message();
  LOGE("app::onAppJSError:" << msg);
  auto rt = rt_.lock();
  if (rt && js_app_.isObject()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onAppError = js_app.getPropertyAsFunction(*rt, "onAppError");
    if (!onAppError) {
      return;
    }

    piper::String msg_str = piper::String::createFromUtf8(*rt, msg);

    piper::Value js_message(*rt, msg_str);
    auto js_error = piper::Object::createFromHostObject(
        *rt, std::make_shared<LynxError>(exception));

    // The first argument is used for backward compatibility
    // since appbrand will use this API and we do not want to break them.
    const Value args[2] = {std::move(js_message), std::move(js_error)};
    onAppError->callWithThis(*rt, js_app, args, 2);
  } else {
    LOGE("reportJSException when js_app_ is not ready: " << msg);
    reportException(msg, "", LYNX_ERROR_CODE_JAVASCRIPT);
  }
}

void App::setJsAppObj(piper::Object&& obj) {
  auto rt = rt_.lock();
  if (!rt) {
    return;
  }

  js_app_ = piper::Value(*rt, obj);
  // check if there has cached data changes
  NotifyUpdatePageData();
}

void App::appDataChange(lepus_value&& data, ApiCallBack callback,
                        runtime::UpdateDataType update_data_type) {
  runtime::UpdateDataTask task(true, PAGE_GROUP_ID, std::move(data), callback,
                               std::move(update_data_type));
  delegate_->UpdateDataByJS(std::move(task));
}

bool App::batchedUpdateData(const piper::Value& args) {
  auto rt = rt_.lock();
  if (!rt || !args.isObject()) {
    return false;
  }
  uint64_t update_task_id = lynx::base::tracing::GetFlowId();
  TRACE_EVENT_FLOW_BEGIN0(LYNX_TRACE_CATEGORY, "batchedUpdateData",
                          update_task_id);
  auto data_obj = args.asObject(*rt);
  if (!data_obj) {
    return false;
  }
  auto data_ary = data_obj->asArray(*rt);
  if (!data_ary) {
    return false;
  }

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY,
                    "batchedUpdateData:JSValueToLepusValue");
  std::vector<runtime::UpdateDataTask> tasks;
  auto size = data_ary->size(*rt);
  if (!size) {
    return false;
  }
  for (size_t i = 0; i < *size; i++) {
    auto val = data_ary->getValueAtIndex(*rt, i);
    if (!val) {
      return false;
    }
    auto item = val->asObject(*rt);
    if (!item) {
      return false;
    }

    auto type_opt = item->getProperty(*rt, "type");
    if (!type_opt) {
      return false;
    }
    auto type = type_opt->asString(*rt);
    if (!type) {
      return false;
    }

    ApiCallBack callback;
    if (item->hasProperty(*rt, "callback")) {
      auto cb_opt = item->getProperty(*rt, "callback");
      if (!cb_opt) {
        return false;
      }
      auto cb = cb_opt->asObject(*rt);
      if (!cb || !cb->isFunction(*rt)) {
        return false;
      }
      callback = CreateCallBack(cb->getFunction(*rt));
    }

    bool is_card = (type->utf8(*rt) == "card");
    std::string component_id = PAGE_GROUP_ID;
    if (!is_card) {
      auto comp_id_opt = item->getProperty(*rt, "componentId");
      if (!comp_id_opt) {
        return false;
      }
      auto comp_id = comp_id_opt->asString(*rt);
      if (!comp_id) {
        return false;
      }
      component_id = comp_id->utf8(*rt);
    }
    auto data_opt = item->getProperty(*rt, "data");
    if (!data_opt) {
      return false;
    }
    auto data_lepusValue = ParseJSValueToLepusValue(*data_opt, component_id);
    if (!data_lepusValue) {
      rt->reportJSIException(JSINativeException(
          "ParseJSValueToLepusValue error in batchedUpdateData"));
      return false;
    }
    runtime::UpdateDataType update_data_type;
    auto js_update_data_type_opt = item->getProperty(*rt, "updateDataType");
    if (js_update_data_type_opt && js_update_data_type_opt->isNumber()) {
      update_data_type =
          runtime::UpdateDataType(js_update_data_type_opt->getNumber());
    }
    std::string timing_flag_string = tasm::GetTimingFlag(*data_lepusValue);
    if (!timing_flag_string.empty()) {
      tasm::TimingCollector::Scope<runtime::TemplateDelegate> scope(
          delegate_, timing_flag_string);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_SET_STATE_TRIGGER);
    }
    tasks.emplace_back(is_card, component_id, *data_lepusValue, callback,
                       std::move(update_data_type));
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "updateData:UpdateDataToTASM",
                    [&](lynx::perfetto::EventContext ctx) {
                      std::stringstream ss;
                      for (runtime::UpdateDataTask& task : tasks) {
                        ss << task.callback_.id() << ",";
                      }
                      auto* debug = ctx.event()->add_debug_annotations();
                      debug->set_name("CallbackID");
                      debug->set_string_value(ss.str());
                    });
  delegate_->UpdateBatchedDataByJS(std::move(tasks), update_task_id);
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  return true;
}

piper::Value App::loadScript(const std::string entry_name,
                             const std::string& url) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "loadExternalJS");

  LOGI("loadscript:" << url);

  auto rt = rt_.lock();
  if (rt) {
    std::string source_url;
    // is the js file in lynx bundle?
    bool is_lynx_assets_source =
        base::BeginsWith(url, runtime::kLynxAssetsScheme);

    if (is_lynx_assets_source || base::BeginsWith(url, "http") ||
        url.front() == '/') {
      source_url = url;
    } else {
      source_url = "/" + url;
    }
    std::string throwing_source;
    if (is_lynx_assets_source) {
      auto& lynx_js_assets_ = GetJSAssetsMap();
      std::string& cache = lynx_js_assets_[source_url];
      // cache is empty means there are no cache before
      if (cache.empty()) {
        cache = delegate_->GetLynxJSAsset(source_url);
      }
      throwing_source = cache;
    } else {
      throwing_source = delegate_->GetJSSource(entry_name, source_url);
    }

    if (!entry_name.empty() && entry_name != tasm::DEFAULT_ENTRY_NAME) {
      source_url = GenerateDynamicComponentSourceUrl(entry_name, source_url);
    }
    bool is_app_service_js =
        (source_url.compare(runtime::kAppServiceJSName) == 0);

    // after this line, 'throwing_source' becomes a empty string
    auto prep = rt->prepareJavaScript(
        std::make_shared<StringBuffer>(std::move(throwing_source)), source_url);
    auto ret = rt->evaluatePreparedJavaScript(prep);
    if (ret) {
      if (is_app_service_js) {
        state_ = State::kAppLoaded;
      }
      return std::move(*ret);
    } else {
      if (is_app_service_js) {
        state_ = State::kAppLoadFailed;
      }
      rt->reportJSIException(
          JSINativeException("load js script failed! url: " + source_url));
    }
  }
  return piper::Value::undefined();
}

std::string App::GenerateDynamicComponentSourceUrl(
    const std::string& entry_name, const std::string& source_url) {
  std::string dynamic_component_source_url = runtime::kDynamicComponentJSPrefix;
  dynamic_component_source_url.append(entry_name);
  dynamic_component_source_url.append("/");
  dynamic_component_source_url.append(source_url);
  return dynamic_component_source_url;
}

piper::Value App::readScript(const std::string entry_name,
                             const std::string& url) {
  LOGI("readScript:" << url);

  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }

  std::string source_url = (url.front() == '/') ? url : "/" + url;
  std::string throwing_source = delegate_->GetJSSource(entry_name, source_url);
  throwing_source.append("\n\n\n\n//# sourceURL=file:///").append(url);

  return piper::Value(piper::String::createFromUtf8(*rt, throwing_source));
}

piper::Value App::setTimeout(piper::Function func, int time) {
  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }

  return timed_task_adapter_.SetTimeout(std::move(func), time);
}

piper::Value App::setInterval(piper::Function func, int time) {
  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }

  return timed_task_adapter_.SetInterval(std::move(func), time);
}

void App::clearTimeout(double task) {
  timed_task_adapter_.RemoveTask(static_cast<uint32_t>(task));
}

piper::Value App::nativeModuleProxy() {
  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }
  return piper::Value(*rt, nativeModuleProxy_);
}

std::optional<piper::Value> App::getInitGlobalProps() {
  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }
  auto props = valueFromLepus(*rt, delegate_->GetInitGlobalProps());
  if (!props) {
    rt->reportJSIException(JSINativeException(
        "getInitGlobalProps fail! exception happen in valueFromLepus."));
    return std::optional<piper::Value>();
  }
  return std::move(*props);
}

piper::Value App::getI18nResource() {
  auto rt = rt_.lock();
  if (!rt) {
    return piper::Value::undefined();
  }
  piper::Value res(piper::String::createFromUtf8(*rt, i18_resource_));
  return res;
}

void App::getContextDataAsync(const std::string& component_id,
                              const std::string& key, ApiCallBack callback) {
  auto rt = rt_.lock();
  if (!rt) {
    return;
  }
  delegate_->GetComponentContextDataAsync(component_id, key, callback);
}

void App::QueryComponent(const std::string& url, ApiCallBack callback) {
  if (delegate_->LoadDynamicComponentFromJS(url, callback)) {
    // the dynamic component is already loaded, just reuse the TemplateEntry.
    lepus::Value callback_value =
        tasm::RadonDynamicComponent::ConstructSuccessLoadInfo(url, true);
    InvokeApiCallBackWithValue(callback, callback_value);
    return;
  }
}

void App::OnIntersectionObserverEvent(int32_t observer_id, int32_t callback_id,
                                      piper::Value data) {
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onIntersectionObserverEvent =
        js_app.getPropertyAsFunction(*rt, "onIntersectionObserverEvent");
    if (!onIntersectionObserverEvent) {
      return;
    }

    piper::Value args[3];
    args[0] = observer_id;
    args[1] = callback_id;
    args[2] = std::move(data);
    const piper::Object& thisObj = js_app;
    onIntersectionObserverEvent->callWithThis(*rt, thisObj, args, 3);
  }
}

void App::onComponentActivity(const std::string& action,
                              const std::string& component_id,
                              const std::string& parent_component_id,
                              const std::string& path,
                              const std::string& entryName,
                              const lepus::Value& data) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("ComponentLifeTimeCallback:" + action);
              });
  LOGI(" onComponentActivity "
       << component_id << " action:" << action << "  path:" << path
       << " entryName:" << entryName << " parent: " << parent_component_id
       << this);

  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onComponentActivity =
        js_app.getPropertyAsFunction(*rt, "onComponentActivity");
    if (!onComponentActivity) {
      return;
    }

    piper::Value js_action(piper::String::createFromUtf8(*rt, action));
    piper::Value js_id(piper::String::createFromUtf8(*rt, component_id));
    piper::Value js_path(piper::String::createFromUtf8(*rt, path));
    piper::Value param = piper::Value::undefined();
    if (action == tasm::BaseComponent::kCreated) {
      piper::Object data_obj = piper::Object(*rt);

      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
      auto jsValue =
          valueFromLepus(*rt, data, jsi_object_wrapper_manager_.get());
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
      if (!jsValue) {
        return;
      }
      data_obj.setProperty(*rt, "initData", *jsValue);
      data_obj.setProperty(*rt, "entryName", entryName);
      piper::Value jsParentID(
          piper::String::createFromUtf8(*rt, parent_component_id));
      data_obj.setProperty(*rt, "parentId", jsParentID);
      param = piper::Value(data_obj);
    }

    const Value args[4] = {std::move(js_action), std::move(js_id),
                           std::move(js_path), std::move(param)};
    size_t count = 4;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    onComponentActivity->callWithThis(*rt, thisObj, args, count);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

    if (action == tasm::BaseComponent::kDetached) {
      // When a component detached, call ForceGcOnJSThread to clear dirty
      // JSIObjectWrapper. This may not only clear JSIObjectWrapper created by
      // this component, but all of the dirty JSIObjectWrapper can be cleared.
      //
      // There is a mutex inside ForceGcOnJSThread, which may cause main thread
      // waiting for ForceGcOnJSThread.
      // see: #8680
      jsi_object_wrapper_manager_->ForceGcOnJSThread();
    }
  }
}

std::optional<Value> App::publicComponentEvent(const std::string& component_id,
                                               const std::string& handler,
                                               const lepus::Value& info) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr,
              [&](lynx::perfetto::EventContext ctx) {
                ctx.event()->set_name("ComponentEvent:" + handler);
              });
  LOGI(" publicComponentEvent " << component_id << " " << handler << " "
                                << this);

  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto publicComponentEvent =
        js_app.getPropertyAsFunction(*rt, "publicComponentEvent");
    if (!publicComponentEvent) {
      return std::nullopt;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, component_id));
    piper::Value js_handler(piper::String::createFromUtf8(*rt, handler));
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto data = valueFromLepus(*rt, info, jsi_object_wrapper_manager_.get());
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    if (!data) {
      return std::nullopt;
    }
    const Value args[3] = {std::move(js_id), std::move(js_handler),
                           std::move(*data)};
    size_t count = 3;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    auto res = publicComponentEvent->callWithThis(*rt, thisObj, args, count);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    return res;
  }
  return std::nullopt;
}

void App::onComponentPropertiesChanged(const std::string& component_id,
                                       const lepus::Value& properties) {
  LOGI(" OnComponentPropertiesChanged " << component_id << " " << this);
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnComponentPropertiesChanged");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onComponentPropertiesChanged =
        js_app.getPropertyAsFunction(*rt, "onComponentPropertiesChanged");
    if (!onComponentPropertiesChanged) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, component_id));
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto js_pro =
        valueFromLepus(*rt, properties, jsi_object_wrapper_manager_.get());
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    if (!js_pro) {
      return;
    }
    const Value args[2] = {std::move(js_id), std::move(*js_pro)};
    size_t count = 2;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    onComponentPropertiesChanged->callWithThis(*rt, thisObj, args, count);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  }
}

void App::OnComponentDataSetChanged(const std::string& component_id,
                                    const lepus::Value& data_set) {
  LOGI(" OnComponentDataSetChanged " << component_id << " " << this);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onComponentDatasetChanged =
        js_app.getPropertyAsFunction(*rt, "onComponentDatasetChanged");
    if (!onComponentDatasetChanged) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, component_id));
    auto js_data_set =
        valueFromLepus(*rt, data_set, jsi_object_wrapper_manager_.get());
    if (!js_data_set) {
      return;
    }
    const Value args[2] = {std::move(js_id), std::move(*js_data_set)};
    size_t count = 2;
    const piper::Object& thisObj = js_app;
    onComponentDatasetChanged->callWithThis(*rt, thisObj, args, count);
  }
}

void App::OnComponentSelectorChanged(const std::string& component_id,
                                     const lepus::Value& instance) {
  LOGI(" onComponentInstanceChanged " << component_id << " " << this);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onComponentInstanceChanged =
        js_app.getPropertyAsFunction(*rt, "onComponentInstanceChanged");
    if (!onComponentInstanceChanged) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, component_id));
    auto js_selector =
        valueFromLepus(*rt, instance, jsi_object_wrapper_manager_.get());
    if (!js_selector) {
      return;
    }
    const Value args[2] = {std::move(js_id), std::move(*js_selector)};
    size_t count = 2;
    const piper::Object& thisObj = js_app;
    onComponentInstanceChanged->callWithThis(*rt, thisObj, args, count);
  }
}

void App::triggerComponentEvent(const std::string& event_name,
                                lepus_value&& msg) {
  LOGI(" triggerComponentEvent " << event_name << " " << this);
  delegate_->TriggerComponentEvent(event_name, std::move(msg));
}

void App::triggerLepusGlobalEvent(const std::string& event_name,
                                  lepus_value&& msg) {
  LOGI(" triggerLepusGlobalEvent: " << event_name << " " << this);
  delegate_->TriggerLepusGlobalEvent(event_name, std::move(msg));
}

void App::triggerWorkletFunction(std::string component_id,
                                 std::string worklet_module_name,
                                 std::string method_name, lepus::Value args,
                                 ApiCallBack callback) {
  LOGI(" triggerWorkletFunction: " << method_name << " " << this);
  delegate_->TriggerWorkletFunction(
      std::move(component_id), std::move(worklet_module_name),
      std::move(method_name), std::move(args), std::move(callback));
}

void App::updateComponentData(const std::string& component_id,
                              lepus_value&& data, ApiCallBack callback,
                              runtime::UpdateDataType update_data_type) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_EVENT_JS_UPDATE_COMPONENT_DATA);
  LOGI(" updateComponentData " << component_id << " " << this);
  runtime::UpdateDataTask task(false, component_id, std::move(data), callback,
                               std::move(update_data_type));
  delegate_->UpdateComponentData(std::move(task));
}

void App::selectComponent(const std::string& component_id,
                          const std::string& id_selector, const bool single,
                          ApiCallBack callBack) {
  LOGI(" selectComponent " << component_id << " " << this);
  delegate_->SelectComponent(component_id, id_selector, single, callBack);
}

void App::InvokeUIMethod(tasm::NodeSelectRoot root,
                         tasm::NodeSelectOptions options, std::string method,
                         const piper::Value* params, ApiCallBack callback) {
  LOGI(" InvokeUIMethod with root: "
       << root.ToPrettyString() << ", node: " << options.ToString()
       << ", method: " << method << ", App: " << this);
  auto rt = rt_.lock();
  if (rt) {
    const piper::Object& obj = params->getObject(*rt);
    auto params_platform_value = PlatformValue::FromPiperJsObject(&obj, rt_);
    delegate_->InvokeUIMethod(std::move(root), std::move(options),
                              std::move(method),
                              std::move(params_platform_value), callback);
  }
}

void App::GetPathInfo(tasm::NodeSelectRoot root,
                      tasm::NodeSelectOptions options, ApiCallBack callBack) {
  LOGI(" GetPathInfo with root: " << root.ToPrettyString() << ", node: "
                                  << options.ToString() << ", App: " << this);
  delegate_->GetPathInfo(std::move(root), std::move(options), callBack);
}

void App::GetFields(tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
                    std::vector<std::string> fields, ApiCallBack call_back) {
  LOGI(" GetFields with root: " << root.ToPrettyString() << ", node: "
                                << options.ToString() << ", App: " << this);
  delegate_->GetFields(std::move(root), std::move(options), std::move(fields),
                       call_back);
}

void App::SetNativeProps(tasm::NodeSelectRoot root,
                         tasm::NodeSelectOptions options,
                         lepus::Value native_props) {
  LOGI(" SetNativeProps with root: " << root.ToPrettyString()
                                     << ", node: " << options.ToString()
                                     << ", App: " << this);
  delegate_->SetNativeProps(std::move(root), std::move(options),
                            std::move(native_props));
}

void App::ElementAnimate(const std::string& component_id,
                         const std::string& id_selector,
                         const lepus::Value& args) {
  LOGI(" element " << id_selector << " in " << component_id
                   << " exec element.Animate " << this);
  delegate_->ElementAnimate(component_id, id_selector, args);
}

// for react
void App::OnReactComponentRender(const std::string& id,
                                 const lepus::Value& props,
                                 const lepus::Value& data,
                                 bool should_component_update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentRender");
  LOGI(" OnReactComponentRender " << id);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactComponentRender =
        js_app.getPropertyAsFunction(*rt, "onReactComponentRender");
    if (!onReactComponentRender) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, id));
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto js_pro = valueFromLepus(*rt, props, jsi_object_wrapper_manager_.get());
    if (!js_pro) {
      return;
    }
    auto js_data = valueFromLepus(*rt, data, jsi_object_wrapper_manager_.get());
    if (!js_data) {
      return;
    }
    piper::Value js_should_component_update(should_component_update);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    const Value args[4] = {std::move(js_id), std::move(*js_pro),
                           std::move(*js_data),
                           std::move(js_should_component_update)};
    size_t count = 4;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RunningInJS");
    onReactComponentRender->callWithThis(*rt, thisObj, args, count);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  }
}

void App::OnReactComponentDidUpdate(const std::string& id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentDidUpdate");
  LOGV(" OnReactComponentDidUpdate " << id);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactComponentDidUpdate =
        js_app.getPropertyAsFunction(*rt, "onReactComponentDidUpdate");
    if (!onReactComponentDidUpdate) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, id));

    const Value args[1] = {std::move(js_id)};
    size_t count = 1;
    const piper::Object& thisObj = js_app;
    onReactComponentDidUpdate->callWithThis(*rt, thisObj, args, count);
  }
}

void App::OnReactComponentDidCatch(const std::string& id,
                                   const lepus::Value& error) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentDidCatch");
  LOGI("OnReactComponentDidCatch "
       << id << ", error: " << error.GetProperty("message"));
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    auto js_app = js_app_.getObject(*rt);
    auto onReactComponentDidCatch =
        js_app.getPropertyAsFunction(*rt, "onReactComponentDidCatch");
    if (!onReactComponentDidCatch) {
      return;
    }
    piper::Value js_id(piper::String::createFromUtf8(*rt, id));
    auto js_error =
        valueFromLepus(*rt, error, jsi_object_wrapper_manager_.get());
    if (!js_error) {
      return;
    }
    const Value args[2] = {std::move(js_id), std::move(*js_error)};
    size_t count = 2;
    const piper::Object& thisObj = js_app;
    onReactComponentDidCatch->callWithThis(*rt, thisObj, args, count);
  }
}

void App::OnReactComponentCreated(
    const std::string& entry_name, const std::string& path,
    const std::string& id, const lepus::Value& props, const lepus::Value& data,
    const std::string& parent_id, bool force_flush) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentCreated");
  LOGI(" OnReactComponentCreated " << id << ", path:" << path << ", entryName:"
                                   << entry_name << ", parent: " << parent_id);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactComponentCreated =
        js_app.getPropertyAsFunction(*rt, "onReactComponentCreated");
    if (!onReactComponentCreated) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, id));
    piper::Value js_parent_id(piper::String::createFromUtf8(*rt, parent_id));
    piper::Value js_path(piper::String::createFromUtf8(*rt, path));

    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto js_pro = valueFromLepus(*rt, props, jsi_object_wrapper_manager_.get());
    if (!js_pro) {
      return;
    }
    auto js_data = valueFromLepus(*rt, data, jsi_object_wrapper_manager_.get());
    if (!js_data) {
      return;
    }
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "RunningInJS");
    const piper::Object& thisObj = js_app;
    if (entry_name.empty()) {
      const Value args[7] = {
          std::move(js_path),  std::move(js_id),        std::move(*js_pro),
          std::move(*js_data), std::move(js_parent_id), nullptr,
          force_flush};
      size_t count = 7;
      if (!onReactComponentCreated->callWithThis(*rt, thisObj, args, count)) {
        LOGE("onReactComponentCreated callWithThis fail! entry_name is empty.");
      }
    } else {
      piper::Value js_entry_name(
          piper::String::createFromUtf8(*rt, entry_name));
      const Value args[7] = {std::move(js_path),
                             std::move(js_id),
                             std::move(*js_pro),
                             std::move(*js_data),
                             std::move(js_parent_id),
                             std::move(js_entry_name),
                             force_flush};
      size_t count = 7;
      if (!onReactComponentCreated->callWithThis(*rt, thisObj, args, count)) {
        LOGE("onReactComponentCreated callWithThis fail! entry_name: "
             << entry_name);
      }
    }
  }
}

void App::OnReactComponentUnmount(const std::string& id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactComponentUnmount");
  LOGI(" OnReactComponentUnmount " << id);
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactComponentUnmount =
        js_app.getPropertyAsFunction(*rt, "onReactComponentUnmount");
    if (!onReactComponentUnmount) {
      return;
    }

    piper::Value js_id(piper::String::createFromUtf8(*rt, id));

    const Value args[1] = {std::move(js_id)};
    size_t count = 1;
    const piper::Object& thisObj = js_app;
    onReactComponentUnmount->callWithThis(*rt, thisObj, args, count);

    // When a component unmounted, call ForceGcOnJSThread to clear dirty
    // JSIObjectWrapper. This may not only clear JSIObjectWrapper created by
    // this component, but all of the dirty JSIObjectWrapper can be cleared.
    //
    // There is a mutex inside ForceGcOnJSThread, which may cause main thread
    // waiting for ForceGcOnJSThread.
    // see: #8680
    jsi_object_wrapper_manager_->ForceGcOnJSThread();
  }
}

void App::OnReactCardRender(const lepus::Value& data,
                            bool should_component_update, bool force_flush) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactCardRender");
  LOGI(" OnReactCardRender ");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactCardRender =
        js_app.getPropertyAsFunction(*rt, "onReactCardRender");
    if (!onReactCardRender) {
      return;
    }
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LepusValueToJSValue");
    auto js_data = valueFromLepus(*rt, data, jsi_object_wrapper_manager_.get());
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    if (!js_data) {
      return;
    }
    piper::Value js_should_component_update(should_component_update);

    const Value args[3] = {std::move(*js_data),
                           std::move(js_should_component_update), force_flush};
    size_t count = 3;
    const piper::Object& thisObj = js_app;
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "RunningInJS");
    onReactCardRender->callWithThis(*rt, thisObj, args, count);
  }
}

void App::OnReactCardDidUpdate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnReactCardDidUpdate");
  LOGI(" OnReactCardDidUpdate ");
  auto rt = rt_.lock();
  if (rt && IsJsAppStateValid() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    Object js_app = js_app_.getObject(*rt);

    auto onReactCardDidUpdate =
        js_app.getPropertyAsFunction(*rt, "onReactCardDidUpdate");
    if (!onReactCardDidUpdate) {
      return;
    }
    size_t count = 0;
    const piper::Object& thisObj = js_app;
    onReactCardDidUpdate->callWithThis(*rt, thisObj, nullptr, count);
  }
}

void App::reportException(const std::string& msg, const std::string& stack,
                          int32_t error_code = LYNX_ERROR_CODE_JAVASCRIPT) {
  LOGE("App::reportException " << this << ", error code is " << error_code
                               << ", message is  " << msg << "\n"
                               << stack);
  auto rt = rt_.lock();
  if (rt) {
    delegate_->OnErrorOccurred(error_code, msg);
  }
}

std::shared_ptr<Runtime> App::GetRuntime() { return rt_.lock(); }

std::optional<lepus_value> App::ParseJSValueToLepusValue(
    const piper::Value& data, const std::string& component_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "JSValueToLepusValue");
  auto rt = rt_.lock();
  if (rt) {
    // only React dsl support parse js function
    // TT dsl don't support use js function as the prroperties of component
    std::unique_ptr<std::vector<piper::Object>> pre_object_vector =
        std::make_unique<std::vector<piper::Object>>();
    auto lepus_value_opt =
        ParseJSValue(*rt, data, jsi_object_wrapper_manager_.get(), component_id,
                     delegate_->GetTargetSDKVersion(), *pre_object_vector);
    if (!lepus_value_opt) {
      return std::optional<lepus_value>();
    }
    return lepus_value_opt;
  }
  return lepus::Value();
}

void App::ConsoleLogWithLevel(const std::string& level,
                              const std::string& msg) {
  auto rt = rt_.lock();
  if (rt) {
    Scope scope(*rt.get());
    piper::Object global = rt->global();
    auto console = global.getProperty(*rt, "nativeConsole");
    if (console && console->isObject()) {
      piper::Value msg_object(piper::String::createFromUtf8(*rt, msg));

      size_t count = 1;
      auto level_func =
          console->getObject(*rt).getPropertyAsFunction(*rt, level.c_str());
      if (!level_func) {
        return;
      }
      if (base::LynxEnv::GetInstance().IsDevtoolEnabled()) {
        std::string msg_with_rid =
            "lepusRuntimeId:" + std::to_string(rt->getRuntimeId());
        piper::Value msg_with_rid_obj(
            piper::String::createFromUtf8(*rt, msg_with_rid));
        count = 2;
        const Value args[2] = {std::move(msg_with_rid_obj),
                               std::move(msg_object)};
        level_func->call(*rt, args, count);
      } else {
        const Value args[1] = {std::move(msg_object)};
        level_func->call(*rt, args, count);
      }
    }
  }
}

void App::I18nResourceChanged(const std::string& msg) { i18_resource_ = msg; }

void App::onPiperInvoked(const std::string& module_name,
                         const std::string& method_name) {
  if (base::LynxEnv::GetInstance().IsPiperMonitorEnabled()) {
    time_t timep;
    time(&timep);
    std::ostringstream time_s;
    time_s << timep;
    base::LynxEnv::onPiperInvoked(module_name, method_name, "", url_,
                                  time_s.str());
  }
}

void App::ReloadFromJS(const lepus::Value& value, ApiCallBack callback) {
  auto rt = rt_.lock();
  if (rt) {
    runtime::UpdateDataType update_data_type;
    runtime::UpdateDataTask task(true, PAGE_GROUP_ID, std::move(value),
                                 callback, update_data_type);
    std::string timing_flag_string = tasm::GetTimingFlag(task.data_);
    if (!timing_flag_string.empty()) {
      tasm::TimingCollector::Scope<runtime::TemplateDelegate> scope(
          delegate_, timing_flag_string);
      tasm::TimingCollector::Instance()->Mark(
          tasm::TimingKey::UPDATE_RELOAD_FROM_JS);
    }
    delegate_->ReloadFromJS(std::move(task));
  }
}

piper::Value App::EnableCanvasOptimization() {
  return api_handler_->EnableCanvasOptimization();
}

void App::CallLepusMethod(const std::string& method_name, lepus::Value args,
                          const ApiCallBack& callback) {
  // This `trace_flow_id` is used to trace the flow of CallLepusMethod.
  // ApiCallBack's creation and invocation use different trace_flow_id
  // generated in ApiCallBack's constructor
  auto trace_flow_id = base::tracing::GetFlowId();
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "callLepusMethodInner",
              [&](perfetto::EventContext ctx) {
                ctx.event()->add_flow_ids(trace_flow_id);
                auto* debug = ctx.event()->add_debug_annotations();
                debug->set_name("methodName");
                debug->set_string_value(method_name);
              });
  LOGI(" CallLepusMethod: " << method_name << " " << this);
  delegate_->CallLepusMethod(method_name, std::move(args), callback,
                             trace_flow_id);
}

void App::OnHMRUpdate(const std::string& script) {
#if ENABLE_HMR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "OnHMRUpdate");
  auto rt = rt_.lock();
  if (rt && js_app_.isObject() && delegate_->SupportComponentJS()) {
    Scope scope(*rt);
    auto js_app = js_app_.getObject(*rt);
    auto on_hmr_update = js_app.getPropertyAsFunction(*rt, "onHMRUpdate");
    size_t count = 1;
    const piper::Object& thisObj = js_app;
    piper::Value js_script(piper::String::createFromUtf8(*rt, script));
    piper::Value args[1] = {std::move(js_script)};
    on_hmr_update->callWithThis(*rt, thisObj, args, count);
  }
#endif
}

void App::MarkTiming(const std::string& timing_flag, const std::string& key) {
  if (timing_flag.empty()) {
    return;
  }
  tasm::TimingCollector::Scope<runtime::TemplateDelegate> scope(delegate_,
                                                                timing_flag);
  if (key == "update_diff_vdom_start") {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DIFF_VDOM_START);
  } else if (key == "update_diff_vdom_end") {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_DIFF_VDOM_END);
  } else if (key == "update_set_state_trigger") {
    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_SET_STATE_TRIGGER);
  }
}

}  // namespace piper
}  // namespace lynx
