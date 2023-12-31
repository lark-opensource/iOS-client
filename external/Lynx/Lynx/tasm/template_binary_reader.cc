// Copyright 2019 The Lynx Authors. All rights reserved.
#include "tasm/template_binary_reader.h"

#include <chrono>
#include <map>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_style_sheet_manager.h"
#include "lepus/function.h"
#include "lepus/json_parser.h"
#include "lepus/quick_context.h"
#include "tasm/compile_options.h"
#include "tasm/config.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_config.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/template_assembler.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

bool TemplateBinaryReader::DecodeForHMR() {
#if ENABLE_HMR
  // decode HEADER in order to get correct config
  ERROR_UNLESS(DecodeHeader());

  // set latest debug information for red-box
  entry_->SetTemplateDebugUrl(compile_options_.template_debug_url_);

  // decode magic_word in end
  stream_->Seek(stream_->size() - sizeof(uint32_t));
  DECODE_U32(magic_word);
  if (magic_word != TASM_SSR_SUFFIX_MAGIC) {
    error_message_ = "Not Valid HMR Template";
    return false;
  }
  stream_->Seek(stream_->size() - 2 * sizeof(uint32_t));
  DECODE_U32(suffix_size);
  stream_->Seek(stream_->size() - suffix_size);
  DECODE_U8(offset_count);

  std::map<uint8_t, Range> type_offset_map;
  for (uint32_t i = 0; i < offset_count; ++i) {
    DECODE_U8(type);
    DECODE_U32(start);
    DECODE_U32(end);
    type_offset_map.insert(std::make_pair(type, Range(start, end)));
  }

  // decode section for "STRING"，in order to get all the "string" value
  stream_->Seek(type_offset_map[BinaryOffsetType::TYPE_STRING].start);
  ERROR_UNLESS(DeserializeStringSection());
  entry_->GetVm()->string_table()->string_list.resize(string_list_count_);
  for (size_t dd = 0; dd < string_list_count_; dd++) {
    entry_->GetVm()->string_table()->string_list[dd] = string_list_[dd];
  }

  // seek to the part of CSS
  stream_->Seek(type_offset_map[BinaryOffsetType::TYPE_CSS].start);

  // clear css_route
  auto manager = entry_->GetStyleSheetManager();
  manager->route_.fragment_ranges.clear();

  ERROR_UNLESS(DecodeCSSDescriptor(true));

  // decode component section, update component information, such as component
  // data
  stream_->Seek(type_offset_map[BinaryOffsetType::TYPE_COMPONENT].start);
  ERROR_UNLESS(DecodeComponentDescriptor(true));

  // decode page section
  stream_->Seek(type_offset_map[BinaryOffsetType::TYPE_PAGE_ROUTE].start);
  ERROR_UNLESS(DecodePageDescriptor(true));

  // decode dynamic component section if necessary
  if (!is_card_) {
    stream_->Seek(
        type_offset_map[BinaryOffsetType::TYPE_DYNAMIC_COMPONENT_ROUTE].start);
    ERROR_UNLESS(DecodeDynamicComponentDescriptor(true));
  }
#endif
  return true;
}

bool TemplateBinaryReader::DecodeCSSDescriptor(bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_CSS_DESCRIPTOR);
  auto manager = entry_->GetStyleSheetManager();
  manager->SetEnableNewImportRule(
      compile_options_.enable_css_selector_ ||
      Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                              LYNX_VERSION_2_9));
  ERROR_UNLESS(DecodeCSSRoute(manager->route_));
  auto& fragment_ranges = manager->route_.fragment_ranges;
  std::unordered_map<int32_t, std::unique_ptr<SharedCSSFragment>> fragments_map;

  css_section_range_.start = static_cast<uint32_t>(stream_->offset());
  css_section_range_.end = css_section_range_.start;
  bool enable_css_async_decode = GetCSSAsyncDecode();
  bool enable_css_lazy_decode =
      enable_css_async_decode ? true : GetCSSLazyDecode();
  for (auto it = fragment_ranges.begin(); it != fragment_ranges.end(); ++it) {
    if (!enable_css_lazy_decode || is_hmr) {
      auto fragment = std::make_unique<SharedCSSFragment>();
      stream_->Seek(css_section_range_.start + it->second.start);
      ERROR_UNLESS(DecodeCSSFragment(
          fragment.get(), it->second.end + css_section_range_.start));
      fragment->SetEnableClassMerge(compile_options_.enable_css_class_merge_);
#if ENABLE_HMR
      if (is_hmr) {
        fragments_map.insert({fragment->id(), std::move(fragment)});
      } else {
        manager->AddSharedCSSFragment(std::move(fragment));
      }
#else
      manager->AddSharedCSSFragment(std::move(fragment));
#endif
    }
    css_section_range_.end =
        css_section_range_.end > css_section_range_.start + it->second.end
            ? css_section_range_.end
            : it->second.end + css_section_range_.start;
  }

#if ENABLE_HMR
  if (is_hmr) {
    // replace fragment with same id in raw_fragments
    // update source style sheet
    for (auto& raw_fragment : manager->raw_fragments_) {
      int32_t key = raw_fragment.first;
      if (fragments_map.find(key) != fragments_map.end()) {
        raw_fragment.second->ReplaceByNewFragment(fragments_map.at(key).get());
      }
    }
  }
#endif

  if (enable_css_async_decode) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeCSSDescriptorWithThread");
    const int length = css_section_range_.end - css_section_range_.start;
    auto css_stream = std::make_unique<lepus::ByteArrayInputStream>(
        stream_->cursor(), length);
    auto context = entry_->GetVm();
    TemplateEntry* binary_entry =
        new TemplateEntry(context, compile_options_.target_sdk_version_);
    auto css_reader = std::make_unique<TemplateBinaryReader>(
        nullptr, binary_entry, std::move(css_stream));
    css_reader->compile_options_ = compile_options_;
    css_reader->enable_css_parser_ = enable_css_parser_;
    css_reader->enable_css_variable_ = enable_css_variable_;
    std::thread fragment_async_thread(
        &TemplateBinaryReader::DecodeCSSFragmentAsync, std::move(css_reader),
        std::move(manager));
    fragment_async_thread.detach();
  }

  stream_->Seek(css_section_range_.end);
  return true;
}

bool TemplateBinaryReader::GetCSSLazyDecode() {
  if (compile_options_.enable_lazy_css_decode_ ==
      FeOption::FE_OPTION_UNDEFINED) {
    absetting_disable_css_lazy_decode_ = lynx::tasm::Config::GetConfigString(
        "disable_lazy_css_decode", compile_options_);
    LOGI("CSSLazyDecode options FE_OPTION_UNDEFINED ABSetting: "
         << absetting_disable_css_lazy_decode_);
    if (config_decoder_) {
      config_decoder_->SetAbSettingDisableCSSLazyDecode(
          absetting_disable_css_lazy_decode_);
    }
    return !(absetting_disable_css_lazy_decode_ == "true");
  }
  LOGI("CSSLazyDecode options FE_OPTION: "
       << (int)compile_options_.enable_lazy_css_decode_);
  return compile_options_.enable_lazy_css_decode_ == FeOption::FE_OPTION_ENABLE;
}

bool TemplateBinaryReader::GetCSSAsyncDecode() {
  if (compile_options_.enable_async_css_decode_ == FeOption::FE_OPTION_ENABLE) {
    return true;
  }
  return false;
}

bool TemplateBinaryReader::DecodeCSSFragmentAsync(
    std::shared_ptr<CSSStyleSheetManager> manager) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DecodeCSSFragmentAsync");
  auto& fragment_ranges = manager->route_.fragment_ranges;
  size_t descriptor_start = stream_->offset();
  for (auto it = fragment_ranges.begin(); it != fragment_ranges.end(); ++it) {
    if (manager->GetStopThread()) {
      break;
    }
    if (manager->IsSharedCSSFragmentDecoded(it->first)) {
      continue;
    }
    auto fragment = std::make_unique<SharedCSSFragment>();
    stream_->Seek(descriptor_start + it->second.start);
    ERROR_UNLESS(
        DecodeCSSFragment(fragment.get(), it->second.end + descriptor_start));
    fragment->SetEnableClassMerge(compile_options_.enable_css_class_merge_);
    manager->AddSharedCSSFragment(std::move(fragment));
  }
  if (entry_ != nullptr) {
    delete entry_;
    entry_ = nullptr;
  }
  return true;
}

bool TemplateBinaryReader::DecodeCSSFragmentById(int32_t id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LazyDecodeCSSFragment");
  auto manager = entry_->GetStyleSheetManager();
  auto& fragment_ranges = manager->route_.fragment_ranges;
  auto it = fragment_ranges.find(id);
  if (it == fragment_ranges.end()) {
    return false;
  }
  auto fragment = std::make_unique<SharedCSSFragment>();
  stream_->Seek(css_section_range_.start + it->second.start);
  ERROR_UNLESS(DecodeCSSFragment(fragment.get(),
                                 it->second.end + css_section_range_.start));
  fragment->SetEnableClassMerge(compile_options_.enable_css_class_merge_);
  manager->AddSharedCSSFragment(std::move(fragment));
  return true;
}

bool TemplateBinaryReader::DidDecodeHeader() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DidDecodeHeader");
  // Construct config decoder
  config_decoder_ = std::make_unique<LynxBinaryConfigDecoder>(
      compile_options_, trial_options_, compile_options_.target_sdk_version_,
      is_lepusng_binary_, enable_css_parser_);

  // Since compile option is already decoded, here we can set
  // compile options to entry.
  entry_->set_compile_options(compile_options_);

  // Set template debug url
  entry_->SetTemplateDebugUrl(compile_options_.template_debug_url_);

  if (compile_options_.enable_lazy_css_decode_ == FeOption::FE_OPTION_DISABLE) {
    entry_->SetTemplateBinaryReader(nullptr);
  }

  // Construct lepus context if the context in this entry is nullptr
  if (!context_ && !ConstructContext()) {
    return false;
  }

  if (configger_ != nullptr) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "InitLepusDebugger");
    configger_->InitLepusDebugger();
  }

  if (is_card_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "InitCardEnv");
    entry_->SetNeedJSGlobalConsole(need_console_);
    entry_->SetSupportComponentJS(support_component_js_);
    configger_->SetSupportComponentJS(support_component_js_);
    configger_->SetTargetSdkVersion(compile_options_.target_sdk_version_);
  }
  return true;
}

bool TemplateBinaryReader::ConstructContext() {
  auto assembler = static_cast<TemplateAssembler*>(configger_);
  if (entry_->EnableReuseContext()) {
    // reuse page's Lepus Context
    auto page_context = assembler->getLepusContext(DEFAULT_ENTRY_NAME);
    if (!(is_lepusng_binary_ && page_context->IsLepusNGContext())) {
      error_message_ =
          "TemplateBinaryReader: enableReuseContext can only be opened when "
          "both using LepusNG.";
      return false;
    }
    entry_->SetVm(page_context);
    context_ = entry_->GetVm().get();
  } else {
    entry_->ConstructContext(assembler, is_lepusng_binary_);
    context_ = entry_->GetVm().get();
    if (is_card_) {
      assembler->vm_to_template_entry_.insert({context_, entry_});
    } else {
      context_->set_name(entry_->GetName());
    }
  }

  if (!context_) {
#if !ENABLE_JUST_LEPUSNG
    error_message_ = "TemplateBinaryReader: cannot run lepusng template.js.";
#else
    error_message_ =
        "TemplateBinaryReader: just lepusng sdk can just run lepusng "
        "template.js.";
#endif
    return false;
  }

  return true;
}

bool TemplateBinaryReader::DidDecodeTemplate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DidDecodeTemplate");
  // set app name, card's entry_name is always DEFAULT_ENTRY_NAME
  if (is_card_) {
    entry_->SetName(app_name_);
    context_->set_name(DEFAULT_ENTRY_NAME);
  }
  // set page_moulds
  entry_->page_moulds_ = std::move(page_moulds_);
  // set string section
  entry_->GetVm()->string_table()->string_list.resize(string_list_count_);
  for (size_t dd = 0; dd < string_list_count_; dd++) {
    entry_->GetVm()->string_table()->string_list[dd] = string_list_[dd];
  }
  // set component_moulds
  entry_->component_moulds_ = std::move(component_moulds_);
  entry_->component_name_to_id_ = std::move(component_name_to_id_);
  // set js_source
  entry_->SetJSSource(std::move(js_sources_));
  // set page_config
  configger_->SetPageConfig(page_configs_);
  // Update CSSConfig.
  entry_->UpdateCSSConfig(page_configs_);
  // set dynamic_component_moulds
  entry_->dynamic_component_moulds_ = std::move(dynamic_component_moulds_);
  entry_->dynamic_component_declarations_ =
      std::move(dynamic_component_declarations_);

  if (!configger_->GetPageConfig()) {
    error_message_ = "TemplateBinaryReader: page config is null";
    return false;
  }

  entry_->SetCircularDataCheck(
      configger_->GetPageConfig()->GetGlobalCircularDataCheck());

  entry_->SetEnableAttributeTimingFlag(
      configger_->GetPageConfig()->GetEnableAttributeTimingFlag());

  entry_->SetAirParsedStylesMap(air_parsed_styles_map_);

  return entry_->ApplyConfigsToLepusContext(
      configger_->GetPageConfig(), compile_options_.target_sdk_version_);
}

bool TemplateBinaryReader::DecodeContext() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_CONTEXT);
  if (context_->IsLepusNGContext()) {
    // read quickjs bytecode
    DECODE_U64LEB(data_len);
    std::vector<uint8_t> data;
    data.resize(static_cast<std::size_t>(data_len + 1));
    ERROR_UNLESS(ReadData(data.data(), static_cast<int>(data_len)));
    if (entry_->EnableReuseContext()) {
      lepus::Value ret_val;
      bool result = lepus::QuickContext::Cast(context_)->EvalBinary(
          data.data(), data_len, &ret_val);
      entry_->SetBinaryEvalResult(ret_val);
      return result;
    } else {
      return lepus::QuickContext::Cast(context_)->DeSerialize(data.data(),
                                                              data_len);
    }
  }

#if !ENABLE_JUST_LEPUSNG
  lepus::VMContext::Cast(context_)->SetSdkVersion(
      compile_options_.target_sdk_version_);
  std::unordered_map<lepus::String, lepus::Value> lepus_root_global_{};
  ERROR_UNLESS(DeserializeGlobal(lepus_root_global_));
  for (auto& pair : lepus_root_global_) {
    lepus::VMContext::Cast(context_)->global_.Add(pair.first, pair.second);
  }

  base::scoped_refptr<lepus::Function> parent =
      base::make_scoped_refptr<lepus::Function>(nullptr);
  DECODE_FUNCTION(parent, root_function);
  lepus::VMContext::Cast(context_)->root_function_ = root_function;
  std::unordered_map<lepus::String, long> lepus_top_variables_{};
  ERROR_UNLESS(DeserializeTopVariables(lepus_top_variables_));
  lepus::VMContext::Cast(context_)->top_level_variables_.insert(
      std::make_move_iterator(lepus_top_variables_.begin()),
      std::make_move_iterator(lepus_top_variables_.end()));
  return true;
#else
  error_message_ = "lepusng just can decode lepusng template.lepus";
  LOGE("lepusng just can decode lepusng template.lepus");
  return false;
#endif
  return true;
}

}  // namespace tasm
}  // namespace lynx
