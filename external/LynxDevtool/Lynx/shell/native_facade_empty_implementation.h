// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_NATIVE_FACADE_EMPTY_IMPLEMENTATION_H_
#define LYNX_SHELL_NATIVE_FACADE_EMPTY_IMPLEMENTATION_H_

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
#include "shell/native_facade.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/page_config.h"
#include "tasm/template_data.h"
#include "tasm/timing.h"

namespace lynx {
namespace shell {

class NativeFacadeEmptyImpl : public NativeFacade {
 public:
  NativeFacadeEmptyImpl() = default;
  virtual ~NativeFacadeEmptyImpl() = default;
  NativeFacadeEmptyImpl(const NativeFacadeEmptyImpl& facade) = default;
  NativeFacadeEmptyImpl& operator=(const NativeFacadeEmptyImpl&) = default;

  virtual void OnDataUpdated() override {}

  virtual void OnTasmFinishByNative() override {}

  virtual void OnTemplateLoaded(const std::string& url) override {}

  virtual void OnRuntimeReady() override {}

  virtual void ReportError(int32_t error_code,
                           const std::string& msg) override {}

  virtual void OnModuleMethodInvoked(const std::string& module,
                                     const std::string& method,
                                     int32_t code) override {}

  virtual void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {}

  virtual void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override {}

  virtual void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) override {}

  virtual void OnConfigUpdated(const lepus::Value& data) override {}

  virtual void Report(
      std::vector<std::unique_ptr<tasm::PropBundle>> stack) override {}

  virtual void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override {}

  virtual std::string TranslateResourceForTheme(
      const std::string& res_id, const std::string& theme_key) override {
    return "success";
  }

  virtual lepus::Value TriggerLepusMethod(const std::string& method_name,
                                          const lepus::Value& argus) override {
    return lepus::Value();
  }

  virtual void TriggerLepusMethodAsync(const std::string& method_name,
                                       const lepus::Value& argus) override {}

  virtual void GetI18nResources(const std::string& channel,
                                const std::string& fallback_url) override {}

  virtual void SetTiming(tasm::Timing timing) override {}

  virtual void InvokeUIMethod(const tasm::LynxGetUIResult& ui_result,
                              const std::string& method,
                              std::unique_ptr<piper::PlatformValue> params,
                              piper::ApiCallBack callback) override {}

  virtual void FlushJSBTiming(piper::NativeModuleInfo timing) override {}

  virtual void MarkDrawEndTimingIfNeeded() override {}
  virtual void UpdateDrawEndTimingState(bool need_draw_end,
                                        const std::string& flag) override {}
  virtual void MarkUIOperationQueueFlushTiming(
      tasm::TimingKey key, const std::string& flag) override {}
  virtual void AddAttributeTimingFlagFromProps(
      const std::string& flag) override {}
};

}  // namespace shell
}  // namespace lynx
#endif  // LYNX_SHELL_NATIVE_FACADE_EMPTY_IMPLEMENTATION_H_
