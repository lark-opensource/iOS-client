// Copyright 2021 The Lynx Authors. All rights reserved.

#include "worklet/lepus_lynx.h"

#include <memory>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "jsbridge/bindings/worklet/napi_frame_callback.h"
#include "jsbridge/bindings/worklet/napi_func_callback.h"
#include "jsbridge/bindings/worklet/napi_lepus_element.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/template_assembler.h"
#include "third_party/fml/make_copyable.h"
#include "worklet/base/worklet_utils.h"

namespace lynx {
namespace worklet {

LepusLynx::LepusLynx(Napi::Env env, const std::string& entry_name,
                     tasm::TemplateAssembler* assembler)
    : env_(env),
      entry_name_(entry_name),
      tasm_(assembler),
      task_handler_(std::make_unique<LepusApiHandler>()) {}

uint32_t LepusLynx::SetTimeout(std::unique_ptr<NapiFuncCallback> callback,
                               int64_t delay) {
  EnsureTimeTaskInvoker();
  auto callback_id = task_handler_->StoreTimedTask(std::move(callback));
  auto task_id =
      timer_->SetTimeout(fml::MakeCopyable([env = Env(), callback_id, this]() {
                           task_handler_->InvokeWithTimedTaskID(
                               callback_id, Napi::Object::New(env), tasm_);
                           task_handler_->RemoveTimeTask(callback_id);
                         }),
                         delay);
  task_to_callback_map_[task_id] = callback_id;
  return task_id;
}

uint32_t LepusLynx::SetInterval(std::unique_ptr<NapiFuncCallback> callback,
                                int64_t delay) {
  EnsureTimeTaskInvoker();
  auto callback_id = task_handler_->StoreTimedTask(std::move(callback));
  auto task_id = timer_->SetInterval(
      [callback_id, this]() {
        task_handler_->InvokeWithTimedTaskID(callback_id,
                                             Napi::Object::New(Env()), tasm_);
        tasm::PipelineOptions options;
        tasm_->page_proxy()->element_manager()->OnPatchFinishInner(options);
      },
      delay);
  task_to_callback_map_[task_id] = callback_id;
  return task_id;
}

void LepusLynx::ClearTimeout(uint32_t task_id) { RemoveTimedTask(task_id); }

void LepusLynx::ClearInterval(uint32_t task_id) { RemoveTimedTask(task_id); }

void LepusLynx::RemoveTimedTask(uint32_t task_id) {
  EnsureTimeTaskInvoker();
  timer_->StopTask(task_id);
  // TODO(songshourui.null): The NapiFunction should be removed to avoid memory
  // leak. However, the developers may currently remove the callback itself in
  // the setTimeout or setInterval callback, which can lead to crashes.
  // Therefore, this part of the code has been commented out for the time being
  // to prevent crashes. We will fix the memory leak issue while also avoiding
  // crashes in the future.
  // task_handler_->RemoveTimeTask(task_to_callback_map_[task_id]);
  task_to_callback_map_.erase(task_id);
}

void LepusLynx::EnsureTimeTaskInvoker() {
  if (timer_ == nullptr) {
    timer_ = std::make_unique<base::TimedTaskManager>();
  }
}

void LepusLynx::TriggerLepusBridge(const std::string& method_name,
                                   Napi::Object method_detail,
                                   std::unique_ptr<NapiFuncCallback> callback) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusLynx:::TriggerLepusBridge");

  constexpr const static char* kEventDetail = "methodDetail";
  constexpr const static char* kEventCallbackId = "callbackId";
  constexpr const static char* kEventEntryName = "tasmEntryName";

  int64_t callback_id = task_handler_->StoreTask(std::move(callback));
  // Native Method triggered from lepus, toLepus default value is ture, toJS
  // default value is false.
  // Construct event para.
  Napi::Object para = Napi::Object::New(Env());
  para.Set(kEventDetail, method_detail);
  para.Set(kEventCallbackId, callback_id);
  para.Set(kEventEntryName, entry_name_);
  const auto& lepus_para = ValueConverter::ConvertNapiValueToLepusValue(para);
  tasm_->TriggerLepusBridgeAsync(method_name, lepus_para);
}

Napi::Value LepusLynx::TriggerLepusBridgeSync(const std::string& method_name,
                                              Napi::Object method_detail) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusLynx:::TriggerLepusBridge");
  LOGI("LepusLynx TriggerLepusBridgeSync triggered");
  if (tasm_ == nullptr) {
    LOGE("LepusLynx TriggerLepusBridge failed since tasm is nullptr");
    return Napi::Object::New(Env());
  }

  constexpr const static char* kEventDetail = "methodDetail";
  constexpr const static char* kEventComponentId = "componentId";
  constexpr const static char* kEventEntryName = "tasmEntryName";

  Napi::Object para = Napi::Object::New(Env());
  para.Set(kEventDetail, method_detail);
  // TODO(fulei.bill): remove this componentId later
  para.Set(kEventComponentId, Napi::String::New(Env(), std::to_string(-1)));
  para.Set(kEventEntryName, entry_name_);
  const auto& lepus_para = ValueConverter::ConvertNapiValueToLepusValue(para);

  Napi::Value callback_param = ValueConverter::ConvertLepusValueToNapiValue(
      Env(), tasm_->TriggerLepusBridge(method_name, lepus_para));
  return callback_param;
}

void LepusLynx::InvokeLepusBridge(const int32_t callback_id,
                                  const lepus::Value& data) {
  constexpr const static char* kEventCallbackParams = "callbackParams";
  Napi::Object callback_param = Napi::Object::New(Env());
  callback_param.Set(kEventCallbackParams,
                     ValueConverter::ConvertLepusValueToNapiValue(Env(), data));
  task_handler_->InvokeWithTaskID(callback_id, callback_param, tasm_);
}

}  // namespace worklet
}  // namespace lynx
