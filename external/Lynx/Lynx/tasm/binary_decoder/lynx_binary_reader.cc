//  Copyright 2022 The Lynx Authors. All rights reserved.
#include "lynx_binary_reader.h"

#include <algorithm>
#include <string>
#include <vector>

#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

bool LynxBinaryReader::DidDecodeHeader() {
  // construct config decoder
  config_decoder_ = std::make_unique<LynxBinaryConfigDecoder>(
      compile_options_, trial_options_, compile_options_.target_sdk_version_,
      is_lepusng_binary_, enable_css_parser_);

  template_bundle_.total_size_ = total_size_;
  template_bundle_.is_lepusng_binary_ = is_lepusng_binary_;
  template_bundle_.target_sdk_version_ = compile_options_.target_sdk_version_;
  template_bundle_.compile_options_ = compile_options_;
  template_bundle_.trial_options_ = trial_options_;
  template_bundle_.template_info_ = template_info_;
  template_bundle_.enable_css_parser_ = enable_css_parser_;
  template_bundle_.enable_css_variable_ = enable_css_variable_;
  template_bundle_.need_console_ = need_console_;
  template_bundle_.support_component_js_ = support_component_js_;
  return true;
}

bool LynxBinaryReader::DidDecodeAppType() {
  template_bundle_.app_type_ = app_type_;
  return LynxBinaryBaseTemplateReader::DidDecodeAppType();
}

bool LynxBinaryReader::DidDecodeTemplate() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DidDecodeTemplate");
  template_bundle_.app_name_ = app_name_;
  template_bundle_.page_moulds_ = std::move(page_moulds_);
  template_bundle_.string_list_count_ = string_list_count_;
  template_bundle_.string_list_ = std::move(string_list_);
  template_bundle_.component_moulds_ = std::move(component_moulds_);
  template_bundle_.component_name_to_id_ = std::move(component_name_to_id_);
  template_bundle_.js_sources_ = std::move(js_sources_);
  template_bundle_.page_configs_ = std::move(page_configs_);
  template_bundle_.dynamic_component_moulds_ =
      std::move(dynamic_component_moulds_);
  template_bundle_.dynamic_component_declarations_ =
      std::move(dynamic_component_declarations_);
  return true;
}

Themed& LynxBinaryReader::Themed() { return template_bundle_.themed_; }

bool LynxBinaryReader::DecodeCSSDescriptor(bool is_hmr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_CSS_DESCRIPTOR);
  auto manager = template_bundle_.css_style_manager_;
  ERROR_UNLESS(DecodeCSSRoute(manager->route_));
  auto& fragment_ranges = manager->route_.fragment_ranges;
  std::unordered_map<int32_t, std::unique_ptr<SharedCSSFragment>> fragments_map;

  css_section_range_.start = static_cast<uint32_t>(stream_->offset());
  css_section_range_.end = css_section_range_.start;
  for (auto it = fragment_ranges.begin(); it != fragment_ranges.end(); ++it) {
    auto fragment = std::make_unique<SharedCSSFragment>();
    stream_->Seek(css_section_range_.start + it->second.start);
    ERROR_UNLESS(DecodeCSSFragment(fragment.get(),
                                   it->second.end + css_section_range_.start));
    fragment->SetEnableClassMerge(compile_options_.enable_css_class_merge_);
    manager->AddSharedCSSFragment(std::move(fragment));
    css_section_range_.end =
        css_section_range_.end > css_section_range_.start + it->second.end
            ? css_section_range_.end
            : it->second.end + css_section_range_.start;
  }
  stream_->Seek(css_section_range_.end);
  return true;
}

bool LynxBinaryReader::DecodeContext() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_CONTEXT);
  if (is_lepusng_binary_) {
    // read quickjs bytecode
    DECODE_U64LEB(data_len);
    std::vector<uint8_t> data;
    data.resize(static_cast<std::size_t>(data_len + 1));
    ERROR_UNLESS(ReadData(data.data(), static_cast<int>(data_len)));
    template_bundle_.lepusng_code_ = std::move(data);
    template_bundle_.lepusng_code_len_ = data_len;
    return true;
  }

#if !ENABLE_JUST_LEPUSNG
  DeserializeGlobal(template_bundle_.lepus_root_global_);
  base::scoped_refptr<lepus::Function> parent =
      base::make_scoped_refptr<lepus::Function>(nullptr);
  DECODE_FUNCTION(parent, root_function);
  template_bundle_.lepus_root_function_ = root_function;
  ERROR_UNLESS(DeserializeTopVariables(template_bundle_.lepus_top_variables_));
  return true;
#else
  error_message_ = "lepusng just can decode lepusng template.lepus";
  LOGE("lepusng just can decode lepusng template.lepus");
  return false;
#endif
}

bool LynxBinaryReader::DecodeParsedStylesSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_PARSED_STYLES_SECTION);
  DECODE_U32(size);
  std::vector<std::string> parsed_styles_keys;
  parsed_styles_keys.reserve(size);
  for (size_t i = 0; i < size; ++i) {
    std::string key;
    ERROR_UNLESS(ReadStringDirectly(&key));
    DECODE_U32(start);
    DECODE_U32(end);
    parsed_styles_keys.emplace_back(std::move(key));
  }

  for (const auto& key : parsed_styles_keys) {
    auto res = GetParsedStyleMap().emplace(key, std::make_shared<StyleMap>());
    ERROR_UNLESS(DecodeParsedStylesInner(*(res.first->second)));
  }
  return true;
}

bool LynxBinaryReader::DecodeElementTemplateSection() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DECODE_ELEMENT_TEMPLATE_SECTION);
  DECODE_U32(size);
  std::vector<std::string> element_template_keys;
  element_template_keys.reserve(size);

  for (size_t i = 0; i < size; ++i) {
    std::string key;
    ERROR_UNLESS(ReadStringDirectly(&key));
    DECODE_U32(start);
    DECODE_U32(end);
    element_template_keys.emplace_back(std::move(key));
  }

  for (const auto& key : element_template_keys) {
    auto info = std::make_shared<ElementTemplateInfo>();
    DecodeElementTemplateInfoInner(*info);
    ERROR_UNLESS(info->exist_);
    info->key_ = key;
    template_bundle_.element_template_infos_.emplace(key, std::move(info));
  }

  return true;
}

}  // namespace tasm
}  // namespace lynx
