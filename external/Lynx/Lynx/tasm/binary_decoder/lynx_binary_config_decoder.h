//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BINARY_DECODER_LYNX_BINARY_CONFIG_DECODER_H_
#define LYNX_TASM_BINARY_DECODER_LYNX_BINARY_CONFIG_DECODER_H_

#include <memory>
#include <string>
#include <utility>

#include "tasm/compile_options.h"
#include "tasm/component_config.h"
#include "tasm/page_config.h"

namespace lynx {
namespace tasm {

// Utils class for decode Lynx Config.
class LynxBinaryConfigDecoder {
 public:
  LynxBinaryConfigDecoder(const tasm::CompileOptions& compile_option,
                          const lepus::Value& trial_option,
                          const std::string& target_sdk_version,
                          bool is_lepusng_binary, bool enable_css_parser)
      : compile_options_(compile_option),
        trial_options_(trial_option),
        target_sdk_version_(target_sdk_version),
        is_lepusng_binary_(is_lepusng_binary),
        enable_css_parser_(enable_css_parser){};

  LynxBinaryConfigDecoder(const LynxBinaryConfigDecoder&) = delete;
  LynxBinaryConfigDecoder& operator=(const LynxBinaryConfigDecoder&) = delete;
  LynxBinaryConfigDecoder(LynxBinaryConfigDecoder&&) = delete;
  LynxBinaryConfigDecoder& operator=(LynxBinaryConfigDecoder&&) = delete;

  bool DecodePageConfig(const std::string& config_str,
                        std::shared_ptr<PageConfig>& page_config);
  bool DecodeComponentConfig(
      const std::string& config_str,
      std::shared_ptr<ComponentConfig>& component_config);

  void SetAbSettingDisableCSSLazyDecode(
      std::string& absetting_disable_css_lazy_decode) {
    absetting_disable_css_lazy_decode_ = absetting_disable_css_lazy_decode;
  }

 private:
  /// TODO(limeng.amer): move to report thread.
  /// Upload global feature switches in PageConfig with common data about lynx
  /// view. If you add a new  global feature switch, you should add it to report
  /// event.
  void ReportGlobalFeatureSwitch(
      const std::shared_ptr<PageConfig>& page_config);
  tasm::CompileOptions compile_options_;
  lepus::Value trial_options_;
  std::string target_sdk_version_;
  bool is_lepusng_binary_{false};
  bool enable_css_parser_{false};
  std::string absetting_disable_css_lazy_decode_{};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BINARY_DECODER_LYNX_BINARY_CONFIG_DECODER_H_
