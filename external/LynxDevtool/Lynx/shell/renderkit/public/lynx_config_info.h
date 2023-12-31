// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_INFO_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_INFO_H_

#include <set>
#include <string>

#include "shell/renderkit/public/lynx_basic_types.h"
namespace lynx {
class LynxConfigInfo {
 public:
  LynxConfigInfo() = default;

  std::string GetPageVersion() { return page_version_; }

  std::string GetPageType() { return page_type_; }

  std::string GetCliVersion() { return cli_version_; }

  std::string GetCustomData() { return custom_data_; }

  std::string GetTemplateUrl() { return template_url_; }

  std::string GetTargetSdkVersion() { return target_sdk_version_; }

  std::string GetLepusVersion() { return lepus_version_; }

  LynxThreadStrategyForRender GetThreadStrategyForRendering() {
    return thread_strategy_for_rendering_;
  }

  bool IsEnableLepusNG() { return enable_lepusNG_; }

  std::string GetRadonMode() { return radon_mode_; }

  // all registered component
  std::set<std::string> GetRegisteredComponents() {
    return registered_components_;
  }

  void SetPageVersion(const std::string& value) { page_version_ = value; }

  void SetPageType(const std::string& value) { page_type_ = value; }

  void SetCliVersion(const std::string& value) { cli_version_ = value; }

  void SetCustomData(const std::string& value) { custom_data_ = value; }

  void SetTemplateUrl(const std::string& value) { template_url_ = value; }

  void SetTargetSdkVersion(const std::string& value) {
    target_sdk_version_ = value;
  }

  void SetLepusVersion(const std::string& value) { lepus_version_ = value; }

  void SetThreadStrategyForRendering(LynxThreadStrategyForRender value) {
    thread_strategy_for_rendering_ = value;
  }

  void SetEnableLepusNG(bool value) { enable_lepusNG_ = value; }

  void SetRadonMode(const std::string& value) { radon_mode_ = value; }

  // all registered component
  void SetRegisteredComponents(const std::set<std::string>& components) {
    registered_components_ = components;
  }

 private:
  std::string page_version_;
  std::string page_type_;
  std::string cli_version_;
  std::string custom_data_;  // json string
  std::string template_url_;
  std::string target_sdk_version_;
  std::string lepus_version_;
  LynxThreadStrategyForRender thread_strategy_for_rendering_ =
      LynxThreadStrategyForRenderAllOnUI;
  bool enable_lepusNG_ = false;
  std::string radon_mode_;
  std::set<std::string> registered_components_;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_INFO_H_
