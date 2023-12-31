// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_IOS_EXTERNAL_SOURCE_LOADER_DARWIN_H_
#define LYNX_SHELL_IOS_EXTERNAL_SOURCE_LOADER_DARWIN_H_

#include <memory>
#include <string>

#import "LynxDynamicComponentFetcher.h"
#import "LynxResourceProvider.h"
#import "LynxTemplateRender.h"
#include "shell/external_source_loader.h"
#import "shell/ios/js_proxy_darwin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TemplateRenderCallbackProtocol;

namespace lynx {
namespace shell {

class ExternalSourceLoaderDarwin : public ExternalSourceLoader {
 public:
  ExternalSourceLoaderDarwin(id<LynxResourceProvider> provider,
                             id<LynxResourceProvider> dynamicComponentProvider,
                             id<LynxDynamicComponentFetcher> dynamicComponentFetcher,
                             id<TemplateRenderCallbackProtocol> render)
      : provider_(provider),
        _dynamicComponentProvider(dynamicComponentProvider),
        _dynamicComponentFetcher(dynamicComponentFetcher),
        _render(render) {}
  ~ExternalSourceLoaderDarwin() override = default;

  std::string LoadScript(const std::string& url) override;

  void LoadScriptAsync(const std::string& url, int32_t callback_id) override;

  void LoadDynamicComponent(const std::string& url, int32_t callback_id) override;

  void SetJSProxy(const std::shared_ptr<JSProxyDarwin>& proxy);

 private:
  id<LynxResourceProvider> provider_;

  id<LynxResourceProvider> _dynamicComponentProvider;
  id<LynxDynamicComponentFetcher> _dynamicComponentFetcher;

  __weak id<TemplateRenderCallbackProtocol> _render;

  std::weak_ptr<JSProxyDarwin> proxy_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_IOS_EXTERNAL_SOURCE_LOADER_DARWIN_H_

NS_ASSUME_NONNULL_END
