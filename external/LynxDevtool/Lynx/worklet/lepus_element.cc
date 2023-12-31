// Copyright 2021 The Lynx Authors. All rights reserved.

#include "worklet/lepus_element.h"

#include <optional>
#include <stack>

#include "base/debug/lynx_assert.h"
#include "base/trace_event/trace_event.h"
#include "css/css_decoder.h"
#include "css/css_property.h"
#include "jsbridge/bindings/worklet/napi_lepus_component.h"
#include "jsbridge/bindings/worklet/napi_lepus_element.h"
#include "jsbridge/bindings/worklet/napi_loader_ui.h"
#include "jsbridge/napi/napi_environment.h"
#include "lepus/context.h"
#include "lepus/lepus_error_helper.h"
#include "lepus/value.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element.h"
#include "tasm/template_entry.h"
#include "worklet/base/worklet_utils.h"
#include "worklet/lepus_component.h"
#include "worklet/lepus_lynx.h"

namespace lynx {
namespace worklet {

LepusElement::LepusElement(int32_t element_id,
                           const std::shared_ptr<tasm::TemplateAssembler>& tasm)
    : element_id_(element_id), weak_tasm_(tasm) {}

tasm::Element* LepusElement::GetElement() {
  auto tasm = weak_tasm_.lock();
  if (tasm == nullptr) {
    return nullptr;
  }
  if (tasm->destroyed()) {
    return nullptr;
  }
  return tasm->page_proxy()->element_manager()->node_manager()->Get(
      element_id_);
}

void LepusElement::FireElementWorklet(
    tasm::TemplateAssembler* tasm, tasm::BaseComponent* component,
    lepus::Value& func_val, const lepus::Value& func_obj,
    const lepus::Value& value,
    const std::shared_ptr<worklet::LepusApiHandler>& task_handler,
    LepusComponent* lepus_component) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::FireElementWorklet");
  if (component == nullptr || tasm == nullptr) {
    return;
  }

  // Get & Exec element worklet function
  auto* ctx = func_val.context();

  // Using lepus::Value to wrap LEPUSValue, so that we don't have to
  // LEPUS_FreeValue it. When using as LEPUSValue, use WrapJSValue()
  const auto func_val_wrapper = lepus::Value(ctx, func_val.ToJSValue(ctx));
  const auto func_obj_wrapper = lepus::Value(ctx, func_obj.ToJSValue(ctx));
  const auto value_wrapper = lepus::Value(ctx, value.ToJSValue(ctx, true));

  const auto func_val_js_value = func_val_wrapper.WrapJSValue();
  const auto func_obj_js_value = func_obj_wrapper.WrapJSValue();
  const auto value_js_value = value_wrapper.WrapJSValue();

  if (!LEPUS_IsFunction(ctx, func_val_js_value)) {
    return;
  }

  auto entry_name = component->GetEntryName();
  if (entry_name.empty()) {
    entry_name = tasm::DEFAULT_ENTRY_NAME;
  }
  Napi::Env env(reinterpret_cast<napi_env>(
      static_cast<lepus::QuickContext*>(tasm->context(entry_name))
          ->napi_env()));
  if (lepus_component == nullptr && task_handler != nullptr) {
    lepus_component = worklet::LepusComponent::Create(
        component->ComponentId(), tasm->shared_from_this(),
        std::weak_ptr<worklet::LepusApiHandler>(task_handler));
  }
  auto component_ins = worklet::NapiLepusComponent::Wrap(
      std::unique_ptr<LepusComponent>(lepus_component), env);
  auto component_obj =
      *reinterpret_cast<LEPUSValue*>(static_cast<napi_value>(component_ins));

  LepusElement::CallLepusWithComponentInstance(tasm, ctx, func_val_js_value,
                                               func_obj_js_value,
                                               value_js_value, component_obj);
}

std::optional<lepus::Value> LepusElement::TriggerWorkletFunction(
    tasm::TemplateAssembler* tasm, tasm::BaseComponent* component,
    const std::string& worklet_module_name, const std::string& method_name,
    const lepus::Value& args) {
  // Lifetime of const reference worklet_module_name, method_name and args can
  // be determined at template_assembler triggerWorkletFunction

  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusComponent::TriggerWorkletFunction");
  if (component == nullptr || tasm == nullptr) {
    LOGE(
        "LepusComponent::TriggerWorkletFunction failed since tasm or component "
        "is null.");
    return std::nullopt;
  }

  // We stored workelt_instance at component by key
  // For example at a ttml: <script src="./worklet.js"
  // name="worklet-module"></script> where key is "worklet-module"

  auto& instances = component->worklet_instances();
  lepus::Value worklet_instance;

  auto iter = instances.find(worklet_module_name);
  if (iter == instances.end()) {
    tasm->ReportError(
        LYNX_ERROR_CODE_WORKLET_MODULE_EXCEPTION,
        std::string{"Can not find worklet module of name: "}.append(
            worklet_module_name));
    return std::nullopt;
  }

  worklet_instance = iter->second;

  // Get function with method_name, and make sure it's OK

  LEPUSContext* ctx = worklet_instance.context();

  // Using lepus::Value to wrap LEPUSValue, so that we don't have to
  // LEPUS_FreeValue it. When using as LEPUSValue, use WrapJSValue()
  const auto worklet_instance_wrapper =
      lepus::Value(ctx, worklet_instance.ToJSValue(ctx));
  const auto worklet_module_function_wrapper = lepus::Value(
      ctx, LEPUS_GetPropertyStr(ctx, worklet_instance_wrapper.WrapJSValue(),
                                method_name.c_str()));

  const auto worklet_instance_js_value = worklet_instance_wrapper.WrapJSValue();
  const auto worklet_module_function_js_value =
      worklet_module_function_wrapper.WrapJSValue();

  if (!LEPUS_IsFunction(ctx, worklet_module_function_js_value)) {
    tasm->ReportError(LYNX_ERROR_CODE_WORKLET_MODULE_EXCEPTION,
                      std::string{"TriggerWorkletFunction failed since "}
                          .append(method_name)
                          .append(" is not a function"));

    return std::nullopt;
  }

  // Make a component_instance with NAPI wrap
  auto entry_name = component->GetEntryName();
  if (entry_name.empty()) {
    entry_name = tasm::DEFAULT_ENTRY_NAME;
  }

  Napi::Env env(reinterpret_cast<napi_env>(
      static_cast<lepus::QuickContext*>(tasm->context(entry_name))
          ->napi_env()));

  auto component_ins = worklet::NapiLepusComponent::Wrap(
      std::unique_ptr<LepusComponent>(LepusComponent::Create(
          component->ComponentId(), tasm->shared_from_this(), {})),
      env);

  auto component_obj =
      *reinterpret_cast<LEPUSValue*>(static_cast<napi_value>(component_ins));

  const auto args_wrapper = lepus::Value(ctx, args.ToJSValue(ctx, true));

  std::optional<lepus::Value> call_result_value =
      LepusElement::CallLepusWithComponentInstance(
          tasm, ctx, worklet_module_function_js_value,
          worklet_instance_js_value, args_wrapper.WrapJSValue(), component_obj);

  return call_result_value;
}

/**
 * @brief LEPUS_Call a function, its arguments are append with componentInstance
 * @return std::optional<lepus::Value> Return std::nullopt when failed,
 * otherwise return lepus::Value
 */
std::optional<lepus::Value> LepusElement::CallLepusWithComponentInstance(
    lynx::tasm::TemplateAssembler* tasm, LEPUSContext* ctx,
    const LEPUSValue& func_obj, const LEPUSValue& this_obj,
    const LEPUSValue& args, const LEPUSValue& component_instance) {
  if (tasm == nullptr) {
    return std::nullopt;
  }

  std::vector<LEPUSValue> lepus_call_args;

  lepus_call_args.push_back(args);
  lepus_call_args.push_back(component_instance);

  lepus::Value call_result_wrapper = lepus::Value(
      ctx, LEPUS_Call(ctx, func_obj, this_obj,
                      static_cast<int>(lepus_call_args.size()),
                      static_cast<LEPUSValue*>(lepus_call_args.data())));
  const auto call_result_js_value = call_result_wrapper.WrapJSValue();

  if (LEPUS_IsException(call_result_js_value)) {
    std::ostringstream ss;
    ss << "Worklet call function failed." << std::endl;
    auto exception_wrapper = lepus::Value(ctx, LEPUS_GetException(ctx));
    auto exception_js_value = exception_wrapper.WrapJSValue();
    const auto& msg =
        lepus::LepusErrorHelper::GetErrorMessage(ctx, exception_js_value);
    const auto& stack =
        lepus::LepusErrorHelper::GetErrorStack(ctx, exception_js_value);
    ss << "The error message is : " << std::endl;
    ss << msg << std::endl;
    ss << "The call stack is : " << std::endl;
    ss << stack << std::endl;
    tasm->ReportError(LYNX_ERROR_CODE_LEPUS_CALL_EXCEPTION, ss.str());

    return std::nullopt;
  }

  return call_result_wrapper;
}

void LepusElement::SetStyles(const Napi::Object& styles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::SetStyles");
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::SetStyles failed, since element is null.");
    return;
  }

  const auto& lepus_v = ValueConverter::ConvertNapiValueToLepusValue(styles);
  if (!lepus_v.IsTable()) {
    LOGE("LepusElement::SetStyles failed, since input para is not object.");
    return;
  }

  for (const auto& pair : *(lepus_v.Table())) {
    const auto& key = tasm::CSSProperty::GetPropertyID(pair.first);
    element->SetStyle(tasm::UnitHandler::Process(
        key, pair.second, element->element_manager()->GetCSSParserConfigs()));
  }
  element->element_manager()->root()->UpdateDynamicElementStyle();
  element->FlushProps();
}

void LepusElement::SetAttributes(const Napi::Object& attributes) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::SetAttributes");
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::SetAttributes failed, since element is null.");
    return;
  }

  const auto& lepus_v =
      ValueConverter::ConvertNapiValueToLepusValue(attributes);
  if (!lepus_v.IsTable()) {
    LOGE(
        "Element Worklet SetAttributes failed, since input para is not "
        "object.");
    return;
  }

  for (const auto& pair : *(lepus_v.Table())) {
    element->SetAttribute(pair.first, pair.second);
    constexpr const static char* kText = "text";
    if (pair.first.IsEqual(kText) && element->data_model() != nullptr &&
        element->data_model()->tag().IsEqual(kText)) {
      for (size_t i = 0; i < element->GetChildCount(); ++i) {
        const auto& c = element->GetChildAt(i);
        static_cast<tasm::Element*>(c)->SetAttribute(pair.first, pair.second);
        static_cast<tasm::Element*>(c)->FlushProps();
      }
    }
  }
  element->FlushProps();
}

Napi::Object LepusElement::GetComputedStyles(
    const std::vector<Napi::String>& keys) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::GetComputedStyles");
  auto res = Napi::Object::New(Env());
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::GetStyles failed, since element is null.");
    return res;
  }

  const auto& styles = element->styles();
  for (const auto& key : keys) {
    auto iter =
        styles.find(tasm::CSSProperty::GetPropertyID(key.Utf8Value().c_str()));
    if (iter == styles.end()) {
      res.Set(key, Env().Undefined());
    } else {
      res.Set(key, Napi::String::New(Env(), tasm::CSSDecoder::CSSValueToString(
                                                iter->first, iter->second)));
    }
  }

  constexpr const static char* kScrollView = "scroll-view";
  constexpr const static char* kXScrollView = "x-scroll-view";
  if (element->GetTag() == kScrollView || element->GetTag() == kXScrollView) {
    constexpr const static char* kDisplay = "display";
    constexpr const static char* kLinear = "linear";
    res.Set(Napi::String::New(Env(), kDisplay),
            Napi::String::New(Env(), kLinear));
  }

  return res;
}

Napi::Object LepusElement::GetAttributes(
    const std::vector<Napi::String>& keys) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::GetAttributes");
  auto res = Napi::Object::New(Env());
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::GetAttributes failed, since element is null.");
    return res;
  }

  const auto& attributes = element->attributes().Table();
  if (attributes->size() <= 0) {
    LOGI(
        "Element Worklet GetAttributes failed, since element's attributes is "
        "empty.");
    return res;
  }
  for (const auto& key : keys) {
    auto iter = attributes->find(key.Utf8Value());
    if (iter == attributes->end()) {
      res.Set(key, Env().Undefined());
    } else {
      res.Set(key, ValueConverter::ConvertLepusValueToNapiValue(Env(),
                                                                iter->second));
    }
  }
  return res;
}

Napi::Object LepusElement::GetDataset() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::GetDataset");
  auto env = Env();
  auto res = Napi::Object::New(env);
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::GetDataset failed, since element is null.");
    return res;
  }

  auto data_model = element->data_model();
  if (data_model == nullptr) {
    LOGI(
        "Element Worklet GetDataset failed, since element's data_model is "
        "null.");
    return res;
  }

  const auto& data_set = data_model->dataset();
  if (data_set.empty()) {
    LOGI(
        "Element Worklet GetDataset failed, since data_model's data_set is "
        "empty.");
    return res;
  }
  for (const auto& pair : data_set) {
    res.Set(Napi::String::New(env, pair.first.str()),
            ValueConverter::ConvertLepusValueToNapiValue(env, pair.second));
  }
  return res;
}

Napi::Value LepusElement::ScrollBy(float width, float height) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::ScrollBy");
  auto env = Env();
  Napi::Object obj = Napi::Object::New(env);
  std::vector<float> res{0, 0, width, height};
  auto element = GetElement();

  if (element != nullptr) {
    res = element->ScrollBy(
        width * starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX,
        height * starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  } else {
    LOGE("LepusElement::ScrollBy failed, since element is null.");
  }
  constexpr const static char* kConsumedX = "consumedX";
  constexpr const static char* kConsumedY = "consumedY";
  constexpr const static char* kUnConsumedX = "unconsumedX";
  constexpr const static char* kUnConsumedY = "unconsumedY";

  obj.Set(kConsumedX,
          res[0] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kConsumedY,
          res[1] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kUnConsumedX,
          res[2] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kUnConsumedY,
          res[3] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  return obj;
}

Napi::Value LepusElement::GetBoundingClientRect() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::GetBoundingClientRect");
  auto env = Env();
  Napi::Object obj = Napi::Object::New(env);
  auto element = GetElement();
  if (element == nullptr) {
    return obj;
  }
  const auto& res = element->GetRectToLynxView();
  constexpr const static int32_t kSize = 4;
  if (res.size() != kSize) {
    return obj;
  }

  constexpr const static char* kLeft = "left";
  constexpr const static char* kTop = "top";
  constexpr const static char* kRight = "right";
  constexpr const static char* kBottom = "bottom";
  constexpr const static char* kWidth = "width";
  constexpr const static char* kHeight = "height";

  obj.Set(kLeft, res[0] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kTop, res[1] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kWidth, res[2] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kHeight, res[3] / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kRight,
          (res[0] + res[2]) / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  obj.Set(kBottom,
          (res[1] + res[3]) / starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX);
  return obj;
}

void LepusElement::Invoke(const Napi::Object& object) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LepusElement::Invoke");
  auto element = GetElement();
  if (element == nullptr) {
    LOGE("LepusElement::Invoke failed since element is null.");
    return;
  }

  if (!object.IsObject()) {
    LOGE("LepusElement::Invoke failed since param is not a object.");
    return;
  }

  constexpr const static char* sKeyMethod = "method";
  constexpr const static char* sKeyParams = "params";
  constexpr const static char* sKeySuccess = "success";
  constexpr const static char* sKeyFail = "fail";

  if (!object.Has(sKeyMethod) || !object.Get(sKeyMethod).IsString()) {
    LOGE("LepusElement::Invoke failed since param doesn't contain "
         << sKeyMethod << ", or it is not string");
    return;
  }

  const static auto& get_func_persistent = [](Napi::Env env, Napi::Value val) {
    Napi::Value fuc = val.IsFunction() ? val : Napi::Value();
    return Napi::Persistent(fuc);
  };

  auto success_p = get_func_persistent(Env(), object.Get(sKeySuccess));
  auto fail_p = get_func_persistent(Env(), object.Get(sKeyFail));

  element->Invoke(
      object.Get(sKeyMethod).ToString().Utf8Value(),
      ValueConverter::ConvertNapiValueToLepusValue(object.Get(sKeyParams)),
      [env = Env(), &success_p, &fail_p](int32_t code,
                                         const lepus::Value& data) {
        std::vector<napi_value> args{};
        args.push_back(Napi::Number::New(env, code));
        args.push_back(
            ValueConverter::ConvertLepusValueToNapiObject(env, data));
        if (code == 0 && success_p.Value().IsFunction()) {
          success_p.Value().As<Napi::Function>().Call(args);
        } else if (fail_p.Value().IsFunction()) {
          fail_p.Value().As<Napi::Function>().Call(args);
        }
      });
}
}  // namespace worklet
}  // namespace lynx
