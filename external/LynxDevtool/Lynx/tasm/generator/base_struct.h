// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_GENERATOR_BASE_STRUCT_H_
#define LYNX_TASM_GENERATOR_BASE_STRUCT_H_

#include <string>
#include <unordered_map>
#include <vector>

#include "lepus/value.h"
#include "tasm/compile_options.h"
#include "tasm/generator/ttml_constant.h"
#include "tasm/generator/ttml_holder.h"
#include "third_party/rapidjson/rapidjson.h"

namespace lynx {
namespace tasm {

struct EncodeResult {
  int status;
  std::string error_msg;
  std::vector<uint8_t> buffer;
  std::string lepus_code;
  std::string lepus_debug;
  std::string section_size;
};

// Options used in encode time, but not be used in run time.
struct GeneratorOptions {
  std::string cli_version_{};
  std::string lepus_version_{};
  std::string dsl_{};
  std::string app_type_{};

  // Since doc.Parse("").HasParseError() == true, let default value be "{}" to
  // avoid decode error.
  std::string config_{"{}"};
  std::string source_content_str_{};

  // for dsl which generate code in fe without using native parser
  std::string lepus_code_{};
  std::unordered_map<std::string, std::string> sub_lepus_code_{};

  rapidjson::Document source_content_obj_{};
  bool silence_{false};
  bool enable_radon_{false};
  bool lepus_closure_fix_{false};
  bool enable_tt_for_full_version_{false};
  bool has_tt_for_command_{false};
  bool enable_dataset_attrs_{false};
  bool enable_debug_info_{false};
  bool skip_encode_{false};
  bool enable_ssr_{false};
  bool enable_cursor_{false};
  PackageInstanceType instance_type_{PackageInstanceType::CARD};
  PackageInstanceDSL instance_dsl_{PackageInstanceDSL::TT};
  PackageInstanceBundleModuleMode bundle_module_mode_{
      PackageInstanceBundleModuleMode::EVAL_REQUIRE_MODE};
  lepus::Value trial_options_{};

  // template info, only enable when targetSdkVersion >= 2.7
  lepus::Value template_info_{};

  // for worklet
  rapidjson::Value worklet_;

  // for template script
  rapidjson::Value packed_script_;
  rapidjson::Value script_map_;

  // for js code
  std::unordered_map<std::string, std::string> js_code_{};

  // for fiber css meta
  rapidjson::Value css_;
  rapidjson::Value css_map_;
  rapidjson::Value css_source_;
  // for style extraction
  rapidjson::Value parsed_styles_;

  // for non fiber css meta
  rapidjson::Document css_obj_{};

  // for element template
  rapidjson::Document element_template_{};

  // for air styles
  rapidjson::Value air_parsed_styles_;
};

// not used in runtime ,just for source generator
struct SourceGeneratorOptions {
  bool enable_tt_for_full_version = false;
  bool has_tt_for_command = false;
  bool enable_dataset_attrs_ = false;
};

struct EncoderOptions {
  bool parser_result_{true};
  std::string err_msg_{};
  SourceGeneratorOptions source_generator_options_{};
  GeneratorOptions generator_options_{};
  CompileOptions compile_options_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_BASE_STRUCT_H_
