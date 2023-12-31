// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_DYNAMIC_COMPONENT_IOS_DYNAMIC_COMPONENT_LOADER_DARWIN_H_
#define LYNX_TASM_DYNAMIC_COMPONENT_IOS_DYNAMIC_COMPONENT_LOADER_DARWIN_H_

#include <string>
#include <vector>

#import "LynxExternalResourceFetcherWrapper.h"
#import "LynxTemplateRender.h"
#include "tasm/dynamic_component/dynamic_component_loader.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TemplateRenderCallbackProtocol;

namespace lynx {
namespace tasm {

class DynamicComponentLoaderDarwin : public DynamicComponentLoader {
 public:
  DynamicComponentLoaderDarwin(id<LynxDynamicComponentFetcher> fetcher,
                               id<TemplateRenderCallbackProtocol> render)
      : _fetcher_wrapper(
            [[LynxExternalResourceFetcherWrapper alloc] initWithDynamicComponentFetcher:fetcher]),
        _weak_render(render) {}
  virtual ~DynamicComponentLoaderDarwin() override = default;
  void RequireTemplate(RadonDynamicComponent* comp, const std::string& url, int trace_id) override;

  void SetEnableLynxResourceService(bool enable) override;

  void PreloadTemplates(const std::vector<std::string>& urls) override;

 protected:
  void ReportErrorInner(ErrCode code, const std::string& msg) override;

 private:
  LynxExternalResourceFetcherWrapper* _fetcher_wrapper;
  __weak id<TemplateRenderCallbackProtocol> _weak_render;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_DYNAMIC_COMPONENT_IOS_DYNAMIC_COMPONENT_LOADER_DARWIN_H_

NS_ASSUME_NONNULL_END
