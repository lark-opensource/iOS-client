// Copyright 2021 The Lynx Authors. All rights reserved.

#import "shell/ios/js_proxy_darwin.h"

#include <atomic>
#include <unordered_map>

#include "base/no_destructor.h"
#include "base/threading/task_runner_manufactor.h"
#include "tasm/config.h"

#include "base/trace_event/trace_event.h"
#import "jsbridge/ios/piper/lynx_callback_darwin.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_dynamic_component.h"
#include "tasm/recorder/recorder_controller.h"

namespace lynx {
namespace shell {

namespace {

// ensure access on js thread
std::unordered_map<int64_t, std::weak_ptr<JSProxyDarwin>>& GetJSProxies() {
  static base::NoDestructor<std::unordered_map<int64_t, std::weak_ptr<JSProxyDarwin>>> js_proxies;
  return *js_proxies;
}

};  // namespace

std::shared_ptr<JSProxyDarwin> JSProxyDarwin::Create(
    const std::shared_ptr<LynxActor<runtime::LynxRuntime>>& actor, LynxView* lynx_view, int64_t id,
    bool use_proxy_map) {
  // constructor is private, cannot use std::make_shared
  auto js_proxy =
      std::shared_ptr<JSProxyDarwin>(new JSProxyDarwin(actor, lynx_view, id, use_proxy_map));
  if (use_proxy_map) {
    base::TaskRunnerManufactor::GetJSRunner()->PostTask(
        [js_proxy, id = js_proxy->id_]() { GetJSProxies().emplace(id, js_proxy); });
  }
  return js_proxy;
}

std::shared_ptr<JSProxyDarwin> JSProxyDarwin::GetJSProxyById(int64_t id) {
  auto& proxies = GetJSProxies();
  auto iter = proxies.find(id);
  return iter != proxies.end() ? iter->second.lock() : nullptr;
}

JSProxyDarwin::JSProxyDarwin(const std::shared_ptr<LynxActor<runtime::LynxRuntime>>& actor,
                             LynxView* lynx_view, int64_t id, bool use_proxy_map)
    : actor_(actor), lynx_view_(lynx_view), id_(id), use_proxy_map_(use_proxy_map) {}

JSProxyDarwin::~JSProxyDarwin() {
  if (use_proxy_map_) {
    base::TaskRunnerManufactor::GetJSRunner()->PostTask([id = id_]() { GetJSProxies().erase(id); });
  }
}

void JSProxyDarwin::CallJSFunction(NSString* module, NSString* method, NSArray* args) {
  actor_->Act([module, method, args](auto& runtime) {
    runtime->call([&runtime, module = module, method = method, args = args] {
      auto js_runtime = runtime->GetJSRuntime();
      piper::Scope scope(*js_runtime);
      if (js_runtime == nullptr) {
        LOGR("try call js module before js context is ready! module:" <<
             [module UTF8String] << " method:" << [method UTF8String] << &runtime);
        return;
      }
      std::string module_name = [module UTF8String];
      std::string method_name = [method UTF8String];
#define WITH_GLOBAL_EVENT_EMITTER_EVENT_NAME                                                \
  ([module isEqualToString:@"GlobalEventEmitter"] && [method isEqualToString:@"emit"] &&    \
   args.count > 0)                                                                          \
      ? ("CallJSFunction:" + module_name + "." + method_name + "->" + [args[0] UTF8String]) \
      : ("CallJSFunction:" + module_name + "." + method_name)
      TRACE_EVENT(LYNX_TRACE_CATEGORY, nullptr, [&](lynx::perfetto::EventContext ctx) {
        ctx.event()->set_name(WITH_GLOBAL_EVENT_EMITTER_EVENT_NAME);
      });
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "CallJSFunction:ObjCArrayToJSArray");
      auto params = convertNSArrayToJSIArray(*js_runtime, args);
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
      if (!params) {
        js_runtime->reportJSIException(piper::JSINativeException(
            "CallJSFunction fail! Reason: Transfer Objc value to js value fail."));
        return;
      }
#if ENABLE_ARK_RECORDER
      auto size = params->length(*js_runtime);
      if (size) {
        piper::Value values[*size];
        for (size_t index = 0; index < *size; index++) {
          auto item_opt = params->getValueAtIndex(*js_runtime, index);
          if (item_opt) {
            values[index] = std::move(*item_opt);
          }
        }
        lynx::tasm::recorder::NativeModuleRecorder::RecordGlobalEvent(
            module_name, method_name, values, *size, js_runtime.get());
      }
#endif
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "CallJSFunction:Fire");
      runtime->CallFunction(module_name, method_name, *params);
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    });
  });
}

void JSProxyDarwin::CallJSIntersectionObserver(NSInteger observer_id, NSInteger callback_id,
                                               NSDictionary* args) {
  actor_->Act([observer_id, callback_id, args](auto& runtime) {
    piper::Scope scope(*runtime->GetJSRuntime());
    auto data_opt = convertNSDictionaryToJSIObject(*runtime->GetJSRuntime(), args);
    if (!data_opt) {
      runtime->GetJSRuntime()->reportJSIException(piper::JSINativeException(
          "CallJSIntersectionObserver fail! Reason: Transfer Objc value to js value fail."));
      return;
    }
    piper::Value data(std::move(*data_opt));
    runtime->CallIntersectionObserver((int32_t)observer_id, (int32_t)callback_id, std::move(data));
  });
}

void JSProxyDarwin::CallJSApiCallbackWithValue(NSInteger callback_id, NSDictionary* args) {
  actor_->Act([callback_id, args](auto& runtime) {
    piper::Scope scope(*runtime->GetJSRuntime());
    auto data_opt = convertNSDictionaryToJSIObject(*runtime->GetJSRuntime(), args);
    if (!data_opt) {
      runtime->GetJSRuntime()->reportJSIException(piper::JSINativeException(
          "CallJSApiCallbackWithValue fail! Reason: Transfer Objc value to js value fail."));
      return;
    }
    piper::Value data(std::move(*data_opt));
    runtime->CallJSApiCallbackWithValue((int32_t)callback_id, std::move(data));
  });
}

void JSProxyDarwin::EvaluateScript(const std::string& url, std::string script,
                                   int32_t callback_id) {
  actor_->Act([url, script = std::move(script), callback_id](auto& runtime) mutable {
    runtime->EvaluateScript(url, std::move(script), piper::ApiCallBack(callback_id));
  });
}

void JSProxyDarwin::RejectDynamicComponentLoad(const std::string& url, int32_t callback_id,
                                               int32_t err_code, const std::string& err_msg) {
  actor_->Act([url, callback_id, err_code, err_msg](auto& runtime) {
    runtime->CallJSApiCallbackWithValue(
        piper::ApiCallBack(callback_id),
        tasm::RadonDynamicComponent::ConstructFailLoadInfo(url, err_code, err_msg));
  });
}

}  // namespace shell
}  // namespace lynx
