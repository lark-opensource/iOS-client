// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_BASE_COMPONENT_H_
#define LYNX_TASM_RADON_BASE_COMPONENT_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/trace_event/trace_event.h"
#include "css/css_fragment_decorator.h"
#include "css/css_style_sheet_manager.h"
#include "lepus/context.h"
#include "lepus/value.h"
#include "tasm/attribute_holder.h"
#include "tasm/component_config.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/moulds.h"
#include "tasm/radon/set_css_variable_op.h"

#ifdef ENABLE_TEST_DUMP
#include "third_party/rapidjson/document.h"
#endif

namespace lynx {
namespace tasm {

using SetCSSVariableOpVector = std::vector<SetCSSVariableOp>;

class BaseComponent {
 public:
  const static char* kCreated;
  const static char* kAttached;
  const static char* kReady;
  const static char* kDetached;
  const static char* kMoved;
  const static char* kClassName;
  const static char* kIdSelector;
  const static char* kRootCSSId;

  enum class RenderType {
    FirstRender,
    UpdateByNative,
    UpdateFromJSBySelf,
    UpdateByParentComponent,
    UpdateByRenderError,
    UpdateByNativeList,
  };

  // usually used to create component or dynamic component
  enum class ComponentType { kUndefined = 0, kStatic, kDynamic };

  BaseComponent(ComponentMould* mould, lepus::Context* context,
                CSSFragment* style_sheet,
                std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
                int32_t tid)
      : mould_(mould),
        context_(context),
        dsl_(tasm::PackageInstanceDSL::TT),
        tid_(tid),
        intrinsic_style_sheet_(style_sheet),
        style_sheet_manager_(std::move(style_sheet_manager)) {
    if (mould) {
      DeriveFromMould(mould);
    }
  }

  static void UpdateTable(lepus::Value& target, const lepus::Value& update,
                          bool reset = false);

  virtual bool UpdateGlobalProps(const lepus::Value& table);

  const std::unordered_map<lepus::String, ClassList>& external_classes() const {
    return external_classes_;
  }

  std::unordered_map<std::string, lepus::Value>& worklet_instances() {
    return worklet_instances_;
  }

  void InsertWorklet(std::string worklet_name, const lepus::Value& worklet) {
    worklet_instances_[worklet_name] = worklet;
  }

  virtual void SetProperties(const lepus::String& key,
                             const lepus::Value& value, AttributeHolder* holder,
                             bool strict_prop_type);

  // methods to check properties undefined.
  // it's result will differ according to pageConfig `enableComponentNullProps`
  virtual bool IsPropertiesUndefined(const lepus::Value& value) const {
    return false;
  }

  virtual void SetData(const lepus::String& key, const lepus::Value& value);
  void UpdateSystemInfo(const lynx::lepus::Value& info);

  inline void SetDSL(PackageInstanceDSL dsl) { dsl_ = dsl; }
  inline PackageInstanceDSL GetDSL() { return dsl_; }
  inline PackageInstanceDSL dsl() { return dsl_; }
  inline bool IsReact() { return dsl_ == PackageInstanceDSL::REACT; }

  void ExtractExternalClass(ComponentMould* data);

  void SetName(const lepus::String& name) { name_ = name; }
  void SetPath(const lepus::String& path) { path_ = path; }

  const lepus::Value& data() { return data_; }
  const lepus::Value& properties() { return properties_; }
  const lepus::Value& GetStyleVariables() { return style_variables_; }
  const lepus::Value& GetInitialData() { return init_data_; }

  virtual CSSFragment* GetStyleSheetBase(AttributeHolder* holder);

  virtual int ComponentId() = 0;
  virtual std::string ComponentStrId() {
    return std::to_string(ComponentId());
  };
  virtual AttributeHolder* GetAttributeHolder() = 0;
  /*
   * GetParentComponent() is used to find the component's parent component.
   * In this method, we will recursively traversal the component's parent
   * and return the first other component or page we found.
   */
  virtual BaseComponent* GetParentComponent() = 0;
  /*
   * GetComponentOfThisComponent() will directly call the component's
   * component() in virtual component or radon component. In radon it just
   * return radon_component_ and in VDOM it just return component_.
   *
   * In most case GetParentComponent() and GetComponentOfThisComponent() will
   * return the same component except the case of slot&plug.
   *
   * For example, component A has a child component B, and B has a slot,
   * component A provides a plug and the plug contains a component C. If we
   * called C->GetComponentOfThisComponent() we would get A, but if we called
   * C->GetParentComponent() we would get B.
   */
  virtual BaseComponent* GetComponentOfThisComponent() = 0;
  virtual const std::string& GetEntryName() const;

  const lepus::String& name() const { return name_; }
  const lepus::String& path() const { return path_; }

  void SetExternalClass(const lepus::String& key, const lepus::String& value);
  bool IsInLepusNGContext() { return context_ && context_->IsLepusNGContext(); }

  virtual void DeriveFromMould(ComponentMould* data);

  virtual bool IsPageForBaseComponent() const { return false; }

  virtual const lepus::Value& component_info_map() const {
    return component_info_map_;
  }

  virtual const lepus::Value& component_path_map() const {
    return component_path_map_;
  }

  int32_t tid() { return tid_; }

  lepus::Value& component_info_map() {
    return const_cast<lepus_value&>(
        static_cast<const BaseComponent&>(*this).component_info_map());
  }
  lepus::Value& component_path_map() {
    return const_cast<lepus_value&>(
        static_cast<const BaseComponent&>(*this).component_path_map());
  }

  void PrepareComponentExternalStyles(AttributeHolder* holder);

  void PrepareRootCSSVariables(AttributeHolder* holder);

  virtual void SetGetDerivedStateFromPropsProcessor(
      const lepus::Value& processor) {
    get_derived_state_from_props_function_ = processor;
  }

  virtual void SetGetDerivedStateFromErrorProcessor(
      const lepus::Value& processor) {
    get_derived_state_from_error_function_ = processor;
  }

  virtual void SetRenderError(const lepus::Value& error) {
    render_error_ = error;
  }

  virtual void SetShouldComponentUpdateProcessor(
      const lepus::Value& processor) {
    should_component_update_function_ = processor;
  }

  bool PreRender(const RenderType& render_type);

  inline void set_pre_properties(const lepus::Value& properties) {
    pre_properties_ = properties;
  }
  inline void set_pre_data(const lepus::Value& data) { pre_data_ = data; }

  bool ShouldComponentUpdate();

  lepus_value PreprocessData();

  BaseComponent* GetErrorBoundary();

  lepus_value PreprocessErrorData();

#ifdef ENABLE_TEST_DUMP
  rapidjson::Value DumpComponentInfoMap(rapidjson::Document& doc);
#endif
  inline lepus::Value inner_state() const { return inner_state_; }
  inline void set_inner_state(const lepus::Value& state) {
    inner_state_ = state;
  }

  // Only when a dynamic component is loaded async, it could be empty.
  bool IsEmpty() const { return context_ == nullptr; }

  ComponentType GetComponentType(const std::string& info) const;

  const std::shared_ptr<ComponentConfig>& GetComponentConfig() const {
    return mould_->GetComponentConfig();
  }

  virtual bool ShouldBlockEmptyProperty() { return false; };
  int32_t GetCSSId() const { return mould_->css_id(); }

 protected:
  virtual void OnReactComponentRenderBase(lepus::Value& new_data,
                                          bool should_component_update) = 0;
  void AttachDataVersions(lepus::Value& update_data);
  void ResetDataVersions();
  enum class InListStatus {
    Unknown,
    InList,
    NotInList,
  };
  virtual bool IsInList() = 0;
  virtual bool NeedsExtraData() const = 0;
  BooleanProp remove_extra_data_{BooleanProp::NotSet};
  bool CheckReactShouldAbortUpdating(lepus::Value table);
  bool CheckReactShouldComponentUpdateKey(lepus::Value table);
  bool CheckReactShouldAbortRenderError(lepus::Value table);

  lepus::Value get_derived_state_from_props_function_;
  lepus::Value should_component_update_function_;
  lepus::Value get_derived_state_from_error_function_;
  lepus::Value render_error_{};

  // Key: lepus::String / value: lepus::Value
  // props and data should be initialized as Value_Nil and then get derived from
  // mould.
  lepus::Value properties_{};
  lepus::Value data_{};
  lepus::Value init_properties_{};
  lepus::Value init_data_{};

  lepus::Value style_variables_{};

  lepus::String name_;
  lepus::String path_;

  mutable std::string entry_name_{};

  ComponentMould* mould_;
  lepus::Context* context_;

  std::unordered_map<lepus::String, ClassList> external_classes_;
  std::unordered_map<std::string, lepus::Value> worklet_instances_;
  lepus::Value inner_state_{};

  PackageInstanceDSL dsl_;
  int32_t tid_;

  bool data_dirty_{true};
  bool properties_dirty_{true};

  // The style sheet containing only the corresponding css file's content.
  CSSFragment* intrinsic_style_sheet_ = nullptr;
  std::shared_ptr<CSSStyleSheetManager> style_sheet_manager_;
  // The lazy-constructed style sheet taking external classes into account.
  std::shared_ptr<CSSFragmentDecorator> style_sheet_;

  lepus::Value component_info_map_ = lepus::Value(lepus::Dictionary::Create());
  lepus::Value component_path_map_ = lepus::Value(lepus::Dictionary::Create());

  InListStatus in_list_status_ = InListStatus::Unknown;
  SetCSSVariableOpVector set_variable_ops_;

 private:
  bool PreRenderReact(const RenderType& render_type);
  bool PreRenderTT(const RenderType& render_type);
  static lepus::Value GetDefaultValue(const lepus::Value& template_value);

  lepus::Value pre_properties_;
  lepus::Value pre_data_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_BASE_COMPONENT_H_
