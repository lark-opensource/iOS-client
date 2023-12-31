// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_HEADLESS_NATIVE_FACADE_HEADLESS_H_
#define LYNX_SHELL_HEADLESS_NATIVE_FACADE_HEADLESS_H_

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

struct NativeFacadeHeadless : public NativeFacadeEmptyImpl {
  NativeFacadeHeadless() = default;
  ~NativeFacadeHeadless() override;
  NativeFacadeHeadless(const NativeFacadeHeadless& facade) = default;
  NativeFacadeHeadless& operator=(const NativeFacadeHeadless&) = default;

  void OnRuntimeReady() override;

  void ReportError(int32_t error_code, const std::string& msg) override;

  void OnConfigUpdated(const lepus::Value& data) override;

  void OnPageConfigDecoded(
      const std::shared_ptr<tasm::PageConfig>& config) override;

  std::unique_ptr<NativeFacade> Copy() override;

  std::shared_ptr<fml::AutoResetWaitableEvent> arwe_ =
      std::make_shared<fml::AutoResetWaitableEvent>();
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_HEADLESS_NATIVE_FACADE_HEADLESS_H_
