#include "tasm/radon/radon_dynamic_component.h"

#include <utility>

#include "base/log/logging.h"
#include "tasm/base/base_def.h"
#include "tasm/base/tasm_utils.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

namespace {
/**
 * |-code: int
 * └ data
 *   |-url: string
 *   |-sync: bool
 *   └ error_msg: string
 * └ detail (compatible with old formats)
 *   |-schema: string
 *   |-cache: bool (meaningless now)
 *   └ errMsg: string
 */
lepus::Value ConstructEventMessage(const std::string& url,
                                   bool need_compatibility,
                                   int code = LYNX_ERROR_CODE_SUCCESS,
                                   const std::string& error_msg = "",
                                   bool sync = false) {
  constexpr static const char* kCode = "code";
  constexpr static const char* kData = "data";
  constexpr static const char* kUrl = "url";
  constexpr static const char* kErrorMsg = "error_msg";
  // following keys are deprecated
  constexpr static const char* kSchema = "schema";
  constexpr static const char* kErrMsg = "errMsg";
  constexpr static const char* kCache = "cache";

  auto event_message = lepus::Dictionary::Create();

  // attach code
  event_message->SetValue(kCode, lepus::Value(code));

  // attach data
  auto lepus_url = lepus::Value(url);
  auto lepus_msg = lepus::Value(error_msg);
  event_message->SetValue(
      kData,
      lepus::Value(lepus::Dictionary::Create({
          {lepus::String(kUrl), lepus_url},
          {lepus::String(RadonDynamicComponent::kSync), lepus::Value(sync)},
          {lepus::String(kErrorMsg), lepus_msg},
      })));

  // attach detail if need to be compatible with old formats
  if (need_compatibility) {
    event_message->SetValue(RadonDynamicComponent::kDetail,
                            lepus::Value(lepus::Dictionary::Create({
                                {lepus::String(kSchema), lepus_url},
                                {lepus::String(kCache), lepus::Value(false)},
                                {lepus::String(kErrMsg), lepus_msg},
                            })));
  }

  return lepus::Value(event_message);
}
}  // namespace

uint32_t RadonDynamicComponent::uid_generator_ = 0;

RadonDynamicComponent::RadonDynamicComponent(
    TemplateAssembler* tasm, const std::string& entry_name,
    PageProxy* page_proxy, int tid, CSSFragment* style_sheet,
    std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
    ComponentMould* mould, lepus::Context* context, uint32_t node_index,
    const lepus::Value& global_props, const lepus::String& tag_name)
    : RadonComponent(page_proxy, tid, style_sheet, style_sheet_manager, mould,
                     context, node_index, tag_name),
      tasm_(tasm),
      uid_(++uid_generator_) {
  node_type_ = kRadonDynamicComponent;
  entry_name_ = entry_name;
  UpdateDynamicCompTopLevelVariables(mould, global_props);
}

RadonDynamicComponent::RadonDynamicComponent(TemplateAssembler* tasm,
                                             const std::string& entry_name,
                                             PageProxy* page_proxy, int tid,
                                             uint32_t node_index,
                                             const lepus::String& tag_name)
    : RadonComponent(page_proxy, tid, nullptr, nullptr, nullptr, nullptr,
                     node_index, tag_name),
      tasm_(tasm),
      uid_(++uid_generator_) {
  node_type_ = kRadonDynamicComponent;
  entry_name_ = entry_name;
  SetPath(lynx::lepus::StringImpl::Create(""));
}

RadonDynamicComponent::RadonDynamicComponent(const RadonDynamicComponent& node,
                                             PtrLookupMap& map)
    : RadonComponent(node, map), tasm_(nullptr), uid_(node.Uid()) {
  node_type_ = kRadonDynamicComponent;
}

void RadonDynamicComponent::InitDynamicComponent(
    CSSFragment* style_sheet,
    std::shared_ptr<CSSStyleSheetManager> style_sheet_manager,
    ComponentMould* mould, lepus::Context* context) {
  context_ = context;
  mould_ = mould;
  style_sheet_manager_ = std::move(style_sheet_manager);
  intrinsic_style_sheet_ = style_sheet;
  DeriveFromMould(mould);
}

void RadonDynamicComponent::SetGlobalProps(const lepus::Value& global_props) {
  UpdateDynamicCompTopLevelVariables(mould_, global_props);
}

void RadonDynamicComponent::UpdateDynamicCompTopLevelVariables(
    ComponentMould* data, const lepus::Value& global_props) {
  if (data == nullptr || !data->data().IsObject() || context_ == nullptr) {
    return;
  }

  ForEachLepusValue(
      data->data(), [this](const lepus::Value& key, const lepus::Value& value) {
        context_->UpdateTopLevelVariable(key.String()->str(), value);
      });

  // update for SystemInfo
  context_->UpdateTopLevelVariable(kSystemInfo, GenerateSystemInfo(nullptr));
  // update for globalProps
  UpdateGlobalProps(global_props);
}

void RadonDynamicComponent::DeriveFromMould(ComponentMould* data) {
  // In the case of DynamicComponent, DerivedFromMould maybe called after
  // setProps(Async Mode) We should merge the initProps and incoming properties.
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              LYNX_TRACE_DYNAMIC_COMPONENT_DERIVE_FROM_MODULE);
  if (data != nullptr) {
    init_properties_ =
        lepus::Value::Clone(data->properties(), IsInLepusNGContext());
    init_data_ = lepus::Value::Clone(data->data(), IsInLepusNGContext());

    if (!init_properties_.IsObject()) {
      init_properties_ = lepus::Value(lepus::Dictionary::Create());
    }

    if (!init_data_.IsObject()) {
      init_data_ = lepus::Value(lepus::Dictionary::Create());
    }

    lepus::Value::MergeValue(init_properties_, properties_);
    lepus::Value::MergeValue(init_data_, data_);

    data_ = init_data_;
    properties_ = init_properties_;
    ExtractExternalClass(data);
  }

  // make sure the data is table
  if (!data_.IsObject()) {
    data_ = lepus::Value(lepus::Dictionary::Create());
  }

  if (!properties_.IsObject()) {
    properties_ = lepus::Value(lepus::Dictionary::Create());
  }

  UpdateSystemInfo(GenerateSystemInfo(nullptr));
}

void RadonDynamicComponent::CreateComponentInLepus() RADON_ONLY {
  if (context_ && !page_proxy_->IsRadonDiff()) {
    lepus::Value p1(this);
    lepus::Value p2(data_);
    lepus::Value p3(properties_);
    context_->Call("$createEntranceDynamicComponent", {p1, p2, p3});
  }
}

void RadonDynamicComponent::UpdateComponentInLepus() RADON_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              LYNX_TRACE_DYNAMIC_COMPONENT_DERIVE_FROM_MODULE);
  if (context_ && !page_proxy_->IsRadonDiff()) {
    lepus::Value p1(this);
    lepus::Value p2(data_);
    lepus::Value p3(properties_);
    context_->Call("$updateEntranceDynamicComponent", {p1, p2, p3});
    update_function_called_ = true;
  }
}

bool RadonDynamicComponent::SetContext(TemplateAssembler* tasm) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_SET_CONTEXT);
  auto entry = tasm->RequireTemplateEntry(this, entry_name_);
  if (entry == nullptr) {
    return false;
  }
  // For dynamic component entry,
  // dynamic_component_moulds[0] must be itself.
  auto cm_it = entry->dynamic_component_moulds().find(0);
  if (cm_it == entry->dynamic_component_moulds().end()) {
    return false;
  }
  ComponentMould* cm = cm_it->second.get();
  context_ = entry->GetVm().get();
  mould_ = cm;
  DeriveFromMould(cm);
  UpdateDynamicCompTopLevelVariables(cm, tasm->GetGlobalProps());
  style_sheet_.reset();
  intrinsic_style_sheet_ =
      entry->GetStyleSheetManager()->GetCSSStyleSheetForComponent(cm->css_id());
  SetPath(lynx::lepus::StringImpl::Create(cm->path()));
  if (tasm->GetPageDSL() == PackageInstanceDSL::REACT) {
    SetGetDerivedStateFromErrorProcessor(tasm->GetComponentProcessorWithName(
        path().c_str(), REACT_ERROR_PROCESS_LIFECYCLE, context_->name()));
  }
  SetGetDerivedStateFromPropsProcessor(tasm->GetComponentProcessorWithName(
      path().c_str(), REACT_PRE_PROCESS_LIFECYCLE, context_->name()));
  SetShouldComponentUpdateProcessor(tasm->GetComponentProcessorWithName(
      path().c_str(), REACT_SHOULD_COMPONENT_UPDATE, context_->name()));
  return true;
}

void RadonDynamicComponent::RenderRadonComponent(RenderOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              LYNX_TRACE_DYNAMIC_COMPONENT_RENDER_ENTRANCE);
  if (!IsEmpty()) {
    lepus::Value p1(this);
    lepus::Value p2(data_);
    lepus::Value p3(properties_);
    lepus::Value p4(option.recursively);
    context_->Call("$renderEntranceDynamicComponent", {p1, p2, p3, p4});
  }
}

bool RadonDynamicComponent::LoadDynamicComponent(const std::string& url,
                                                 TemplateAssembler* tasm,
                                                 const uint32_t uid) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_LOAD);
  if (url != entry_name_ || uid != uid_) {
    return false;
  }

  if (!IsEmpty()) {
    LOGE("Unexpected RadonDynamicComponent: "
         << entry_name_ << ", id: " << ComponentId()
         << ", unempty component was reloaded incorrectly.");
    return false;
  }

  if (!SetContext(tasm)) {
    LOGE("Unexpected RadonDynamicComponent: "
         << entry_name_ << ", id: " << ComponentId()
         << ", empty component fails to be set context.");
    return false;
  }

  DispatchForRender();
  fallback_.reset(nullptr);
  return true;
};

void RadonDynamicComponent::DispatchForRender() {
  PreRender(RenderType::FirstRender);
  dispatched_ = false;
  DispatchOption option(page_proxy_);
  if (page_proxy_->IsRadonDiff()) {
    // radon diff
    DispatchForDiff(option);
  } else {
    // radon
    CreateComponentInLepus();
    UpdateComponentInLepus();
    Dispatch(option);
  }
}

const std::string& RadonDynamicComponent::GetEntryName() const {
  return entry_name_;
}

bool RadonDynamicComponent::UpdateGlobalProps(const lepus::Value& table) {
  if (!table.IsObject()) {
    return false;
  }
  auto global_props = table.ToLepusValue();
  BaseComponent::UpdateGlobalProps(global_props);
  context_->UpdateTopLevelVariable(kGlobalPropsKey, global_props);
  return true;
}

bool RadonDynamicComponent::CanBeReusedBy(
    const RadonBase* const radon_base) const {
  if (!RadonComponent::CanBeReusedBy(radon_base)) {
    return false;
  }
  // In this case, radon_base's node_type must by kRadonDynamicComponent
  // because node_type has been checked in RadonBase::CanBeReusedBy()
  const RadonDynamicComponent* const component =
      static_cast<const RadonDynamicComponent* const>(radon_base);
  return entry_name_ == component->GetEntryName() &&
         IsEmpty() == component->IsEmpty() &&
         remove_component_element_ == component->remove_component_element_;
}

void RadonDynamicComponent::SetProperties(const lepus::String& key,
                                          const lepus::Value& value,
                                          AttributeHolder* holder,
                                          bool strict_prop_type) {
  auto properties = value.ToLepusValue();
  BaseComponent::SetProperties(key, properties, holder, strict_prop_type);
}

void RadonDynamicComponent::SetData(const lepus::String& key,
                                    const lepus::Value& value) {
  auto data = value.ToLepusValue();
  BaseComponent::SetData(key, data);
}

bool RadonDynamicComponent::NeedsExtraData() const {
  // remove dynamic component's extra data
  // only when component "enableRemoveComponentExtraData: true"
  if (remove_extra_data_ == BooleanProp::TrueValue) {
    return false;
  }
  return true;
}

RadonDynamicComponent* RadonDynamicComponent::CreateRadonDynamicComponent(
    TemplateAssembler* tasm, const std::string& url, const lepus::String& name,
    int tid, uint32_t index) {
  auto* comp =
      new RadonDynamicComponent(tasm, url, tasm->page_proxy(), tid, index);
  auto entry = tasm->RequireTemplateEntry(comp, url);
  if (entry != nullptr) {
    auto cm_it = entry->dynamic_component_moulds().find(0);
    if (cm_it != entry->dynamic_component_moulds().end()) {
      ComponentMould* cm = cm_it->second.get();
      auto context = entry->GetVm().get();
      comp->InitDynamicComponent(nullptr, entry->GetStyleSheetManager(), cm,
                                 context);
      comp->SetPath(lynx::lepus::StringImpl::Create(cm->path()));
      comp->SetGlobalProps(tasm->GetGlobalProps());

      if (comp->dsl() == PackageInstanceDSL::REACT) {
        comp->SetGetDerivedStateFromErrorProcessor(
            tasm->GetComponentProcessorWithName(comp->path().c_str(),
                                                REACT_ERROR_PROCESS_LIFECYCLE,
                                                context->name()));
      }

      comp->SetGetDerivedStateFromPropsProcessor(
          tasm->GetComponentProcessorWithName(comp->path().c_str(),
                                              REACT_PRE_PROCESS_LIFECYCLE,
                                              context->name()));
      comp->SetShouldComponentUpdateProcessor(
          tasm->GetComponentProcessorWithName(comp->path().c_str(),
                                              REACT_SHOULD_COMPONENT_UPDATE,
                                              context->name()));
    }
  }
  comp->SetName(name);
  comp->SetDSL(tasm->GetPageDSL());
  return comp;
}

void RadonDynamicComponent::OnComponentAdopted() {
  if (IsEmpty()) {
    if (state_ == DynamicCompState::STATE_FAIL) {
      // IF dynamic component is loaded failed here, this means dynamic
      // component is loaded in sync mode and loaded failed now! Trigger
      // bindError Here.
      tasm_->SendDynamicComponentEvent(entry_name_, error_msg_, ImplId());
    }
  }
}

lepus::Value RadonDynamicComponent::ConstructSuccessLoadInfo(
    const std::string& url, bool cache) {
  return ConstructEventMessage(url, true);
}

lepus::Value RadonDynamicComponent::ConstructFailLoadInfo(
    const std::string& url, int32_t code, const std::string& msg) {
  return ConstructEventMessage(url, true, code, msg);
}

lepus::Value RadonDynamicComponent::ConstructErrMsg(
    const std::string& url, const int code, const std::string& error_msg,
    bool sync) {
  return ConstructEventMessage(url, false, code, error_msg, sync);
}

void RadonDynamicComponent::CreateAndAdoptFallback(
    std::unique_ptr<RadonPlug> plug) {
  auto fallback_slot = new RadonSlot(plug->plug_name());
  AddChild(std::unique_ptr<RadonBase>(fallback_slot));
  AdoptPlugToSlot(fallback_slot, std::move(plug));
}

void RadonDynamicComponent::AddFallback(std::unique_ptr<RadonPlug> fallback) {
  // dynamic component loaded successfully does not need fallback
  if (!fallback || !IsEmpty()) {
    return;
  }

  switch (state_) {
    case DynamicCompState::STATE_UNKNOW:
      fallback_ = std::move(fallback);
      break;
    case DynamicCompState::STATE_FAIL:
      CreateAndAdoptFallback(std::move(fallback));
      break;
    default:
      break;
  }
}

bool RadonDynamicComponent::RenderFallback() {
  if (fallback_) {
    CreateAndAdoptFallback(std::move(fallback_));
    DispatchForRender();
    return true;
  }
  return false;
}

}  // namespace tasm
}  // namespace lynx
