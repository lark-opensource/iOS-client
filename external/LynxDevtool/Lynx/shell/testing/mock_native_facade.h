// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_TESTING_MOCK_NATIVE_FACADE_H_
#define LYNX_SHELL_TESTING_MOCK_NATIVE_FACADE_H_

#include <any>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/perf_collector.h"
#include "shell/native_facade_empty_implementation.h"
#include "third_party/fml/synchronization/waitable_event.h"

namespace lynx {
namespace shell {

struct MockNativeFacade : public NativeFacadeEmptyImpl {
  MockNativeFacade() = default;
  ~MockNativeFacade() override;
  MockNativeFacade(const MockNativeFacade& facade) = default;
  MockNativeFacade& operator=(const MockNativeFacade&) = default;

  void OnDataUpdated() override;

  void OnTemplateLoaded(const std::string& url) override;

  void OnSSRHydrateFinished(const std::string& url) override;

  void OnRuntimeReady() override;

  void OnTasmFinishByNative() override;

  void ReportError(int32_t error_code, const std::string& msg) override;

  void OnModuleMethodInvoked(const std::string& module,
                             const std::string& method, int32_t code) override;

  void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) override;

  void OnConfigUpdated(const lepus::Value& data) override;

  void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override;

  std::string TranslateResourceForTheme(const std::string& res_id,
                                        const std::string& theme_key) override;

  void GetI18nResources(const std::string& channel,
                        const std::string& fallback_url) override;

  std::unique_ptr<NativeFacade> Copy() override;

  std::shared_ptr<fml::AutoResetWaitableEvent> arwe =
      std::make_shared<fml::AutoResetWaitableEvent>();

  struct Result {
    bool on_correct_thread = false;
    std::unordered_map<std::string, std::any> bundle;

    std::any& operator[](const char* key) { return bundle[key]; }

    std::any& operator[](const std::string& key) { return bundle[key]; }

    operator bool() const { return on_correct_thread; }
  };

  std::any& operator[](const std::string& key) { return result[key]; }

  std::any& operator[](const char* key) { return result[key]; }

  operator bool() const { return result; }

  Result result;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_TESTING_MOCK_NATIVE_FACADE_H_
