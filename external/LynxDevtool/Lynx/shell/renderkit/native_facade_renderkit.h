// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_NATIVE_FACADE_RENDERKIT_H_
#define LYNX_SHELL_RENDERKIT_NATIVE_FACADE_RENDERKIT_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "shell/lynx_shell.h"
#include "shell/native_facade.h"
#include "shell/renderkit/public/template_render_callback.h"

namespace lynx {
namespace shell {
class NativeFacadeRenderkit : public NativeFacade {
 public:
  explicit NativeFacadeRenderkit(TemplateRenderCallback* callback)
      : callback_(callback) {}

  NativeFacadeRenderkit(const NativeFacadeRenderkit& facade) = default;

  NativeFacadeRenderkit& operator=(const NativeFacadeRenderkit&) = default;

  std::unique_ptr<NativeFacade> Copy() override;

  void OnDataUpdated() override;

  void OnPageChanged(bool is_first_screen) override;

  void OnTasmFinishByNative() override;

  void OnTemplateLoaded(const std::string& url) override;

  void OnRuntimeReady() override;

  void ReportError(int32_t error_code, const std::string& msg) override;

  void OnModuleMethodInvoked(const std::string& module,
                             const std::string& method, int32_t code) override;

  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string,
                               base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) override;

  void OnConfigUpdated(const lepus::Value& data) override;

  void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override;

  std::string TranslateResourceForTheme(const std::string& res_id,
                                        const std::string& theme_key) override;

  lepus::Value TriggerLepusMethod(const std::string& method_name,
                                  const lepus::Value& arguments) override;

  void TriggerLepusMethodAsync(const std::string& js_method_name,
                               const lepus::Value& args) override;

  void GetI18nResources(const std::string& channel,
                        const std::string& fallback_url) override;

  void SetTiming(tasm::Timing timing) override;

  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) override;

  void InvokeUIMethod(const tasm::LynxGetUIResult& ui_result,
                      const std::string& method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback) override;

  void FlushJSBTiming(piper::NativeModuleInfo timing) override;

  void MarkDrawEndTimingIfNeeded() override {}
  void UpdateDrawEndTimingState(bool need_draw_end,
                                const std::string& flag) override {}
  void MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                       const std::string& flag) override {}

  void AddAttributeTimingFlagFromProps(const std::string& flag) override {}

 private:
  TemplateRenderCallback* callback_ = nullptr;
};
}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_NATIVE_FACADE_RENDERKIT_H_
