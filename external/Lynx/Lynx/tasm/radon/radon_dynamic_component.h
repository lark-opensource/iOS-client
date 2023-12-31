// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_DYNAMIC_COMPONENT_H_
#define LYNX_TASM_RADON_RADON_DYNAMIC_COMPONENT_H_

#include <memory>
#include <string>

#include "tasm/radon/radon_component.h"

namespace lynx {

namespace tasm {

class TemplateAssembler;

enum class DynamicCompState : uint8_t {
  STATE_UNKNOW = 0,
  STATE_SUCCESS = 1,
  STATE_FAIL = 2
};

struct DynamicComponentLoadFailMsg {
  std::string error_msg_;
  int error_code_;
  bool sync_;  // whether the dynamic component is loaded in sync mode.
};

class RadonDynamicComponent : public RadonComponent {
 public:
  constexpr static const char* const kEventFail = "fail";
  // todo(@nihao) supported later.
  constexpr static const char* const kEventSuccess = "success";
  constexpr static const char* const kDetail = "detail";
  constexpr static const char* const kSync = "sync";

  RadonDynamicComponent(
      TemplateAssembler* tasm, const std::string& entry_name,
      PageProxy* page_proxy, int tid, CSSFragment* style_sheet,
      std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
      ComponentMould* mould, lepus::Context* context, uint32_t node_index,
      const lepus::Value& global_props,
      const lepus::String& tag_name = "component");

  // construct an empty component
  // context_, mould_, intrinsic_style_sheet_ are nullptr;
  // path_ is empty;
  RadonDynamicComponent(TemplateAssembler* tasm, const std::string& entry_name,
                        PageProxy* page_proxy, int tid, uint32_t node_index,
                        const lepus::String& tag_name = "component");

  RadonDynamicComponent(const RadonDynamicComponent& node, PtrLookupMap& map);

  void InitDynamicComponent(
      CSSFragment* style_sheet,
      std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
      ComponentMould* mould, lepus::Context* context);

  void SetGlobalProps(const lepus::Value& global_props);
  void DeriveFromMould(ComponentMould* data) override;

  void UpdateDynamicCompTopLevelVariables(ComponentMould* data,
                                          const lepus::Value& global_props);

  bool NeedsExtraData() const override;

  virtual void CreateComponentInLepus() RADON_ONLY override;

  virtual void UpdateComponentInLepus() RADON_ONLY override;

  bool LoadDynamicComponent(const std::string& url, TemplateAssembler* tasm,
                            const uint32_t uid);

  virtual const std::string& GetEntryName() const override;
  virtual bool UpdateGlobalProps(const lepus::Value& table) override;

  virtual bool CanBeReusedBy(const RadonBase* const radon_base) const override;

  virtual void SetProperties(const lepus::String& key,
                             const lepus::Value& value, AttributeHolder* holder,
                             bool strict_prop_type) override;

  virtual void SetData(const lepus::String& key,
                       const lepus::Value& value) override;

  static RadonDynamicComponent* CreateRadonDynamicComponent(
      TemplateAssembler* tasm, const std::string& url,
      const lepus::String& name, int tid, uint32_t index);

  static lepus::Value ConstructSuccessLoadInfo(const std::string& url,
                                               bool cache);

  static lepus::Value ConstructFailLoadInfo(const std::string& url,
                                            int32_t code,
                                            const std::string& msg);

  static lepus::Value ConstructErrMsg(const std::string& url, const int code,
                                      const std::string& error_msg, bool sync);
  bool SetContext(TemplateAssembler* tasm);

  void OnComponentAdopted();

  inline void SetDynamicComponentState(DynamicCompState state,
                                       lepus::Value msg = lepus::Value()) {
    state_ = state;
    error_msg_ = msg;
  }

  inline DynamicCompState GetDynamicComponentState() const { return state_; }

  inline lepus::Value& GetErrorMsg() { return error_msg_; };

  uint32_t Uid() const { return uid_; }

  void AddFallback(std::unique_ptr<RadonPlug> fallback);

  // try to render fallback if it exists
  bool RenderFallback();

 private:
  // create a new slot to adopt fallback plug
  void CreateAndAdoptFallback(std::unique_ptr<RadonPlug> fallback);
  // dispatch for render when LoadComponentWithCallback or show fallback if
  // failed
  void DispatchForRender();

  DynamicCompState state_{DynamicCompState::STATE_UNKNOW};
  lepus::Value error_msg_;
  TemplateAssembler* tasm_;
  virtual void RenderRadonComponent(RenderOption&) override RADON_DIFF_ONLY;

  // only use for dynamic component require callback
  uint32_t uid_;
  static uint32_t uid_generator_;

  std::unique_ptr<RadonPlug> fallback_{nullptr};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_DYNAMIC_COMPONENT_H_
