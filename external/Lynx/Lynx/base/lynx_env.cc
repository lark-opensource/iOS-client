// Copyright 2021 The Lynx Authors. All rights reserved.

#include "base/lynx_env.h"

#include <unordered_map>
#include <utility>

#if OS_ANDROID
#include "base/android/lynx_env_android.h"
#elif OS_IOS || OS_OSX
#include "tasm/ios/config_darwin.h"
#endif

namespace lynx {
namespace base {

LynxEnv& LynxEnv::GetInstance() {
  static base::NoDestructor<LynxEnv> instance;
  return *instance;
}

void LynxEnv::onPiperInvoked(const std::string& module_name,
                             const std::string& method_name,
                             const std::string& param_str,
                             const std::string& url,
                             const std::string& invoke_session) {
#if OS_ANDROID
  base::LynxEnvAndroid::onPiperInvoked(module_name, method_name, param_str,
                                       url);
#endif
}

void LynxEnv::onPiperResponsed(const std::string& module_name,
                               const std::string& method_name,
                               const std::string& url,
                               const std::string& response,
                               const std::string& invoke_session) {
#if OS_ANDROID
#endif
}

void LynxEnv::SetEnv(const std::string& key, bool value) {
  std::lock_guard<std::mutex> lock(mutex_);

  auto old_value = env_map_.find(key);
  if (old_value != env_map_.end()) {
    env_map_.erase(old_value);
  }

  env_map_.emplace(key, value);
}

void LynxEnv::SetGroupedEnv(const std::string& key, bool value,
                            const std::string& group_key) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = env_group_sets_.find(group_key);
  if (it == env_group_sets_.end()) {
    std::unordered_set<std::string> new_set;
    it = env_group_sets_.insert(it, std::make_pair(group_key, new_set));
  }
  if (value) {
    it->second.insert(key);
  } else {
    it->second.erase(key);
  }
}

void LynxEnv::SetGroupedEnv(
    const std::unordered_set<std::string>& new_group_values,
    const std::string& group_key) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto old_value = env_group_sets_.find(group_key);
  if (old_value != env_group_sets_.end()) {
    env_group_sets_.erase(old_value);
  }
  env_group_sets_.emplace(group_key, new_group_values);
}

bool LynxEnv::GetEnv(const std::string& key, bool default_value) {
  std::lock_guard<std::mutex> lock(mutex_);

  auto value = env_map_.find(key);
  bool ret_value = value != env_map_.end() ? (*value).second : default_value;
  return ret_value && GetEnvMask(key);
}

void LynxEnv::SetEnvMask(const std::string& key, bool value) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto old_value = env_mask_map_.find(key);
  if (old_value != env_mask_map_.end()) {
    env_mask_map_.erase(old_value);
  }
  env_mask_map_.emplace(key, value);
}

bool LynxEnv::GetEnvMask(const std::string& key) {
  auto value = env_mask_map_.find(key);
  return value != env_mask_map_.end() ? (*value).second : true;
}

std::unordered_set<std::string> LynxEnv::GetGroupedEnv(
    const std::string& group_key) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = env_group_sets_.find(group_key);
  if (it != env_group_sets_.end()) {
    return it->second;
  }
  return std::unordered_set<std::string>();
}

bool LynxEnv::IsLynxDebugEnabled() {
  return GetEnv("lynx_debug_enabled", false);
}

bool LynxEnv::IsDevtoolComponentAttach() {
  return GetEnv(kLynxDevtoolComponentAttach, false);
}

bool LynxEnv::IsDevtoolEnabled() { return GetEnv("enable_devtool", false); }

bool LynxEnv::IsDevtoolEnabledForDebuggableView() {
  return GetEnv("enable_devtool_for_debuggable_view", false);
}

bool LynxEnv::IsQuickjsCacheEnabled() {
  return GetEnv("enable_quickjs_cache", true) &&
         !GetEnv("force_disable_quickjs_cache", false);
}

bool LynxEnv::IsDisableCollectLeak() {
  return GetEnv("disable_collect_leak", true);
}

bool LynxEnv::IsLayoutPerformanceEnabled() {
  return GetEnv(kLynxLayoutPerformanceEnable, false);
}

bool LynxEnv::IsV8Enabled() {
#if OS_ANDROID || OS_IOS
  return GetEnv("enable_v8", false);
#else
  return IsDevtoolEnabled() && GetEnv("enable_v8", true);
#endif
}

bool LynxEnv::IsPiperMonitorEnabled() {
  return GetEnv("enablePiperMonitor", false);
}

bool LynxEnv::IsDomTreeEnabled() {
  return IsDevtoolEnabled() && GetEnv(kLynxEnableDomTree, true);
}

bool LynxEnv::ShouldEnableQuickjsDebug() {
  return !IsV8Enabled() && IsQuickjsDebugEnabled();
}

bool LynxEnv::GetVsyncAlignedFlushGlobalSwitch() {
  return GetEnv("enable_vsync_aligned_flush", true);
}

bool LynxEnv::EnableGlobalFeatureSwitchStatistic() {
  return GetEnv("enable_global_feature_switch_statistic", false);
}

bool LynxEnv::IsDevtoolConnected() {
  return GetEnv("devtool_connected", false);
}

bool LynxEnv::IsQuickjsDebugEnabled() {
#if OS_ANDROID || OS_IOS
  return IsDevtoolEnabled() && GetEnv("enable_quickjs_debug", true);
#else
  return false;
#endif
}

bool LynxEnv::IsJsDebugEnabled() {
#if OS_ANDROID || OS_IOS
  return IsV8Enabled() || IsQuickjsDebugEnabled();
#else
  return IsV8Enabled();
#endif
}

bool LynxEnv::IsTableDeepCheckEnabled() {
  return GetEnv(kLynxEnableTableDeepCheck, false);
}

bool LynxEnv::IsDisabledLepusngOptimize() {
  return GetEnv("disable_lepusng_optimize", false);
}

std::unordered_set<std::string> LynxEnv::GetActivatedCDPDomains() {
  return GetGroupedEnv("activated_cdp_domains");
}

bool LynxEnv::IsDebugModeEnabled() {
#if LYNX_ENABLE_TRACING || ENABLE_ARK_RECORDER
  return true;
#else
  return false;
#endif
}

std::string LynxEnv::GetExperimentSettings(const std::string& key) {
#ifndef LYNX_UNIT_TEST
#if OS_ANDROID
  std::lock_guard<std::mutex> lock(settings_mutex_);
  if (experiment_settings_map_.count(key) > 0) {
    return experiment_settings_map_[key];
  }
  std::string value = base::LynxEnvAndroid::GetExperimentSettings(key);
  if (value.empty()) {
    value = "";
  }
  experiment_settings_map_.emplace(key, value);
  return value;
#elif OS_IOS || OS_OSX
  return tasm::LynxConfigDarwin::getExperimentSettings(key);
#endif
#endif
  return experiment_settings_map_[key];
}

}  // namespace base
}  // namespace lynx
