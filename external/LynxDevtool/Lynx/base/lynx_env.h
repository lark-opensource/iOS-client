// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_LYNX_ENV_H_
#define LYNX_BASE_LYNX_ENV_H_

#include <map>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>

#include "base/base_export.h"
#include "base/no_destructor.h"

namespace lynx {
namespace base {

class BASE_EXPORT_FOR_DEVTOOL LynxEnv {
 public:
  constexpr static const char* const kLynxLayoutPerformanceEnable =
      "layout_performance_enable";
  constexpr static const char* const kLynxDevtoolComponentAttach =
      "devtool_component_attach";
  constexpr static const char* const kLynxEnableDomTree = "enable_dom_tree";
  constexpr static const char* const kLynxEnableTableDeepCheck =
      "enable_table_deep_check";

  BASE_EXPORT_FOR_DEVTOOL static LynxEnv& GetInstance();
  static void onPiperInvoked(const std::string& module_name,
                             const std::string& method_name,
                             const std::string& param_str,
                             const std::string& url,
                             const std::string& invoke_session);
  static void onPiperResponsed(const std::string& method_name,
                               const std::string& module_name,
                               const std::string& url,
                               const std::string& response,
                               const std::string& invoke_session);

  void SetEnv(const std::string& key, bool value);
  void SetGroupedEnv(const std::string& key, bool value,
                     const std::string& group_key);
  void SetGroupedEnv(const std::unordered_set<std::string>& new_group_values,
                     const std::string& group_key);
  bool GetEnv(const std::string& key, bool default_value);
  std::unordered_set<std::string> GetGroupedEnv(const std::string& group_key);
  void SetEnvMask(const std::string& key, bool value);

  bool IsLynxDebugEnabled();
  bool IsDevtoolComponentAttach();
  bool IsDevtoolEnabled();
  BASE_EXPORT_FOR_DEVTOOL bool IsDevtoolEnabledForDebuggableView();
  bool IsQuickjsCacheEnabled();
  bool IsDisableCollectLeak();
  bool IsLayoutPerformanceEnabled();
  BASE_EXPORT_FOR_DEVTOOL bool IsV8Enabled();
  bool IsPiperMonitorEnabled();
  bool IsDomTreeEnabled();
  bool IsDevtoolConnected();
  bool IsQuickjsDebugEnabled();
  bool IsJsDebugEnabled();
  bool IsTableDeepCheckEnabled();
  bool IsDisabledLepusngOptimize();
  bool ShouldEnableQuickjsDebug();
  bool GetVsyncAlignedFlushGlobalSwitch();
  bool EnableGlobalFeatureSwitchStatistic();
  BASE_EXPORT_FOR_DEVTOOL std::unordered_set<std::string>
  GetActivatedCDPDomains();
  BASE_EXPORT_FOR_DEVTOOL bool IsDebugModeEnabled();
  std::string GetExperimentSettings(const std::string& key);

  LynxEnv(const LynxEnv&) = delete;
  LynxEnv& operator=(const LynxEnv&) = delete;
  LynxEnv(LynxEnv&&) = delete;
  LynxEnv& operator=(LynxEnv&&) = delete;

 private:
  LynxEnv() = default;

  bool GetEnvMask(const std::string& key);

  friend class base::NoDestructor<LynxEnv>;

  std::mutex mutex_;
  std::map<std::string, bool> env_map_;
  std::unordered_map<std::string, bool> env_mask_map_;
  std::unordered_map<std::string, std::unordered_set<std::string>>
      env_group_sets_;
  std::mutex settings_mutex_;
  std::unordered_map<std::string, std::string> experiment_settings_map_;
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_LYNX_ENV_H_
