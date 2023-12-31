// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_ELEMENT_AIR_COMPONENT_ELEMENT_H_
#define LYNX_TASM_AIR_AIR_ELEMENT_AIR_COMPONENT_ELEMENT_H_

#include <memory>
#include <vector>

#include "tasm/air/air_element/air_element.h"
#include "tasm/moulds.h"

namespace lynx {
namespace tasm {

class AirComponentElement : public AirElement {
 public:
  AirComponentElement(ElementManager* manager, int tid, uint32_t lepus_id,
                      int32_t id, lepus::Context* context);
  AirComponentElement(const AirComponentElement& node, AirPtrLookUpMap& map);
  void DeriveFromMould(ComponentMould* mould);

  bool is_component() const override { return true; }

  void SetName(const lepus::String& name) { name_ = name; }
  void SetPath(const lepus::String& path) { path_ = path; }

  void SetProperty(const lepus::String& key, const lepus::Value& value);
  void SetProperties(const lepus::Value& value);
  void SetData(const lepus::Value& data);
  void SetData(const lepus::String& key, const lepus::Value& value);
  lepus::Value GetProperties() override { return properties_; };
  lepus::Value GetData() override { return data_; };

  void CreateComponentInLepus();
  bool UpdateComponentInLepus(const lepus::Value& data);

  uint32_t NonVirtualNodeCountInParent() override;

  void OnElementRemoved() override;

 private:
  lepus::Value data_{};
  lepus::Value properties_{};
  lepus::String name_;
  lepus::String path_;
  int32_t tid_;
  lepus::Context* context_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_AIR_AIR_ELEMENT_AIR_COMPONENT_ELEMENT_H_
