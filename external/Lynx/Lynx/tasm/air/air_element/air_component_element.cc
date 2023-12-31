// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_component_element.h"

#include <memory>
#include <string>

#include "base/string/string_utils.h"
#include "tasm/air/air_element/air_page_element.h"
#include "tasm/react/element_manager.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

namespace {
constexpr static const char *kComponentDetached = "detached";

}  // namespace

AirComponentElement::AirComponentElement(ElementManager *manager, int tid,
                                         uint32_t lepus_id, int32_t id,
                                         lepus::Context *context)
    : AirElement(kAirComponent, manager, kAirComponentTag, lepus_id, id),
      tid_(tid),
      context_(context) {}

AirComponentElement::AirComponentElement(const AirComponentElement &node,
                                         AirPtrLookUpMap &map)
    : AirElement{node, map},
      name_(node.name_),
      path_(node.path_),
      tid_(node.tid_),
      context_(node.context_) {
  AirElement *node_parent = const_cast<AirComponentElement &>(node).parent();
  if (map.find(node_parent) != map.end()) {
    set_parent(map[node_parent]);
  }
  ForEachLepusValue(node.properties_,
                    [this](const lepus::Value &key, const lepus::Value &value) {
                      this->SetProperty(key.String(), value);
                    });
  ForEachLepusValue(node.data_,
                    [this](const lepus::Value &key, const lepus::Value &value) {
                      this->SetData(key.String(), value);
                    });
}

void AirComponentElement::DeriveFromMould(ComponentMould *mould) {
  if (mould != nullptr) {
    properties_ = lepus::Value::Clone(mould->properties(),
                                      context_ && context_->IsLepusNGContext());
    data_ = lepus::Value::Clone(mould->data(),
                                context_ && context_->IsLepusNGContext());
  }
  if (!data_.IsObject()) {
    data_ = lepus::Value::CreateObject(context_);
  }
  if (!properties_.IsObject()) {
    properties_ = lepus::Value::CreateObject(context_);
  }
}

void AirComponentElement::SetProperties(const lepus::Value &value) {
  if (value.IsObject()) {
    properties_ = value;
  }
}

void AirComponentElement::SetProperty(const lepus::String &key,
                                      const lepus::Value &value) {
  const lepus::Value &v = properties_.GetProperty(key);
  if (CheckTableValueNotEqual(v, value)) {
    properties_.SetProperty(key, value);
  }
}

void AirComponentElement::SetData(const lepus::Value &data) {
  if (data.IsObject() && UpdateComponentInLepus(data)) {
    PipelineOptions options;
    options.has_patched = true;
    element_manager()->OnPatchFinishInnerForAir(options);
  }
}

void AirComponentElement::SetData(const lepus::String &key,
                                  const lepus::Value &value) {
  const lepus::Value &v = data_.GetProperty(key);
  if (CheckTableValueNotEqual(v, value)) {
    data_.SetProperty(key, value);
  }
}

void AirComponentElement::CreateComponentInLepus() {
  if (!data_.IsObject()) {
    data_ = lepus::Value(lepus::Dictionary::Create());
  }
  lepus::Value p1(AirLepusRef::Create(
      element_manager()->air_node_manager()->Get(impl_id())));
  lepus::Value p2(data_);
  lepus::Value p3(properties_);
  context_->Call("$createComponent" + std::to_string(tid_), {p1, p2, p3});
}

bool AirComponentElement::UpdateComponentInLepus(const lepus::Value &data) {
  auto updated_keys = lepus::CArray::Create();
  tasm::ForEachLepusValue(
      data,
      [this, updated_keys](const lepus::Value &key, const lepus::Value &value) {
        lepus::Value ret = data_.GetProperty(key.String()->str());
        if (!ret.IsEmpty()) {
          if (CheckTableShadowUpdated(ret, value) ||
              value.GetLength() != ret.GetLength()) {
            updated_keys->push_back(key);
            data_.SetProperty(key.String()->str(), value);
          }
        } else {
          updated_keys->push_back(key);
          data_.SetProperty(key.String()->str(), value);
        }
      });
  // In unittest, context_ will be nullptr(lepus function named $updateComponent
  // is undefined also).
  if (context_ && updated_keys->size()) {
    lepus::Value p1(AirLepusRef::Create(
        element_manager()->air_node_manager()->Get(impl_id())));
    context_->Call("$updateComponent",
                   {p1, data_, properties_, lepus::Value(path_.str()),
                    lepus::Value(updated_keys)});
  }
  return updated_keys->size();
}

uint32_t AirComponentElement::NonVirtualNodeCountInParent() {
  uint32_t sum = 0;
  for (auto child : air_children_) {
    sum += child->NonVirtualNodeCountInParent();
  }
  return sum;
}

void AirComponentElement::OnElementRemoved() {
  element_manager()->AirRoot()->FireComponentLifeCycleEvent(kComponentDetached,
                                                            impl_id());
}

}  // namespace tasm
}  // namespace lynx
