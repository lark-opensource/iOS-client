// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_IOS_NATIVE_FACADE_DARWIN_H_
#define LYNX_SHELL_IOS_NATIVE_FACADE_DARWIN_H_

#import <Foundation/Foundation.h>

#import "LynxTemplateRender.h"
#import "LynxView.h"
#import "TemplateRenderCallbackProtocol.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "shell/native_facade.h"

std::vector<uint8_t> ConvertNSBinary(NSData* binary);

namespace lynx {
namespace shell {

class NativeFacadeDarwin : public NativeFacade {
 public:
  // TODO(heshan): will use adapter instead after ios platfrom ready
  NativeFacadeDarwin(id<TemplateRenderCallbackProtocol> render) : _render(render) {}
  ~NativeFacadeDarwin() override = default;
  NativeFacadeDarwin(const NativeFacadeDarwin& facade) = default;
  NativeFacadeDarwin& operator=(const NativeFacadeDarwin&) = default;

  void OnDataUpdated() override;

  void OnPageChanged(bool is_first_screen) override;

  void OnTasmFinishByNative() override;

  void OnTemplateLoaded(const std::string& url) override;

  void OnRuntimeReady() override;

  void ReportError(int32_t error_code, const std::string& msg) override;

  void OnModuleMethodInvoked(const std::string& module, const std::string& method,
                             int32_t code) override;

  void OnFirstLoadPerfReady(const std::unordered_map<int32_t, double>& perf,
                            const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnUpdatePerfReady(const std::unordered_map<int32_t, double>& perf,
                         const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnDynamicComponentPerfReady(
      const std::unordered_map<std::string, base::PerfCollector::DynamicComponentPerfInfo>&
          dynamic_component_perf) override;

  void OnConfigUpdated(const lepus::Value& data) override;

  void OnPageConfigDecoded(const std::shared_ptr<tasm::PageConfig>& config) override;

  lepus::Value TriggerLepusMethod(const std::string& method_name,
                                  const lepus::Value& arguments) override;

  void TriggerLepusMethodAsync(const std::string& method_name, const lepus::Value& argus) override;

  std::string TranslateResourceForTheme(const std::string& res_id,
                                        const std::string& theme_key) override;

  void GetI18nResources(const std::string& channel, const std::string& fallback_url) override;

  std::unique_ptr<NativeFacade> Copy() override;

  void SetTiming(tasm::Timing timing) override;

  void MarkDrawEndTimingIfNeeded() override{};
  void UpdateDrawEndTimingState(bool need_draw_end, const std::string& flag) override{};
  void MarkUIOperationQueueFlushTiming(tasm::TimingKey key, const std::string& flag) override{};
  void AddAttributeTimingFlagFromProps(const std::string& flag) override{};

  void InvokeUIMethod(const tasm::LynxGetUIResult& ui_result, const std::string& method,
                      std::unique_ptr<piper::PlatformValue> params,
                      piper::ApiCallBack callback) override;

  void FlushJSBTiming(piper::NativeModuleInfo timing) override;

  void OnSSRHydrateFinished(const std::string& url) override;

  // report all tracker events to platform.
  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack) override;

 private:
  __weak id<TemplateRenderCallbackProtocol> _render;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_IOS_NATIVE_FACADE_DARWIN_H_
