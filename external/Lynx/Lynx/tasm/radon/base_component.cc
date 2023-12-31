// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/base_component.h"

#include <map>
#include <set>

#include "tasm/base/base_def.h"
#include "tasm/config.h"
#include "tasm/value_utils.h"

#ifdef ENABLE_TEST_DUMP
#include "lepus/json_parser.h"
#endif

namespace lynx {
namespace tasm {

const char* BaseComponent::kCreated = "created";
const char* BaseComponent::kAttached = "attached";
const char* BaseComponent::kReady = "ready";
const char* BaseComponent::kDetached = "detached";
const char* BaseComponent::kMoved = "moved";
const char* BaseComponent::kClassName = "className";
const char* BaseComponent::kIdSelector = "id";
const char* BaseComponent::kRootCSSId = ":root";

void BaseComponent::UpdateTable(lepus::Value& target,
                                const lepus::Value& update, bool reset) {
  if (update.IsEmpty()) return;
  if (reset) {
    target.SetTable(lepus::Dictionary::Create());
  }
  lepus::Value::MergeValue(target, update);
}

void BaseComponent::SetData(const lepus::String& key,
                            const lepus::Value& value) {
  data_.SetProperty(key, value);
}

bool BaseComponent::UpdateGlobalProps(const lepus::Value& table) {
  if (!NeedsExtraData()) {
    // If there is no need for extra data, do not set GlobalProps to data to
    // avoid extra copy.
    return false;
  }

  if (!data_.IsEqual(table)) {
    if (!table.IsNil()) {
      DCHECK(table.IsObject());
      data_.SetProperty(kGlobalPropsKey, table);
      return true;
    }
  }
  return false;
}

void BaseComponent::SetProperties(const lepus::String& key,
                                  const lepus::Value& value,
                                  AttributeHolder* holder,
                                  bool strict_prop_type) {
  if (IsPropertiesUndefined(value) && ShouldBlockEmptyProperty()) {
    return;
  }
  if (!properties_.IsObject()) {
    properties_ = lepus::Value(lepus::Dictionary::Create());
  }
  static base::NoDestructor<std::set<std::string>> kAttributeNames({
    "flatten",
#if ENABLE_RENDERKIT
        "focusable", "focus-index",
#endif
  });
  if (kAttributeNames->find(key.str()) != kAttributeNames->end()) {
    if (!holder->attributes_[key.str()].first.IsEqual(value)) {
      holder->SetDynamicAttribute(key, value);
      properties_dirty_ = true;
    }
  } else {
    const lepus::Value& v = properties_.GetProperty(key);
    // if value type mismatch, set value to default.
    // default_value.IsNil() means any type is permitted.
    bool same_type =
        v.Type() == value.Type() || (v.IsNumber() && value.IsNumber());
    bool use_default_value = strict_prop_type && !v.IsNil() && !same_type;
    lepus::Value new_value = use_default_value ? GetDefaultValue(v) : value;
    if (!(v == new_value)) {
      properties_.SetProperty(key, new_value);
      properties_dirty_ = true;
    }
  }

  // Each property may also be an external class mapping.
  // This is done at run time since there's no way to tell if a prop is also
  // declared as an external class for <component is="{{}}"/>.
  if (value.IsString() && !value.String()->empty()) {
    SetExternalClass(key, value.String());
  }
}

CSSFragment* BaseComponent::GetStyleSheetBase(AttributeHolder* holder) {
  if (!style_sheet_) {
    if (!intrinsic_style_sheet_ && style_sheet_manager_ != nullptr) {
      intrinsic_style_sheet_ =
          style_sheet_manager_->GetCSSStyleSheetForComponent(mould_->css_id());
    }
    style_sheet_ =
        std::make_shared<CSSFragmentDecorator>(intrinsic_style_sheet_);
    if (intrinsic_style_sheet_ && style_sheet_ &&
        intrinsic_style_sheet_->HasTouchPseudoToken()) {
      style_sheet_->MarkHasTouchPseudoToken();
    }
    PrepareComponentExternalStyles(holder);
    PrepareRootCSSVariables(holder);
  }
  return style_sheet_.get();
}

const std::string& BaseComponent::GetEntryName() const { return entry_name_; }

void BaseComponent::ExtractExternalClass(ComponentMould* data) {
  if (data->external_classes().IsArrayOrJSArray()) {
    for (int i = 0; i < data->external_classes().GetLength(); ++i) {
      const auto& item = data->external_classes().GetProperty(i);
      if (item.IsString()) {
        external_classes_[item.String()] = ClassList();
      }
    }
  }
}

void BaseComponent::PrepareComponentExternalStyles(AttributeHolder* holder) {
  // Make sure we look for external. Return when this is top level component.
  if (IsPageForBaseComponent()) {
    return;
  }

  CSSFragmentDecorator* style_sheet =
      static_cast<CSSFragmentDecorator*>(holder->ParentStyleSheet());
  if (!style_sheet) {
    return;
  }
  for (const auto& pair : external_classes_) {
    for (const auto& clazz : pair.second) {
      const std::string rule = std::string(".") + clazz.c_str();
      auto token = style_sheet->GetSharedCSSStyle(rule);

      if (token) {
        // Translate into component class names and store.
        const std::string new_rule = std::string(".") + pair.first.c_str();
        style_sheet_->AddExternalStyle(new_rule, std::move(token));
      }
    }
  }
}

static void update_root_css_variable(
    AttributeHolder* holder, const std::shared_ptr<CSSParseToken>& root) {
  auto& variables = root->GetStyleVariables();
  if (variables.empty()) {
    return;
  }

  for (const auto& it : variables) {
    CSSVariableMap map = holder->css_variables_map();
    if (map.find(it.first) == map.end()) {
      holder->UpdateCSSVariable(it.first, it.second);
    }
  }
}

void BaseComponent::PrepareRootCSSVariables(AttributeHolder* holder) {
  // component may be empty
  if (!intrinsic_style_sheet_) {
    return;
  }

  auto* rule_set = intrinsic_style_sheet_->rule_set();
  if (rule_set) {
    const auto& root_css_token = rule_set->GetRootToken();
    if (root_css_token) {
      update_root_css_variable(holder, root_css_token);
    }
    return;
  }
  auto root_css = intrinsic_style_sheet_->css().find(kRootCSSId);
  if (root_css != intrinsic_style_sheet_->css().end()) {
    update_root_css_variable(holder, root_css->second);
  }
}

void BaseComponent::UpdateSystemInfo(const lynx::lepus::Value& info) {
  if (!NeedsExtraData()) {
    // If there is no need for extra data, do not set SystemInfo to data
    // to avoid extra copy.
    return;
  }

  data_.SetProperty(kSystemInfo, info);
  data_dirty_ = true;
}

void BaseComponent::SetExternalClass(const lepus::String& key,
                                     const lepus::String& value) {
  if (external_classes_.find(key) != external_classes_.end()) {
    external_classes_[key].clear();
    std::vector<std::string> classes;
    base::SplitString(value.str(), ' ', classes);
    for (const std::string& clazz : classes) {
      external_classes_[key].push_back(clazz);
    }
  }
}

void BaseComponent::DeriveFromMould(ComponentMould* data) {
  if (data != nullptr) {
    init_properties_ = data->properties();
    init_data_ = data->data();
    properties_ = lepus::Value::Clone(init_properties_, IsInLepusNGContext());
    data_ = lepus::Value::Clone(init_data_, IsInLepusNGContext());

    ExtractExternalClass(data);

    if (data->GetComponentConfig() != nullptr) {
      remove_extra_data_ =
          data->GetComponentConfig()->GetEnableRemoveExtraData();
    }
  }

  // make sure the data is table
  if (!data_.IsObject()) {
    data_ = lepus::Value(lepus::Dictionary::Create());
  }

  if (!properties_.IsObject()) {
    properties_ = lepus::Value(lepus::Dictionary::Create());
  }
}

lepus_value BaseComponent::PreprocessData() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PreprocessData");
  if (get_derived_state_from_props_function_.IsCallable() && context_) {
    lepus_value data = context_->CallWithClosure(
        get_derived_state_from_props_function_, {properties_, data_});
    return data;
  }
  return lepus::Value();
}

lepus_value BaseComponent::PreprocessErrorData() {
  if (dsl_ == PackageInstanceDSL::REACT &&
      get_derived_state_from_error_function_.IsCallable() && context_) {
    lepus_value data = context_->CallWithClosure(
        get_derived_state_from_error_function_, {render_error_});
    return data;
  }
  return lepus::Value();
}

bool BaseComponent::PreRender(const RenderType& render_type) {
  if (dsl_ == PackageInstanceDSL::REACT) {
    return PreRenderReact(render_type);
  }
  return PreRenderTT(render_type);
}

bool BaseComponent::PreRenderReact(const RenderType& render_type) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PreRenderReact");
  switch (render_type) {
    case RenderType::UpdateFromJSBySelf:
      return true;
    case RenderType::FirstRender:
    case RenderType::UpdateByParentComponent:
    case RenderType::UpdateByNativeList:
    case RenderType::UpdateByNative: {
      lepus_value new_data;
      if (get_derived_state_from_props_function_.IsCallable()) {
        new_data = PreprocessData();
        if (new_data.IsObject()) {
          UpdateTable(data_, new_data);
          LOGI("getDerivedStateFromProps component " << this->path().c_str());
        }

        // Add extra version fields when there could be conflicts for native
        // and JS to update data simultaneously. For child components this
        // could happen with getDerivedStateFromProps() generating states from
        // props set by its parent.
        AttachDataVersions(new_data);
      }
      //
      // case 'RenderType::FirstRender' don't execute 'shouldComponentUpdate'
      //
      if (render_type == RenderType::FirstRender) {
        return true;
      }

      //
      // check shouldComponentUpdate
      // case 'RenderType::UpdateByParentComponent' and
      // 'RenderType::UpdateByNative'
      //
      bool should_component_update = ShouldComponentUpdate();
      OnReactComponentRenderBase(new_data, should_component_update);
      return should_component_update;
    }
    case RenderType::UpdateByRenderError: {
      lepus_value new_data{};
      if (get_derived_state_from_error_function_.IsCallable()) {
        new_data = PreprocessErrorData();
        if (new_data.IsObject()) {
          new_data.SetProperty(lepus::String(REACT_RENDER_ERROR_KEY),
                               lepus::Value(LEPUS_RENDER_ERROR));
          UpdateTable(data_, new_data);
          LOGI("UpdateByRenderError" << this->path().c_str()
                                     << ", new_data: " << new_data);
        }
        AttachDataVersions(new_data);
      }
      // clear render error info, then call js render
      SetRenderError(lepus::Value());
      OnReactComponentRenderBase(new_data, true);
      return true;
    }
    default:
      break;
  }
  return true;
}

BaseComponent* BaseComponent::GetErrorBoundary() {
  BaseComponent* parent_node = this->GetParentComponent();
  while (parent_node != nullptr) {
    if (parent_node->get_derived_state_from_error_function_.IsCallable()) {
      return parent_node;
    }
    parent_node = parent_node->GetParentComponent();
  }
  return nullptr;
}

void BaseComponent::AttachDataVersions(lepus::Value& update_data) {
  // List descendants don't support states currently, but unfortunately they are
  // used anyway (e.g. issue #4249). Don't try to mess with those.
  if (IsInList()) {
    return;
  }

  if (update_data.IsNil()) {
    update_data.SetTable(lepus::Dictionary::Create());
  }

  // Version starts from 0, 0 means JS side has not sent any update yet.
  int64_t ui_data_version = 0;
  if (data_.Contains(REACT_NATIVE_STATE_VERSION_KEY)) {
    ui_data_version =
        data_.GetProperty(REACT_NATIVE_STATE_VERSION_KEY).Number();
  }
  ++ui_data_version;
  lepus::Value ui_version_value(ui_data_version);
  data_.SetProperty(REACT_NATIVE_STATE_VERSION_KEY, ui_version_value);
  update_data.SetProperty(REACT_NATIVE_STATE_VERSION_KEY, ui_version_value);
  update_data.SetProperty(REACT_JS_STATE_VERSION_KEY,
                          data_.GetProperty(REACT_JS_STATE_VERSION_KEY));

  LOGI("AttachDataVersions native: "
       << ui_data_version
       << ", js: " << data_.GetProperty(REACT_JS_STATE_VERSION_KEY).Number()
       << ", path: " << path().str());
}

void BaseComponent::ResetDataVersions() {
  // List descendants don't support states currently, but unfortunately they are
  // used anyway (e.g. issue #4249). Don't try to mess with those.
  if (IsInList()) {
    return;
  }

  // Reset both ui and js versions to 0 (which is the default value)
  // ui version will be bumped up to 1 by AttachDataVersions later
  lepus::Value ui_version_value(0);
  lepus::Value js_version_value(0);
  data_.SetProperty(REACT_NATIVE_STATE_VERSION_KEY, ui_version_value);
  data_.SetProperty(REACT_JS_STATE_VERSION_KEY, js_version_value);

  LOGI("ResetDataVersions native: " << 0 << ", js: " << 0
                                    << ", path: " << path().str());
}

bool BaseComponent::PreRenderTT(const RenderType& render_type) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PreRenderTT");
  if (render_type == RenderType::UpdateFromJSBySelf) {
    // update from js, no need to call `getDerivedStateFromProps`
    return ShouldComponentUpdate();
  }
  lepus_value new_data;
  if (get_derived_state_from_props_function_.IsCallable()) {
    new_data = PreprocessData();
    if (new_data.IsObject()) {
      UpdateTable(data_, new_data);
      LOGI("getDerivedStateFromProps for TTML component "
           << this->path().c_str());
    }
  }

  // check shouldComponentUpdate
  return render_type == RenderType::FirstRender || ShouldComponentUpdate();
}

bool BaseComponent::ShouldComponentUpdate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ShouldComponentUpdate");
  if (should_component_update_function_.IsCallable() && context_) {
    lepus::Value result = context_->CallWithClosure(
        should_component_update_function_,
        {properties_, data_, pre_properties_, pre_data_});
    if (result.IsBool()) {
      return result.Bool();
    }
    LOGE("ShouldComponentUpdate should return bool value!");
  }
  return true;
}

bool BaseComponent::CheckReactShouldAbortUpdating(lepus::Value table) {
  if (table.Contains(REACT_NATIVE_STATE_VERSION_KEY)) {
    int64_t expected_native_state_version =
        table.GetProperty(REACT_NATIVE_STATE_VERSION_KEY).Number();
    int64_t ui_data_version =
        data_.GetProperty(REACT_NATIVE_STATE_VERSION_KEY).Number();
    // List descendants don't support states currently, but unfortunately they
    // are used anyway (e.g. issue #4249). Don't try to mess with those.
    if (!IsInList() && expected_native_state_version < ui_data_version) {
      LOGI("CheckReactShouldAbortUpdating conflicts detected, "
           << "expecting native version: " << expected_native_state_version
           << ", actual version: " << ui_data_version << ", aborting");
      return true;
    }
    // Update versions upfront for later correct determination of "data changed"
    data_.SetProperty(REACT_NATIVE_STATE_VERSION_KEY,
                      table.GetProperty(REACT_NATIVE_STATE_VERSION_KEY));
    data_.SetProperty(REACT_JS_STATE_VERSION_KEY,
                      table.GetProperty(REACT_JS_STATE_VERSION_KEY));
  }
  return false;
}

bool BaseComponent::CheckReactShouldComponentUpdateKey(lepus::Value table) {
  if (table.IsObject() && table.Contains(REACT_SHOULD_COMPONENT_UPDATE_KEY)) {
    bool should_component_render =
        table.GetProperty(REACT_SHOULD_COMPONENT_UPDATE_KEY).Bool();
    if (!should_component_render) {
      ForEachLepusValue(
          table, [this](const lepus::Value& key, const lepus::Value& value) {
            if (key.String()->str() != REACT_SHOULD_COMPONENT_UPDATE_KEY) {
              this->data_.SetProperty(key.String(), value);
            }
          });
      return true;
    }
  }
  return false;
}

bool BaseComponent::CheckReactShouldAbortRenderError(lepus::Value table) {
  if (table.Contains(REACT_RENDER_ERROR_KEY)) {
    if (table.GetProperty(REACT_RENDER_ERROR_KEY).String()->str() ==
            JS_RENDER_ERROR ||
        table.GetProperty(REACT_RENDER_ERROR_KEY).String()->str() ==
            LEPUS_RENDER_ERROR) {
      LOGI("CheckReactShouldAbortRenderError");
      SetRenderError(lepus::Value());
      return true;
    }
  }
  return false;
}

#ifdef ENABLE_TEST_DUMP
rapidjson::Value BaseComponent::DumpComponentInfoMap(rapidjson::Document& doc) {
  auto comp = [](const lepus::String& lhs, const lepus::String& rhs) {
    return lhs.str() < rhs.str();
  };
  std::map<lepus::String, lepus::Value, decltype(comp)>
      ordered_component_info_map(component_info_map().Table()->begin(),
                                 component_info_map().Table()->end(), comp);

  rapidjson::Document::AllocatorType& allocator = doc.GetAllocator();
  rapidjson::Value component_info_value;
  component_info_value.SetObject();

  for (auto it = ordered_component_info_map.begin();
       it != ordered_component_info_map.end(); ++it) {
    rapidjson::Value key((it->first).str(), allocator);
    lepus::Value lepus_val = it->second;
    std::string json_str = lepusValueToJSONString(lepus_val);
    rapidjson::Value val(json_str, allocator);
    component_info_value.AddMember(key, val, allocator);
  }
  return component_info_value;
}
#endif

BaseComponent::ComponentType BaseComponent::GetComponentType(
    const std::string& name) const {
  lepus::Dictionary& map = *(component_info_map().Table().Get());
  const auto& iter = map.find(name);
  if (iter == map.end()) {
    return BaseComponent::ComponentType::kUndefined;
  }
  const auto& info = iter->second;
  if (!info.IsArrayOrJSArray()) {
    return BaseComponent::ComponentType::kUndefined;
  }
  if (info.GetLength() < 1) {
    return BaseComponent::ComponentType::kUndefined;
  }
  auto id = info.GetProperty(0);
  if (!id.IsNumber()) {
    return BaseComponent::ComponentType::kUndefined;
  }
  if (id.Number() < 0) {
    return BaseComponent::ComponentType::kDynamic;
  }
  return BaseComponent::ComponentType::kStatic;
}

lepus::Value BaseComponent::GetDefaultValue(
    const lepus::Value& template_value) {
  lepus::Value default_value;
  switch (template_value.Type()) {
    case lepus::Value_Double:
    case lepus::Value_NaN:
      default_value.SetNumber(static_cast<double>(0.0));
      break;
    case lepus::Value_Bool:
      default_value.SetBool(false);
      break;
    case lepus::Value_String:
      default_value.SetString(lepus::StringImpl::Create(""));
      break;
    case lepus::Value_Int32:
      default_value.SetNumber(static_cast<int32_t>(0));
      break;
    case lepus::Value_Int64:
      default_value.SetNumber(static_cast<int64_t>(0));
      break;
    case lepus::Value_UInt32:
      default_value.SetNumber(static_cast<uint32_t>(0));
      break;
    case lepus::Value_UInt64:
      default_value.SetNumber(static_cast<uint64_t>(0));
      break;
    case lepus::Value_Table:
      default_value.SetTable(lepus::Dictionary::Create());
      break;
    case lepus::Value_Array:
      default_value.SetArray(lepus::CArray::Create());
      break;
    case lepus::Value_Nil:
      default_value.SetNil();
      break;
    case lepus::Value_Undefined:
      default_value.SetUndefined();
      break;
    default:
      default_value = template_value;
  }
  return default_value;
}

}  // namespace tasm
}  // namespace lynx
