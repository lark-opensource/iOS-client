//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BINARY_DECODER_LYNX_TEMPLATE_BUNDLE_H_
#define LYNX_TASM_BINARY_DECODER_LYNX_TEMPLATE_BUNDLE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "css/css_style_sheet_manager.h"
#include "lepus/function.h"
#include "lepus/value.h"
#include "tasm/base/element_template_info.h"
#include "tasm/compile_options.h"
#include "tasm/header_ext_info.h"
#include "tasm/moulds.h"
#include "tasm/page_config.h"
#include "tasm/template_binary.h"
#include "tasm/template_themed.h"

namespace lynx {
namespace tasm {

// LynxTemplateBundle is used to hold the result of DecodeResult.
// It is usually used when user needs to decode a template without loading
// template.
//
class LynxTemplateBundle final {
 public:
  LynxTemplateBundle()
      : css_style_manager_(std::make_shared<CSSStyleSheetManager>(nullptr)){};

  inline lepus::Value GetExtraInfo() {
    if (page_configs_) {
      return page_configs_->GetExtraInfo();
    }
    return lepus::Value();
  }

  const std::unordered_map<lepus::String, lepus::String> &GetJsSources() const {
    return js_sources_;
  }

  bool IsCard() const { return app_type_ == APP_TYPE_CARD; }

 private:
  // header info.
  uint32_t total_size_{0};
  bool is_lepusng_binary_{false};
  std::string lepus_version_{};
  std::string target_sdk_version_{};
  CompileOptions compile_options_{};
  lepus::Value template_info_{};
  lepus::Value trial_options_{};
  bool enable_css_variable_{false};
  bool enable_css_parser_{false};
  bool need_console_{true};
  bool support_component_js_{false};

  // app type.
  std::string app_type_{};

  // body - CSS
  Range css_section_range_;
  std::shared_ptr<CSSStyleSheetManager> css_style_manager_;

  // body - APP
  std::string app_name_;

  // body - PAGE
  std::unordered_map<int32_t, std::shared_ptr<PageMould>> page_moulds_{};

  // body - String
  uint32_t string_list_count_{0};
  std::vector<lepus::String> string_list_{};

  // body - COMPONENT
  std::unordered_map<std::string, int32_t> component_name_to_id_{};
  std::unordered_map<int32_t, std::shared_ptr<ComponentMould>>
      component_moulds_{};

  // body - JS
  std::unordered_map<lepus::String, lepus::String> js_sources_{};

  // body - CONFIG
  std::shared_ptr<lynx::tasm::PageConfig> page_configs_{};

  // body - DYNAMIC-COMPONENT
  std::unordered_map<int32_t, std::shared_ptr<DynamicComponentMould>>
      dynamic_component_moulds_;

  // body - THEMED.
  Themed themed_;

  // body - USING_DYNAMIC_COMPONENT_INFO
  std::unordered_map<std::string, std::string>
      dynamic_component_declarations_{};

  // body - ROOT-LEPUS
  // for lepusng
  std::vector<uint8_t> lepusng_code_{};
  uint64_t lepusng_code_len_{0};
  // for lepus
  std::unordered_map<lepus::String, lepus::Value> lepus_root_global_;
  std::unordered_map<lepus::String, long> lepus_top_variables_{};
#if !ENABLE_JUST_LEPUSNG
  base::scoped_refptr<lepus::Function> lepus_root_function_{};
#endif

  // fiber- element template info map
  std::unordered_map<std::string, std::shared_ptr<ElementTemplateInfo>>
      element_template_infos_{};

  // fiber- parsed styles map
  ParsedStyleMap parsed_styles_map_{};

  // air parsed styles
  AirParsedStylesMap air_parsed_styles_map_;

  friend class LynxBinaryReader;
  friend class TemplateAssembler;
  friend class TemplateEntry;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BINARY_DECODER_LYNX_TEMPLATE_BUNDLE_H_
