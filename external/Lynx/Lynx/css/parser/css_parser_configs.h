// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_CSS_PARSER_CONFIGS_H_
#define LYNX_CSS_PARSER_CSS_PARSER_CONFIGS_H_

#include <string>

#include "tasm/compile_options.h"
#include "tasm/config.h"
#include "tasm/generator/version.h"

namespace lynx {
namespace tasm {

struct CSSParserConfigs {
  static CSSParserConfigs GetCSSParserConfigsByComplierOptions(
      const CompileOptions& compile_options) {
    CSSParserConfigs config;
    if (!compile_options.target_sdk_version_.empty() &&
        std::isdigit(compile_options.target_sdk_version_[0])) {
      Version version(compile_options.target_sdk_version_);
      if (version >= Version(LYNX_VERSION_2_6)) {
        config.enable_length_unit_check = true;
      }
      if (version < Version(LYNX_VERSION_1_6)) {
        config.enable_legacy_parser = true;
      }
    }
    config.enable_css_strict_mode = compile_options.enable_css_strict_mode_;
    config.remove_css_parser_log = compile_options.remove_css_parser_log_;
    return config;
  }
  // default is disable.
  bool enable_css_strict_mode = false;
  bool remove_css_parser_log = false;
  bool enable_legacy_parser = false;
  bool enable_length_unit_check = false;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_PARSER_CSS_PARSER_CONFIGS_H_
