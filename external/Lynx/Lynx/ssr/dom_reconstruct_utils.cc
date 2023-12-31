// Copyright 2022 The Lynx Authors. All rights reserved.
#include "ssr/dom_reconstruct_utils.h"

#include <map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "lepus/json_parser.h"
#include "ssr/ssr_node_key.h"
#include "tasm/attribute_holder.h"
#include "tasm/config.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_base.h"
#include "tasm/radon/radon_factory.h"
#include "tasm/radon/radon_slot.h"
#include "tasm/radon/radon_types.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace ssr {

namespace {

static constexpr char kSSRPlaceHolderMagicPrefix[] = "$_ph{";
static constexpr char kSSRPlaceHolderMagicSuffix[] = "}hp_#";
static constexpr size_t kSSRPlaceHolderMagicPrefixLength = 5;
static constexpr size_t kSSRPlaceHolderMagicSuffixLength = 5;

// Will replace the magic words works as a placeholder for SSR in place if
// possible. And will return the replaced value anyways even if the value cannot
// be replaced in place.
// The name of placeholder variable will be enclosed by $_ph{ }ph_# pattern.
// Find all the placeholder variable name and replace it with injected data from
// client.
lepus::Value ReplacePlaceholdersForString(lepus::Value value,
                                          const lepus::Value& dict) {
  // Calling value.String() may return a local shared pointer, hold that to
  // avoid deconstruct.
  const auto& lepus_string = value.String();
  const auto& str = lepus_string->str();

  auto prefix_start = str.find(kSSRPlaceHolderMagicPrefix);
  auto suffix_start = str.find(kSSRPlaceHolderMagicSuffix, prefix_start);
  if (prefix_start == 0 &&
      suffix_start + kSSRPlaceHolderMagicSuffixLength == str.size()) {
    return dict.GetProperty(str.substr(
        kSSRPlaceHolderMagicPrefixLength,
        suffix_start - prefix_start - kSSRPlaceHolderMagicPrefixLength));
  }

  // Placeholders injected inside a string.
  // Now only string injected data is supported if the placeholder is put within
  // a string.
  if (prefix_start != std::string::npos && suffix_start != std::string::npos) {
    std::string result;
    size_t last_suffix_end = 0;
    // A $_ph{ }ph_# enclosed placeholder variable is found in string.
    while (prefix_start != std::string::npos &&
           suffix_start != std::string::npos) {
      // Append the substring before the placeholder variable to result string.
      result =
          result + str.substr(last_suffix_end, prefix_start - last_suffix_end);
      // Append the replaced value to string.
      lepus::Value dict_value = dict.GetProperty(str.substr(
          kSSRPlaceHolderMagicPrefixLength + prefix_start,
          suffix_start - prefix_start - kSSRPlaceHolderMagicPrefixLength));
      result += lepusValueToString(dict_value);
      // Find next enclosed placeholder variable.
      prefix_start = str.find(kSSRPlaceHolderMagicPrefix,
                              suffix_start + kSSRPlaceHolderMagicSuffixLength);
      last_suffix_end = suffix_start + kSSRPlaceHolderMagicSuffixLength;
      suffix_start = str.find(kSSRPlaceHolderMagicSuffix, prefix_start);
    }
    // Append the rest of string,
    // if there is some string after all the placeholder variables.
    if (last_suffix_end < str.length()) {
      result = result + str.substr(last_suffix_end);
    }
    return lepus::Value(lepus::StringImpl::Create(result));
  } else {
    return value;
  }
}

lepus::Value ReplacePlaceholdersInPlaceIfPossible(lepus::Value value,
                                                  const lepus::Value& dict) {
  switch (value.Type()) {
    case lepus::Value_Table: {
      auto table = value.Table();
      for (auto& it : *table) {
        it.second = ReplacePlaceholdersInPlaceIfPossible(it.second, dict);
      }
      return lepus::Value(table);
    }
    case lepus::Value_Array: {
      auto array = value.Array();
      for (int i = 0; static_cast<size_t>(i) < array->size(); ++i) {
        array->set(i,
                   ReplacePlaceholdersInPlaceIfPossible(array->get(i), dict));
      }
      return lepus::Value(array);
    }
    case lepus::Value_String: {
      return ReplacePlaceholdersForString(value, dict);
    }
    default:
      return value;
  }
}

void LoadNodeValue(tasm::RadonNode* this_node, const lepus::CArray& typed_info,
                   const lepus::Value& dict) {
  this_node->MarkAllDynamic();

  // attributes
  auto attributes = typed_info.get(ssr::RadonNodeKey::kAttributes).Table();

  for (auto& itr : *attributes) {
    this_node->SetDynamicAttribute(
        itr.first, ReplacePlaceholdersInPlaceIfPossible(itr.second, dict));
  }
  // style
  auto styles = typed_info.get(ssr::RadonNodeKey::kStyles).Array();
  size_t style_size = styles->size();
  for (size_t idx = 0; idx < style_size; ++idx) {
    auto style = styles->get(idx).Array();
    tasm::CSSValue css_value(
        style->get(ssr::CSSInfoKey::kValue),
        static_cast<tasm::CSSValuePattern>(
            style->get(ssr::CSSInfoKey::kValuePattern).UInt32()),
        static_cast<tasm::CSSValueType>(
            style->get(ssr::CSSInfoKey::kCSSValueType).UInt32()),
        style->get(ssr::CSSInfoKey::kDefaultValue).String()->str());
    tasm::CSSPropertyID css_id = static_cast<tasm::CSSPropertyID>(
        style->get(ssr::CSSInfoKey::kCSSId).Int32());
    this_node->SetInlineStyle(css_id, css_value);
  }

  // static events
  auto static_events = typed_info.get(ssr::RadonNodeKey::kStaticEvents).Array();
  size_t event_size = static_events->size();
  for (size_t idx = 0; idx < event_size; ++idx) {
    auto event = static_events->get(idx).Array();
    bool is_piper_event =
        static_cast<ssr::RadonEventKey::EventType>(
            event->get(ssr::RadonEventKey::kEventType).Int32()) ==
        ssr::RadonEventKey::kPiper;

    auto event_type = event->get(ssr::RadonEventKey::kType).String();
    auto event_name = event->get(ssr::RadonEventKey::kName).String();
    auto event_function = event->get(ssr::RadonEventKey::kFuncName);
    if (is_piper_event) {
      auto args = event->get(ssr::RadonEventKey::kArgs);
      std::vector<std::pair<lepus::String, lepus::Value>> event_vec;
      if (event_function.IsArray()) {
        auto calls_array = event_function.Array();
        for (size_t call_idx = 0; call_idx < calls_array->size(); ++call_idx) {
          auto call_entry = calls_array->get(call_idx).Array();
          event_vec.emplace_back(std::pair<lepus::String, lepus::Value>(
              call_entry->get(RadonEventKey::kPiperName).String(),
              ReplacePlaceholdersInPlaceIfPossible(
                  call_entry->get(RadonEventKey::kPiperArgs), dict)));
        }
      } else if (event_function.IsString()) {
        event_vec.emplace_back(event_function.String(), args);
      }
      this_node->SetStaticEvent(event_type, event_name, event_vec);
    } else {
      this_node->SetStaticEvent(event_type, event_name,
                                event_function.String());
    }
  }
  // Data Set
  auto data_set = typed_info.get(ssr::RadonNodeKey::kDataSet).Table();
  for (auto& itr : *data_set) {
    this_node->SetDataSet(
        itr.first, ReplacePlaceholdersInPlaceIfPossible(itr.second, dict));
  }
}

void LoadComponentValue(
    tasm::RadonComponent* this_node, const lepus::CArray& typed_info,
    std::map<uint32_t, tasm::RadonComponent*>& component_map,
    const lepus::Value& dict) {
  LoadNodeValue(this_node,
                *(typed_info.get(ssr::RadonComponentKey::kRadonNode).Array()),
                dict);
  this_node->SetName(typed_info.get(ssr::RadonComponentKey::kName).String());
  component_map.emplace(typed_info.get(ssr::RadonComponentKey::kSsrId).UInt32(),
                        this_node);
}

void LoadTypedValue(tasm::RadonBase* this_node, const lepus::CArray& typed_info,
                    std::map<uint32_t, tasm::RadonComponent*>& component_map,
                    const lepus::Value& dict) {
  switch (this_node->NodeType()) {
    case tasm::kRadonNode:
      LoadNodeValue(static_cast<tasm::RadonNode*>(this_node), typed_info, dict);
      break;
    case tasm::kRadonComponent:
    case tasm::kRadonPage:
      LoadComponentValue(static_cast<tasm::RadonComponent*>(this_node),
                         typed_info, component_map, dict);
    default:
      break;
  }
}

std::unique_ptr<tasm::RadonBase> ConstructChild(
    tasm::PageProxy* proxy,
    const std::map<uint32_t, tasm::RadonComponent*>& component_map,
    const lepus::CArray& value_info) {
  tasm::RadonNodeType type = static_cast<tasm::RadonNodeType>(
      value_info.get(ssr::RadonValueKey::kNodeType).Int32());
  auto base_info = value_info.get(ssr::RadonValueKey::kRadonBase).Array();
  auto typed_info =
      value_info.get(ssr::RadonValueKey::kRadonTypedValue).Array();

  uint32_t index = base_info->get(ssr::RadonBaseKey::kNodeIndex).Number();
  auto tag_name = base_info->get(ssr::RadonBaseKey::kTagName).String()->str();

  // Is radon node
  if (type == tasm::kRadonNode) {
    return std::make_unique<tasm::RadonNode>(proxy, tag_name, index);
  }

  if (type == tasm::kRadonPage || type == tasm::kRadonComponent) {
    // Is component
    int tid = typed_info->get(ssr::RadonComponentKey::kTid).Number();
    return std::make_unique<tasm::RadonComponent>(
        proxy, tid, nullptr, nullptr, nullptr, nullptr, index, tag_name);
  }

  if (type == tasm::kRadonSlot) {
    auto slot_name =
        typed_info->get(ssr::RadonSlotKey::kRadonSlotName).String()->str();
    return std::make_unique<tasm::RadonSlot>(slot_name);
  }

  if (type == tasm::kRadonPlug) {
    auto entry = component_map.find(
        typed_info->get(ssr::RadonPlugKey::kComponentSsrId).UInt32());
    if (entry != component_map.end()) {
      return std::make_unique<tasm::RadonPlug>(tag_name, entry->second);
    }
  }

  return nullptr;
}

void LoadDomNode(tasm::RadonBase* this_node, tasm::PageProxy* proxy,
                 const lepus::Value& node_value,
                 std::map<uint32_t, tasm::RadonComponent*>& component_map,
                 const lepus::Value& dict) {
  // TODO: SSR format version check in dchecks.
  DCHECK(node_value.IsArray());
  const auto radon_info = node_value.Array();

  const auto typed_info =
      radon_info->get(ssr::RadonValueKey::kRadonTypedValue).Array();

  LoadTypedValue(this_node, *typed_info, component_map, dict);

  const auto base_info =
      radon_info->get(ssr::RadonValueKey::kRadonBase).Array();
  const auto children =
      base_info->get(ssr::RadonBaseKey::kRadonChildren).Array();
  for (size_t idx = 0; idx < children->size(); ++idx) {
    auto current_value = children->get(idx).Array();

    auto child =
        ConstructChild(proxy, component_map, *(children->get(idx).Array()));
    if (child) {
      tasm::RadonBase* child_ptr = child.get();
      this_node->AddChild(std::move(child));
      LoadDomNode(child_ptr, proxy, children->get(idx), component_map, dict);
    }
  }
  // TODO: Other types are not supported yet, will support in future
}

// For page config decode.
bool ConvertBOOLToPageConfigValue(const lepus::Value& value) {
  return value.Bool();
}
std::string ConvertStringToPageConfigValue(const lepus::Value& value) {
  return value.String()->str();
}
int32_t ConvertIntegerToPageConfigValue(const lepus::Value& value) {
  return value.Int32();
}
lepus::Value ConvertLepusValueToPageConfigValue(lepus::Value value) {
  return value;
}
std::unordered_set<tasm::CSSPropertyID> ConvertUnorderedSetToPageConfigValue(
    const lepus::Value& value) {
  std::unordered_set<tasm::CSSPropertyID> value_set;
  if (!value.IsArray()) {
    return value_set;
  }

  auto array = value.Array();
  for (size_t idx = 0; idx < array->size(); ++idx) {
    value_set.insert(static_cast<tasm::CSSPropertyID>(array->get(idx).Int32()));
  }
  return value_set;
}
tasm::TernaryBool ConvertNewImageTypeToPageConfigValue(
    const lepus::Value& value) {
  return static_cast<tasm::TernaryBool>(value.Int32());
}
tasm::PackageInstanceDSL ConvertDSLTypeToPageConfigValue(
    const lepus::Value& value) {
  return static_cast<tasm::PackageInstanceDSL>(value.Int32());
}
tasm::PackageInstanceBundleModuleMode ConvertBundleModeTypeToPageConfigValue(
    const lepus::Value& value) {
  return static_cast<tasm::PackageInstanceBundleModuleMode>(value.Int32());
}

}  // namespace

lepus::Value RetrievePageData(const lepus::Value& ssr_out_value,
                              const lepus::Value& dict) {
  auto result = ssr_out_value.Array()->get(lynx::ssr::SSRDataKey::kPageProps);
  tasm::ForEachLepusValue(
      dict, [&result](const lepus::Value& key, const lepus::Value& value) {
        if (key.IsString()) {
          result.SetProperty(key.String(), value);
        }
      });
  return result;
}

lepus::Value RetrieveGlobalProps(const lepus::Value& ssr_out_value) {
  return ssr_out_value.Array()->get(lynx::ssr::SSRDataKey::kGlobalProps);
}

lepus::Value RetrievePageConfig(const lepus::Value& ssr_out_value) {
  return ssr_out_value.Array()->get(lynx::ssr::SSRDataKey::kPageConfig);
}

lepus::Value RetrieveScript(const lepus::Value& ssr_out_value) {
  return ssr_out_value.Array()->get(lynx::ssr::SSRDataKey::kSSRScript);
}

lepus::Value ProcessSsrScriptIfNeeded(const lepus::Value value,
                                      const lepus::Value& dict) {
  return ReplacePlaceholdersForString(value, dict);
}

bool RetrieveSupportComponentJS(const lepus::Value& page_status) {
  return page_status.Array()
      ->get(ssr::PageConfigKey::kSupportComponentJS)
      .Bool();
}

std::string RetrieveTargetSdkVersion(const lepus::Value& page_status) {
  return page_status.Array()
      ->get(ssr::PageConfigKey::kTargetSdkVersion)
      .String()
      ->str();
}

bool RetrieveLepusNGSwitch(const lepus::Value& page_status) {
  return page_status.Array()->get(ssr::PageConfigKey::kUseLepusNG).Bool();
}

std::shared_ptr<tasm::PageConfig> RetrieveLynxPageConfig(
    const lepus::Value& page_status) {
  auto config = page_status.Array()->get(ssr::PageConfigKey::kPageConfig);
  auto page_config = std::make_shared<tasm::PageConfig>();
#define PAGE_CONFIG_RECONSTRUCTOR(name, type)                          \
  {                                                                    \
    lepus::Value value;                                                \
    if (config.IsTable()) {                                            \
      value = config.Table()->GetValue(#name);                         \
    } else if (config.IsArray()) {                                     \
      value = config.Array()->get(ssr::PageConfigKey::k##name);        \
    }                                                                  \
    if (!value.IsEmpty()) {                                            \
      page_config->Set##name(Convert##type##ToPageConfigValue(value)); \
    }                                                                  \
  }
  FOREACH_PAGECONFIG_FIELD(PAGE_CONFIG_RECONSTRUCTOR)
#undef PAGE_CONFIG_RECONSTRUCTOR

  return page_config;
}

void ReconstructDom(const lepus::Value& ssr_out_data, tasm::PageProxy* proxy,
                    tasm::RadonPage* page, const lepus::Value& dict) {
  std::map<uint32_t, tasm::RadonComponent*> component_map;
  const auto& ssr_radon_data =
      ssr_out_data.Array()->get(lynx::ssr::SSRDataKey::kSSRRootTree);

  LoadDomNode(page, proxy, ssr_radon_data, component_map, dict);
}

/* Format args for SSR sever event.
 origin format：
 {tasmEntryName: __Card__, callbackId: 0, fromPiper: true, methodDetail:
 {method:openSchema, module:LynxTestModule, param:[arg1, arg2, ...]}}

 processed format：
 while method_name == "call":
 [true, 0, {method:openSchema, module:LynxTestModule, data}], data means
 elements in arg2 which is a dictionary.

 while method_name != "call":
 [true, 0, arg1, arg2, ... , {method:openSchema, module:LynxTestModule}]
 */
lepus::Value FormatEventArgsForIOS(const std::string& method_name,
                                   const lepus::Value& args) {
  if (!args.IsTable() || args.GetLength() <= 0) {
    return args;
  }
  auto from_piper = args.GetProperty(ssr::kLepusModuleFromPiper);
  if (from_piper.IsNil() || !from_piper.Bool()) {
    return args;
  }
  auto processed_args = lepus::CArray::Create();
  processed_args->push_back(lepus::Value(true));
  auto callback_id = args.GetProperty(ssr::kLepusModuleCallbackId);
  processed_args->push_back(callback_id.IsNil() ? lepus::Value(0)
                                                : callback_id);
  auto method_detail_map = args.GetProperty(ssr::kLepusModuleMethodDetail);
  if (!method_detail_map.IsTable()) {
    return args;
  }
  auto detail_map = lepus::Dictionary::Create();
  auto params_array = method_detail_map.GetProperty(ssr::kLepusModuleParam);
  // process call method
  if (method_name == ssr::kLepusModuleCallMethod &&
      params_array.GetLength() > 2) {
    auto raw_data = params_array.GetProperty(1);
    tasm::ForEachLepusValue(raw_data, [&detail_map](const lepus::Value& key,
                                                    const lepus::Value& arg) {
      detail_map->SetValue(key.String()->c_str(), arg);
    });
  } else {
    // process normal method
    tasm::ForEachLepusValue(
        params_array,
        [&processed_args](const lepus::Value& key, const lepus::Value& arg) {
          processed_args->push_back(arg);
        });
  }
  detail_map->SetValue(ssr::kLepusModuleMethod,
                       method_detail_map.GetProperty(ssr::kLepusModuleMethod));
  detail_map->SetValue(ssr::kLepusModuleModule,
                       method_detail_map.GetProperty(ssr::kLepusModuleModule));
  processed_args->push_back(lepus::Value(detail_map));
  return lepus::Value(processed_args);
}

/* Format args for SSR sever event.
 origin format：
 {tasmEntryName: __Card__, callbackId: 0, fromPiper: true, methodDetail :
 {method:openSchema,module:LynxTestModule,param:[arg1, arg2, ...]}}

 processed format：
 while method_name == "call":
 {tasmEntryName: __Card__, callbackId: 0, fromPiper: true, methodDetail :
 {method:openSchema, module:LynxTestModule, data}}, data means elements in arg2
 which is a dictionary.

 while method_name != "call":
 {tasmEntryName: __Card__, callbackId: 0,
 fromPiper: true, methodDetail : {module:LynxTestModule, param:[arg1, arg2,
 ...]}}
 */
lepus::Value FormatEventArgsForAndroid(const std::string& method_name,
                                       const lepus::Value& args) {
  if (!args.IsTable() || args.GetLength() <= 0) {
    return args;
  }
  auto from_piper = args.GetProperty(ssr::kLepusModuleFromPiper);
  if (from_piper.IsNil() || !from_piper.Bool()) {
    return args;
  }

  auto processed_args = lepus::Dictionary::Create();
  processed_args->SetValue(ssr::kLepusModuleFromPiper, lepus::Value(true));
  processed_args->SetValue(ssr::kLepusModuleTasmEntryName,
                           args.GetProperty(ssr::kLepusModuleTasmEntryName));
  processed_args->SetValue(ssr::kLepusModuleCallbackId,
                           args.GetProperty(ssr::kLepusModuleCallbackId));
  auto method_detail_map_new = lepus::Dictionary::Create();
  auto method_detail_map = args.GetProperty(ssr::kLepusModuleMethodDetail);
  method_detail_map_new->SetValue(
      ssr::kLepusModuleModule,
      method_detail_map.GetProperty(ssr::kLepusModuleModule));
  auto params_array = method_detail_map.GetProperty(ssr::kLepusModuleParam);
  // process "call" method
  if (method_name == ssr::kLepusModuleCallMethod &&
      params_array.GetLength() > 2) {
    method_detail_map_new->SetValue(
        ssr::kLepusModuleMethod,
        method_detail_map.GetProperty(ssr::kLepusModuleMethod));
    auto raw_data = params_array.GetProperty(1);
    tasm::ForEachLepusValue(
        raw_data, [&method_detail_map_new](const lepus::Value& key,
                                           const lepus::Value& arg) {
          method_detail_map_new->SetValue(key.String()->c_str(), arg);
        });
  } else {
    // process normal method
    method_detail_map_new->SetValue(ssr::kLepusModuleParam, params_array);
  }
  processed_args->SetValue(ssr::kLepusModuleMethodDetail,
                           lepus::Value(method_detail_map_new));
  return lepus::Value(processed_args);
}

bool CheckSSRkApiVersion(const lepus::Value& ssr_out_value) {
  auto version =
      ssr_out_value.Array()->get(lynx::ssr::SSRDataKey::kVersion).String();
  const bool result =
      lynx::tasm::Config::IsHigherOrEqual(kSSRApiVersion, version->c_str());
  LynxWarning(
      result, LYNX_ERROR_CODE_API_VERSION_NOT_SUPPORTED,
      std::string(
          "Unsupported SSR API Version! Loading SSR data of API version ") +
          version->c_str() +
          ". While the latest API version supported by the integrated SDK is " +
          kSSRApiVersion);
  return result;
}

}  // namespace ssr
}  // namespace lynx
