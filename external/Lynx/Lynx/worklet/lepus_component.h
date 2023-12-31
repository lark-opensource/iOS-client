// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_WORKLET_LEPUS_COMPONENT_H_
#define LYNX_WORKLET_LEPUS_COMPONENT_H_

#include <memory>
#include <string>
#include <vector>

#include "jsbridge/napi/base.h"
#include "lepus/value.h"
#include "worklet/lepus_element.h"
#include "worklet/lepus_raf_handler.h"

namespace lynx {

namespace tasm {
class TemplateAssembler;
}  // namespace tasm

namespace worklet {

using piper::BridgeBase;
using piper::ImplBase;

class NapiFrameCallback;
class NapiFuncCallback;

class LepusComponent : public ImplBase {
 public:
  static LepusComponent* Create(
      uint32_t component_id,
      const std::shared_ptr<tasm::TemplateAssembler>& assembler,
      std::weak_ptr<LepusApiHandler> task_handler) {
    return new LepusComponent(component_id, assembler, task_handler);
  }
  LepusComponent(const LepusComponent&) = delete;
  virtual ~LepusComponent();

  LepusElement* QuerySelector(const std::string& selector);
  std::vector<LepusElement*> QuerySelectorAll(const std::string& selector);
  int64_t RequestAnimationFrame(std::unique_ptr<NapiFrameCallback> callback);
  void CancelAnimationFrame(int64_t id);
  void TriggerEvent(const std::string& event_name, Napi::Object event_detail,
                    Napi::Object event_option);
  Napi::Object GetStore();
  void SetStore(const Napi::Object& value);

  Napi::Object GetData();
  void SetData(const Napi::Object& value);

  Napi::Object GetProperties();

  void CallJSFunction(const std::string& func_name, Napi::Object func_param,
                      std::unique_ptr<NapiFuncCallback> callback);
  void CallJSFunction(const std::string& func_name, Napi::Object func_param);

  // not visible in napi, just for callback
  void HandleJSCallbackLepus(const int64_t callback_id,
                             const lepus::Value& data);

  void set_component_id(uint32_t id) { component_id_ = id; }
  uint32_t component_id() { return component_id_; }

 private:
  LepusComponent(uint32_t component_id,
                 const std::shared_ptr<tasm::TemplateAssembler>& assembler,
                 std::weak_ptr<worklet::LepusApiHandler> task_handler);
  std::vector<LepusElement*> QuerySelector(const std::string& selector,
                                           bool single);

  void DoFrame(int64_t frame_start, int64_t frame_end);

  uint32_t component_id_;
  std::weak_ptr<tasm::TemplateAssembler> weak_tasm_;
  std::unique_ptr<LepusAnimationFrameTaskHandler> raf_handler_;
  std::weak_ptr<LepusApiHandler> task_handler_;
  lepus::Value data_updated_;
};
}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_WORKLET_LEPUS_COMPONENT_H_
