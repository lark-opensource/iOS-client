// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_ELEMENT_AIR_PAGE_ELEMENT_H_
#define LYNX_TASM_AIR_AIR_ELEMENT_AIR_PAGE_ELEMENT_H_

#include <memory>
#include <string>
#include <vector>

#include "lepus/value.h"
#include "tasm/air/air_element/air_element.h"
#include "tasm/compile_options.h"
#include "tasm/page_proxy.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

class AirComponentElement;
class AirForElement;

class AirPageElement : public AirElement {
 public:
  constexpr const static char* kDefaultPageTag = "page";

  AirPageElement(ElementManager* manager, uint32_t lepus_id, int32_t id = -1)
      : AirElement(kAirPage, manager, kDefaultPageTag, lepus_id, id) {
    manager->SetRootOnLayout(layout_node());
    manager->catalyzer()->set_air_root(this);
    manager->SetAirRoot(this);
  }

  bool UpdatePageData(const lepus::Value& table,
                      const UpdatePageOption& update_page_option);

  void SetContext(lepus::Context* context) { context_ = context; }

  void SetRadon(bool is_radon) { is_radon_ = is_radon; }
  bool IsRadon() const { return is_radon_; }

  bool RefreshWithGlobalProps(const lynx::lepus::Value& table,
                              bool should_render);

  void DeriveFromMould(ComponentMould* data);

  bool is_page() const override { return true; }

  /**
   * save stack of for_element
   */
  void PushForElement(AirForElement* for_element) {
    for_stack_.push_back(for_element);
  };
  void PopForElement() { for_stack_.pop_back(); };

  AirForElement* GetCurrentForElement() {
    return for_stack_.size() ? for_stack_.back() : nullptr;
  };

  /**
   * stack for component
   */
  void PushComponentElement(AirComponentElement* component) {
    component_stack_.push_back(component);
  }
  void PopComponentElement() { component_stack_.pop_back(); }

  AirComponentElement* GetCurrentComponentElement() {
    return component_stack_.size() ? component_stack_.back() : nullptr;
  }

  lepus::Value GetData() override;
  lepus::Value GetProperties() override { return lepus::Value(); }

  uint64_t GetKeyForCreatedElement(uint32_t lepus_id);

  // Trigger Component LifeCycle Event.
  void FireComponentLifeCycleEvent(const std::string& name, int component_id);

 private:
  lepus::Context* context_;
  std::vector<AirForElement*> for_stack_;
  std::vector<AirComponentElement*> component_stack_;
  std::unique_ptr<lepus::Value> current_page_data_;
  bool is_radon_{false};

  lepus::Value init_data_{};
  lepus::Value data_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_AIR_AIR_ELEMENT_AIR_PAGE_ELEMENT_H_
