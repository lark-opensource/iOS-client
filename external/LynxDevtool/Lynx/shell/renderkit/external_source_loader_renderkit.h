// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_EXTERNAL_SOURCE_LOADER_RENDERKIT_H_
#define LYNX_SHELL_RENDERKIT_EXTERNAL_SOURCE_LOADER_RENDERKIT_H_

#include <memory>
#include <string>
#include <utility>

#include "shell/renderkit/lynx_template_render.h"
#include "shell/renderkit/public/lynx_resource_provider.h"

namespace lynx {
namespace shell {
class ExternalSourceLoaderRenderkit : public ExternalSourceLoader {
 public:
  explicit ExternalSourceLoaderRenderkit(
      LynxTemplateRender* render,
      lynx::LynxResourceProvider* external_js_provider,
      lynx::LynxResourceProvider* dynamic_component_provider)
      : render_(render),
        external_js_provider_(external_js_provider),
        dynamic_component_provider_(dynamic_component_provider),
        async_callback_probe_(new AsyncCallBackProbe){};
  ~ExternalSourceLoaderRenderkit() override;
  void LoadDynamicComponent(const std::string& url,
                            int32_t callback_id) override;
  std::string LoadScript(const std::string& url) override;
  void LoadScriptAsync(const std::string& url, int32_t callback_id) override;

 private:
  void LoadScriptAsyncCallback(const std::string& result,
                               const std::string& url, int32_t callback_id);
  void LoadDynamicComponentCallback(const std::string& result,
                                    const std::string& url,
                                    int32_t callback_id);

  LynxTemplateRender* render_ = nullptr;
  lynx::LynxResourceProvider* external_js_provider_ = nullptr;
  lynx::LynxResourceProvider* dynamic_component_provider_ = nullptr;
  std::shared_ptr<AsyncCallBackProbe> async_callback_probe_;
};
}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_EXTERNAL_SOURCE_LOADER_RENDERKIT_H_
