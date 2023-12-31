// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_NATIVE_FACADE_H_
#define LYNX_SHELL_NATIVE_FACADE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/perf_collector.h"
#include "jsbridge/bindings/api_call_back.h"
#include "jsbridge/module/lynx_module_timing.h"
#include "jsbridge/platform_value.h"
#include "lepus/value.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/page_config.h"
#include "tasm/template_data.h"
#include "tasm/timing.h"

namespace lynx {
namespace shell {

class NativeFacade {
 public:
  NativeFacade() = default;
  virtual ~NativeFacade() = default;
  NativeFacade(const NativeFacade& facade) = default;
  NativeFacade& operator=(const NativeFacade&) = default;

  virtual std::unique_ptr<NativeFacade> Copy() = 0;

  virtual void OnDataUpdated() = 0;

  virtual void OnTasmFinishByNative() = 0;

  virtual void OnTemplateLoaded(const std::string& url) = 0;

  virtual void OnRuntimeReady() = 0;

  virtual void ReportError(int32_t error_code, const std::string& msg) = 0;

  virtual void OnModuleMethodInvoked(const std::string& module,
                                     const std::string& method,
                                     int32_t code) = 0;

  virtual void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) = 0;

  virtual void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) = 0;

  virtual void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) = 0;

  virtual void OnConfigUpdated(const lepus::Value& data) = 0;

  virtual void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) = 0;

  virtual std::string TranslateResourceForTheme(
      const std::string& res_id, const std::string& theme_key) = 0;

  virtual lepus::Value TriggerLepusMethod(const std::string& method_name,
                                          const lepus::Value& argus) = 0;

  virtual void TriggerLepusMethodAsync(const std::string& method_name,
                                       const lepus::Value& argus) = 0;

  virtual void GetI18nResources(const std::string& channel,
                                const std::string& fallback_url) = 0;

  virtual void SetTiming(tasm::Timing timing) = 0;

  virtual void MarkDrawEndTimingIfNeeded() = 0;
  virtual void UpdateDrawEndTimingState(bool need_draw_end,
                                        const std::string& flag) = 0;
  virtual void MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                               const std::string& flag) = 0;
  virtual void AddAttributeTimingFlagFromProps(const std::string& flag) = 0;

  // report all tracker events to platform.
  virtual void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) = 0;

  virtual void InvokeUIMethod(const tasm::LynxGetUIResult& ui_result,
                              const std::string& method,
                              std::unique_ptr<piper::PlatformValue> params,
                              piper::ApiCallBack callback) = 0;

  virtual void FlushJSBTiming(piper::NativeModuleInfo timing) = 0;

  virtual void OnSSRHydrateFinished(const std::string& url){};

  virtual void OnPageChanged(bool is_first_screen) {}
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_NATIVE_FACADE_H_
