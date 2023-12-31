// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_TEMPLATE_RENDER_CALLBACK_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_TEMPLATE_RENDER_CALLBACK_H_

#include <string>
#include <unordered_map>

#include "lynx_export.h"

namespace lynx {
class LYNX_EXPORT TemplateRenderCallback {
 public:
  virtual ~TemplateRenderCallback() = default;

  virtual void OnLoaded(const std::string& url) = 0;

  virtual void OnRuntimeReady() = 0;

  virtual void OnDataUpdated() = 0;

  virtual void OnPageChanged(bool is_first_screen) = 0;

  virtual void OnFirstLoadPerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) = 0;

  virtual void OnUpdatePerfReady(
      const std::unordered_map<int32_t, double>& perf,
      const std::unordered_map<int32_t, std::string>& perf_timing) = 0;

  virtual void onErrorOccurred(int32_t error_code,
                               const std::string& message) = 0;

  virtual void onThemeUpdatedByJs(
      const std::unordered_map<std::string, std::string>& theme) = 0;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_TEMPLATE_RENDER_CALLBACK_H_
