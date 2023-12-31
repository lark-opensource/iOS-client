// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_page_element.h"

#include "tasm/air/air_element/air_component_element.h"
#include "tasm/air/air_element/air_for_element.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

namespace {
constexpr static const char *kOnDataChanged = "onDataChanged";
}  // namespace

bool AirPageElement::UpdatePageData(
    const lepus::Value &table, const UpdatePageOption &update_page_option) {
  auto array = lepus::CArray::Create();
  bool need_update = false;
  lepus::Value new_data;
  if (update_page_option.reload_template ||
      update_page_option.reset_page_data) {
    // reset to default Card data, then update by table
    new_data = lepus::Value::Clone(init_data_);
    tasm::ForEachLepusValue(
        table, [&new_data](const lepus::Value &key, const lepus::Value &value) {
          new_data.SetProperty(key.String(), value);
        });

  } else {
    new_data = table;
  }

  if (update_page_option.update_first_time) {
    if (!table.IsEmpty()) {
      data_ = new_data;
    }
  } else {
    tasm::ForEachLepusValue(
        new_data, [this, &need_update, array](const lepus::Value &key,
                                              const lepus::Value &value) {
          lepus::Value ret = data_.GetProperty(key.String()->str());
          if (!ret.IsEmpty()) {
            if (CheckTableShadowUpdated(ret, value) ||
                value.GetLength() != ret.GetLength()) {
              array->push_back(key);
              data_.SetProperty(key.String()->str(), value);
              need_update = true;
            }
          } else {
            array->push_back(key);
            data_.SetProperty(key.String()->str(), value);
            need_update = true;
          }
        });
  }

  if (need_update) {
    std::string timing_flag = tasm::GetTimingFlag(table);
    tasm::TimingCollector::Scope<TemplateAssembler::Delegate> scope(
        &(context_->GetTasmPointer()->GetDelegate()), timing_flag);
    // UpdatePage0 for first screen is called in
    // TemplateAssembler::RenderTemplateForAir
    element_manager()->painting_context()->MarkUIOperationQueueFlushTiming(
        tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_START, timing_flag);

    if (!update_page_option.update_first_time &&
        !update_page_option.from_native) {
      if (!timing_flag.empty()) {
        tasm::TimingCollector::Instance()->Mark(
            tasm::TimingKey::UPDATE_SET_STATE_TRIGGER);
      }
    }

    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_REFRESH_PAGE_START_AIR);

    if (is_radon_) {
      lepus::Value params(
          AirLepusRef::Create(element_manager()->air_node_manager()->Get(
              element_manager()->AirRoot()->impl_id())));
      context_->Call("$updatePage0", {params});
    } else {
      lepus::Value params(array);
      lepus::Value data(data_);
      lepus::Value page_id(element_manager()->AirRoot()->impl_id());
      context_->Call("$updatePage0", {params, data, page_id});
    }

    tasm::TimingCollector::Instance()->Mark(
        tasm::TimingKey::UPDATE_REFRESH_PAGE_END_AIR);

    LOGI("lynx_air, UpdatePageData, first_time="
         << update_page_option.update_first_time);
    // trigger lifecycle event
    if (!update_page_option.update_first_time &&
        update_page_option.from_native) {
      auto *tasm = context_->GetTasmPointer();
      if (tasm) {
        tasm->SendAirPageEvent(kOnDataChanged, lepus_value());
      }
    }
    PipelineOptions options;
    options.has_patched = true;
    // trigger onTimingUpdate
    options.timing_flag = timing_flag;

    element_manager()->OnPatchFinishInnerForAir(options);
  }
  return true;
}

bool AirPageElement::RefreshWithGlobalProps(const lynx::lepus::Value &table,
                                            bool should_render) {
  constexpr const static char *kGlobalPropsKey = "__globalProps";
  context_->UpdateTopLevelVariable(kGlobalPropsKey, table);
  return true;
}

void AirPageElement::DeriveFromMould(ComponentMould *data) {
  if (data == nullptr || !data->data().IsObject()) {
    return;
  }

  if (context_->IsLepusNGContext()) {
    init_data_ = lepus::Value(
        context_->context(), data->data().ToJSValue(context_->context(), true));
  } else {
    init_data_ = data->data();
  }

  data_ = lepus::Value::Clone(init_data_, context_->IsLepusNGContext());

  // make sure the data is table
  if (!data_.IsObject()) {
    data_ = lepus::Value::CreateObject(context_);
  }
}

lepus::Value AirPageElement::GetData() { return lepus::Value(data_); }

uint64_t AirPageElement::GetKeyForCreatedElement(uint32_t lepus_id) {
  uint64_t key = static_cast<uint64_t>(lepus_id);
  auto *for_element = this->GetCurrentForElement();
  auto *component_element = this->GetCurrentComponentElement();
  // If both the for element and component element are not null, this means that
  // the current element is both under the for and component. Check which is
  // 'closer', and use the closer element to determine the unique key. According
  // to the generation order, the later the element is created, the greater
  // lepus id.
  // For for element, use the unique id and active index to compute the unique
  // key. The unique id and the active index of for element are both 32 bits.
  // Shift the unique id and then perform a bitwise OR operation on active
  // index. This will generate a unique key. Compared to using strings as key,
  // computation of numbers is much more efficient. For component, just use the
  // unique id as the key.
  static const uint8_t shift = 32;
  if (for_element && component_element) {
    auto for_lepus_id = for_element->GetLepusId();
    auto comp_lepus_id = component_element->GetLepusId();
    int for_impl_id = for_element->impl_id();
    int comp_impl_id = component_element->impl_id();
    if (for_lepus_id > comp_lepus_id) {
      key = static_cast<uint64_t>(for_impl_id) << shift |
            static_cast<uint64_t>(for_element->ActiveIndex());
    } else {
      key = static_cast<uint64_t>(comp_impl_id);
    }
  } else if (for_element) {
    key = static_cast<uint64_t>(for_element->impl_id()) << shift |
          static_cast<uint64_t>(for_element->ActiveIndex());
  } else if (component_element) {
    key = static_cast<uint64_t>(component_element->impl_id());
  }
  return key;
}

void AirPageElement::FireComponentLifeCycleEvent(const std::string &name,
                                                 int component_id) {
  auto *tasm = context_->GetTasmPointer();
  tasm->SendAirComponentEvent(name, component_id, lepus::Value(), "");
}

}  // namespace tasm
}  // namespace lynx
