// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/runtime_mediator.h"

#include "base/debug/lynx_assert.h"
#include "config/config.h"
#include "shell/common/vsync_monitor.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/template_assembler.h"
#if ENABLE_ARK_RECORDER
#include "tasm/recorder/ark_base_recorder.h"
#endif

namespace lynx {
namespace shell {

void RuntimeMediator::UpdateDataByJS(runtime::UpdateDataTask task) {
  card_cached_data_mgr_->IncrementTaskCount();
  engine_actor_->ActAsync([task = std::move(task)](auto& engine) mutable {
    engine->UpdateDataByJS(std::move(task));
  });
}

void RuntimeMediator::UpdateBatchedDataByJS(
    std::vector<runtime::UpdateDataTask> tasks, uint64_t update_task_id) {
  card_cached_data_mgr_->IncrementTaskCount();
  engine_actor_->ActAsync(
      [tasks = std::move(tasks),
       update_task_id = update_task_id](auto& engine) mutable {
        engine->UpdateBatchedDataByJS(std::move(tasks), update_task_id);
      });
}

std::vector<shell::CacheDataOp> RuntimeMediator::FetchUpdatedCardData() {
  return card_cached_data_mgr_->ObtainCardCacheData();
}

std::string RuntimeMediator::GetLynxJSAsset(const std::string& name) {
  std::string resource = js_source_loader_->LoadJSSource(name);
  if (resource.empty()) {
    LOGE("GetLynxJSAsset failed, the source_url is: " << name);
  }
  return resource;
}

std::string RuntimeMediator::GetJSSource(const std::string& bundle_name,
                                         const std::string& name) {
  tasm::TemplateBundle* bundle = nullptr;
  if (bundle_name == tasm::DEFAULT_ENTRY_NAME) {
    bundle = &card_bundle_;
  } else {
    auto iter = component_bundles_.find(bundle_name);
    if (iter != component_bundles_.end()) {
      bundle = &iter->second;
    }
  }
  if (bundle != nullptr) {
    auto iter = bundle->js_source.find(name);
    if (iter != bundle->js_source.end()) {
      return iter->second.str();
    }
  }
  LOGE("GetJSSource with externalSourceLoader: " << name);
#if ENABLE_ARK_RECORDER
  std::string external_source_content =
      external_source_loader_->LoadScript(name);
  tasm::recorder::ArkBaseRecorder::GetInstance().RecordExternalSource(
      name.c_str(), external_source_content.c_str());
  return external_source_content;
#else
  return external_source_loader_->LoadScript(name);
#endif
}

lepus::Value RuntimeMediator::GetTasmEncodedData() {
  return card_bundle_.encoded_data;
}

lepus::Value RuntimeMediator::GetNativeInitData() {
  return card_bundle_.init_data;
}

lepus::Value RuntimeMediator::GetInitGlobalProps() {
  return lepus::Value::ShallowCopy(init_global_props_);
}

void RuntimeMediator::GetComponentContextDataAsync(
    const std::string& component_id, const std::string& key,
    piper::ApiCallBack callback) {
  engine_actor_->ActAsync([component_id, key, callback](auto& engine) {
    engine->GetComponentContextDataAsync(component_id, key, callback);
  });
}

bool RuntimeMediator::LoadDynamicComponentFromJS(
    const std::string& url, const piper::ApiCallBack& callback) {
  if (component_bundles_.find(url) != component_bundles_.end()) {
    return true;
  }
  external_source_loader_->LoadDynamicComponent(url, callback.id());
  return false;
}

void RuntimeMediator::LoadScriptAsync(const std::string& url,
                                      piper::ApiCallBack callback) {
  external_source_loader_->LoadScriptAsync(url, callback.id());
}

void RuntimeMediator::OnRuntimeReady() {
  facade_actor_->ActAsync([](auto& facade) { facade->OnRuntimeReady(); });
}

void RuntimeMediator::OnErrorOccurred(int32_t error_code,
                                      const std::string& msg) {
  facade_actor_->ActAsync([error_code, msg](auto& facade) {
    facade->ReportError(error_code, msg);
  });
}

void RuntimeMediator::OnModuleMethodInvoked(const std::string& module,
                                            const std::string& method,
                                            int32_t code) {
  facade_actor_->ActAsync([module, method, code](auto& facade) {
    facade->OnModuleMethodInvoked(module, method, code);
  });
}

void RuntimeMediator::UpdateComponentData(runtime::UpdateDataTask task) {
  engine_actor_->ActAsync([task = std::move(task)](auto& engine) mutable {
    engine->UpdateComponentData(std::move(task));
  });
}

void RuntimeMediator::SelectComponent(const std::string& component_id,
                                      const std::string& id_selector,
                                      const bool single,
                                      piper::ApiCallBack callBack) {
  engine_actor_->ActAsync(
      [component_id, id_selector, single, callBack](auto& engine) {
        engine->SelectComponent(component_id, id_selector, single, callBack);
      });
}

void RuntimeMediator::InvokeUIMethod(
    tasm::NodeSelectRoot root, tasm::NodeSelectOptions options,
    std::string method, std::unique_ptr<piper::PlatformValue> params,
    piper::ApiCallBack callback) {
  engine_actor_->ActAsync([root = std::move(root), options = std::move(options),
                           method = std::move(method),
                           params = std::move(params),
                           callback](auto& engine) mutable {
    engine->InvokeUIMethod(root, options, method, std::move(params), callback);
  });
}

void RuntimeMediator::GetPathInfo(tasm::NodeSelectRoot root,
                                  tasm::NodeSelectOptions options,
                                  piper::ApiCallBack call_back) {
  engine_actor_->ActAsync([root = std::move(root), options = std::move(options),
                           call_back](auto& engine) {
    engine->GetPathInfo(root, options, call_back);
  });
}

void RuntimeMediator::GetFields(tasm::NodeSelectRoot root,
                                tasm::NodeSelectOptions options,
                                std::vector<std::string> fields,
                                piper::ApiCallBack call_back) {
  engine_actor_->ActAsync([root = std::move(root), options = std::move(options),
                           fields = std::move(fields),
                           call_back](auto& engine) {
    engine->GetFields(root, options, fields, call_back);
  });
}

void RuntimeMediator::ElementAnimate(const std::string& component_id,
                                     const std::string& id_selector,
                                     const lepus::Value& args) {
  engine_actor_->ActAsync([component_id, id_selector, args](auto& engine) {
    engine->ElementAnimate(component_id, id_selector, args);
  });
}

void RuntimeMediator::OnCoreJSUpdated(std::string core_js) {
  engine_actor_->ActAsync([core_js = std::move(core_js)](auto& engine) mutable {
    engine->UpdateCoreJS(std::move(core_js));
  });
}

void RuntimeMediator::TriggerComponentEvent(const std::string& event_name,
                                            const lepus::Value& msg) {
  engine_actor_->ActAsync([event_name, msg](auto& engine) {
    engine->TriggerComponentEvent(event_name, msg);
  });
}

void RuntimeMediator::TriggerLepusGlobalEvent(const std::string& event_name,
                                              const lepus::Value& msg) {
  engine_actor_->ActAsync([event_name, msg](auto& engine) {
    engine->TriggerLepusGlobalEvent(event_name, msg);
  });
}

void RuntimeMediator::InvokeLepusComponentCallback(
    const int64_t callback_id, const std::string& entry_name,
    const lepus::Value& data) {
  engine_actor_->ActAsync([callback_id, entry_name, data](auto& engine) {
    engine->InvokeLepusComponentCallback(callback_id, entry_name, data);
  });
}

void RuntimeMediator::TriggerWorkletFunction(std::string component_id,
                                             std::string worklet_module_name,
                                             std::string method_name,
                                             lepus::Value args,
                                             piper::ApiCallBack callback) {
  engine_actor_->ActAsync(
      [component_id = std::move(component_id),
       worklet_module_name = std::move(worklet_module_name),
       method_name = std::move(method_name), args = std::move(args),
       callback = std::move(callback)](auto& engine) mutable {
        engine->TriggerWorkletFunction(
            std::move(component_id), std::move(worklet_module_name),
            std::move(method_name), std::move(args), std::move(callback));
      });
}

bool RuntimeMediator::NeedGlobalConsole() {
  return card_bundle_.need_global_console;
}

bool RuntimeMediator::SupportComponentJS() {
  return card_bundle_.support_component_js;
}

void RuntimeMediator::RunOnJSThread(base::closure closure) {
  return js_runner_->PostTask(std::move(closure));
}

void RuntimeMediator::AfterNotifyJSUpdatePageData(
    std::vector<base::closure> callbacks) {
  if (callbacks.empty()) {
    return;
  }
  facade_actor_->ActAsync([callbacks = std::move(callbacks)](auto& facade) {
    for (const auto& callback : callbacks) {
      callback();
    }
  });
}

void RuntimeMediator::OnCardDecoded(tasm::TemplateBundle bundle,
                                    const lepus::Value& global_props) {
  card_bundle_ = std::move(bundle);
  init_global_props_ = global_props;
}

void RuntimeMediator::OnComponentDecoded(tasm::TemplateBundle bundle) {
  std::string name = bundle.name;
  component_bundles_.emplace(std::move(name), std::move(bundle));
}

void RuntimeMediator::RequestVSync() {
  if (has_pending_vsync_request_) {
    return;
  }
  has_pending_vsync_request_ = true;
  vsync_monitor_->AsyncRequestVSync(
      [this](int64_t frame_start_time, int64_t frame_end_time) {
        vsync_monitor_->runtime_actor()->Act(
            [this, frame_start_time, frame_end_time](auto& runtime) {
              has_pending_vsync_request_ = false;
              DoFrame(frame_start_time, frame_end_time);
            });
      });
}

inline void RuntimeMediator::SwapVSyncCallbacks(
    std::vector<VSyncCallback>& swap_callbacks) {
  // first run flush callback; then JS RAF callback
  for (auto& cb_pair : flush_vsync_callbacks_) {
    swap_callbacks.push_back(std::move(cb_pair.second));
  }
  flush_vsync_callbacks_.clear();

  for (auto& cb_pair : vsync_callbacks_) {
    swap_callbacks.push_back(std::move(cb_pair.second));
  }
  vsync_callbacks_.clear();
}

inline void RuntimeMediator::DoFrame(int64_t frame_start_time,
                                     int64_t frame_end_time) {
  std::vector<VSyncCallback> callbacks;
  SwapVSyncCallbacks(callbacks);
  for (auto& cb : callbacks) {
    cb(frame_start_time, frame_end_time);
  }
}

void RuntimeMediator::AsyncRequestVSync(
    uintptr_t id, base::MoveOnlyClosure<void, int64_t, int64_t> callback,
    bool for_flush) {
  // make sure to run on Runtime thread
  DCHECK(js_runner_->RunsTasksOnCurrentThread());
  if (!for_flush) {
    vsync_callbacks_.emplace(id, std::move(callback));
  } else {
    flush_vsync_callbacks_.emplace(id, std::move(callback));
  }
  RequestVSync();
}

void RuntimeMediator::SetCSSVariables(const std::string& component_id,
                                      const std::string& id_selector,
                                      const lepus::Value& properties) {
  engine_actor_->ActAsync(
      [component_id, id_selector, properties](auto& engine) {
        engine->SetCSSVariables(component_id, id_selector, properties);
      });
}

void RuntimeMediator::SetNativeProps(tasm::NodeSelectRoot root,
                                     const tasm::NodeSelectOptions& options,
                                     const lepus::Value& native_props) {
  engine_actor_->ActAsync(
      [root = std::move(root), options, native_props](auto& engine) {
        engine->SetNativeProps(root, options, native_props);
      });
}

void RuntimeMediator::ReloadFromJS(runtime::UpdateDataTask task) {
  engine_actor_->ActAsync([task = std::move(task)](auto& engine) mutable {
    engine->ReloadFromJS(std::move(task));
  });
}

void RuntimeMediator::OnCardConfigDataChanged(const lepus::Value& data) {
  card_config_ = data;
}

lepus::Value RuntimeMediator::GetNativeCardConfigData() { return card_config_; }

bool RuntimeMediator::GetEnableAttributeTimingFlag() const {
  return card_bundle_.enable_attribute_timing_flag;
}

const std::string& RuntimeMediator::GetTargetSDKVersion() {
  return card_bundle_.target_sdk_version;
}

void RuntimeMediator::SetTiming(tasm::Timing timing) {
  facade_actor_->ActAsync([timing = std::move(timing)](auto& facade) mutable {
    facade->SetTiming(std::move(timing));
  });
}

void RuntimeMediator::Report(
    std::vector<std::unique_ptr<tasm::PropBundle>> stack) {
  facade_actor_->ActAsync([stack = std::move(stack)](auto& facade) mutable {
    facade->Report(std::move(stack));
  });
}

void RuntimeMediator::FlushJSBTiming(piper::NativeModuleInfo timing) {
  facade_actor_->ActAsync([timing = std::move(timing)](auto& facade) mutable {
    facade->FlushJSBTiming(std::move(timing));
  });
}

void RuntimeMediator::CallLepusMethod(const std::string& method_name,
                                      lepus::Value args,
                                      const piper::ApiCallBack& callback,
                                      uint64_t trace_flow_id) {
  engine_actor_->ActAsync([method_name, args = std::move(args), callback,
                           trace_flow_id](auto& engine) mutable {
    engine->CallLepusMethod(method_name, std::move(args), callback,
                            trace_flow_id);
  });
}

}  // namespace shell
}  // namespace lynx
