// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_WORKLET_LEPUS_ELEMENT_H_
#define LYNX_WORKLET_LEPUS_ELEMENT_H_

#include <memory>
#include <string>
#include <vector>

#include "jsbridge/napi/base.h"
#include "lepus/quick_context.h"
#include "tasm/react/event.h"
#include "tasm/template_assembler.h"

namespace lynx {

namespace tasm {
class Element;
}  // namespace tasm

namespace worklet {
class LepusComponent;

using piper::BridgeBase;
using piper::ImplBase;

class LepusElement : public ImplBase {
 public:
  static LepusElement* Create(
      int32_t element_id,
      const std::shared_ptr<tasm::TemplateAssembler>& tasm) {
    return new LepusElement(element_id, tasm);
  }
  static void FireElementWorklet(
      tasm::TemplateAssembler* tasm, tasm::BaseComponent* component,
      lepus::Value& func_val, const lepus::Value& func_obj,
      const lepus::Value& value,
      const std::shared_ptr<worklet::LepusApiHandler>& task_handler,
      LepusComponent* lepus_component);

  static std::optional<lepus::Value> TriggerWorkletFunction(
      tasm::TemplateAssembler* tasm, tasm::BaseComponent* component,
      const std::string& worklet_module_name, const std::string& method_name,
      const lepus::Value& args);

  static std::optional<lepus::Value> CallLepusWithComponentInstance(
      lynx::tasm::TemplateAssembler* tasm, LEPUSContext* ctx,
      const LEPUSValue& func_obj, const LEPUSValue& this_obj,
      const LEPUSValue& args, const LEPUSValue& component_instance);

  LepusElement(const LepusElement&) = delete;
  ~LepusElement() override = default;

  tasm::Element* GetElement();

  void SetStyles(const Napi::Object& styles);
  void SetAttributes(const Napi::Object& attributes);

  Napi::Object GetComputedStyles(const std::vector<Napi::String>& keys);
  Napi::Object GetAttributes(const std::vector<Napi::String>& keys);
  Napi::Object GetDataset();

  // Function
  Napi::Value ScrollBy(float width, float height);
  Napi::Value GetBoundingClientRect();
  void Invoke(const Napi::Object& object);

 private:
  LepusElement(int32_t element_id,
               const std::shared_ptr<tasm::TemplateAssembler>& tasm);
  int32_t element_id_{-1};
  std::weak_ptr<tasm::TemplateAssembler> weak_tasm_;
};
}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_WORKLET_LEPUS_ELEMENT_H_
