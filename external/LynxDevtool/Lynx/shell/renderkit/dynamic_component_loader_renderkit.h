// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_DYNAMIC_COMPONENT_LOADER_RENDERKIT_H_
#define LYNX_SHELL_RENDERKIT_DYNAMIC_COMPONENT_LOADER_RENDERKIT_H_

#include <memory>
#include <string>

#include "shell/renderkit/public/lynx_resource_provider.h"
#include "shell/renderkit/public/lynx_view_builder.h"
#include "tasm/dynamic_component/dynamic_component_loader.h"

namespace lynx ::tasm {
class DynamicComponentLoaderRenderkit : public DynamicComponentLoader {
 public:
  DynamicComponentLoaderRenderkit(
      lynx::LynxResourceProvider* dynamic_component_provider);
  ~DynamicComponentLoaderRenderkit();

  void RequireTemplate(RadonDynamicComponent* dynamic_component,
                       const std::string& url, int trace_id) override;

 private:
  void LoadDynamicComponentCallback(const std::string& result,
                                    const std::string& url, int32_t trace_id);

  std::shared_ptr<lynx::AsyncCallBackProbe> async_callback_probe_;
  lynx::LynxResourceProvider* dynamic_component_provider_ = nullptr;
};
}  // namespace lynx::tasm

#endif  // LYNX_SHELL_RENDERKIT_DYNAMIC_COMPONENT_LOADER_RENDERKIT_H_
