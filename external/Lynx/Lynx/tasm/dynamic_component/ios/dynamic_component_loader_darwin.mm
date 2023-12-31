// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/dynamic_component/ios/dynamic_component_loader_darwin.h"

#import "LynxError.h"
#import "LynxLog.h"
#import "LynxService.h"
#import "LynxThreadManager.h"
#import "TemplateRenderCallbackProtocol.h"

#include "base/debug/lynx_assert.h"
#include "base/trace_event/trace_event.h"
#include "shell/ios/native_facade_darwin.h"

namespace lynx {
namespace tasm {

namespace {
// convert NSError to an optional error message which C could understand
std::optional<std::string> GenerateErrorMessage(NSError* error) {
  if (error) {
    return [[error localizedDescription] UTF8String];
  }
  return std::nullopt;
}
}  // namespace

void DynamicComponentLoaderDarwin::RequireTemplate(RadonDynamicComponent* dynamic_component,
                                                   const std::string& url, int trace_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RequireTemplate. ", "url", url);

  __block std::string block_url = url;
  __block volatile BOOL invoked = NO;
  __block NSString* comp_url = [NSString stringWithUTF8String:url.c_str()];
  __block NSObject* object = [[NSObject alloc] init];
  std::weak_ptr<DynamicComponentLoader> weak = shared_from_this();

  StartRecordRequireTime(url, trace_id);

  LoadedBlock loaded_block = ^(NSData* _Nullable data, NSError* _Nullable error) {
    @synchronized(object) {
      if (invoked) {
        LLogError(@"DynamicComponent. Illegal callback invocation from native. The loaded "
                  @"callback can only be invoked once! The url is %@",
                  comp_url);
        return;
      }
      invoked = YES;
    }

    auto loader_ptr = weak.lock();
    if (loader_ptr) {
      // Validate before report async component loading
      if (!error && data.length > 0) {
        [LynxService(LynxServiceMonitorProtocol)
            reportErrorGlobalContextTag:LynxContextTagLastLynxAsyncComponentURL
                                   data:[NSString
                                            stringWithCString:block_url.c_str()
                                                     encoding:[NSString defaultCStringEncoding]]];
      }

      loader_ptr->DidLoadComponent(DynamicComponentLoader::Callback{
          std::move(block_url), ConvertNSBinary(data), GenerateErrorMessage(error),
          dynamic_component, trace_id});
    }
  };

  [_fetcher_wrapper fetchResource:comp_url withLoadedBlock:loaded_block];
}

void DynamicComponentLoaderDarwin::PreloadTemplates(const std::vector<std::string>& urls) {
  std::weak_ptr<DynamicComponentLoader> weak_loader = shared_from_this();

  auto PreloadSingleTemplate = [weak_loader,
                                fetcher_wrapper = this->_fetcher_wrapper](const std::string& url) {
    __block std::string block_url = url;
    __block NSString* ns_url = [NSString stringWithUTF8String:url.c_str()];
    __block BOOL invoked = NO;
    __block NSObject* object = [[NSObject alloc] init];

    LoadedBlock preloaded_block = ^(NSData* _Nullable data, NSError* _Nullable error) {
      @synchronized(object) {
        if (invoked) {
          LLogError(@"DynamicComponent. Illegal callback invocation from native. The preloaded "
                    @"callback can only be invoked once! The url is %@",
                    ns_url);
          return;
        }
        invoked = YES;
      }

      if (error || [data length] == 0) {
        LLogError(@"Preload dynamic component failed. The url is %@, and the error is %@", ns_url,
                  error ? [error localizedDescription] : @"the template binary is empty");
        return;
      }

      auto loader = weak_loader.lock();
      if (loader != nullptr) {
        loader->DidPreloadTemplate(block_url, ConvertNSBinary(data));
      }
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
      [fetcher_wrapper fetchResource:ns_url withLoadedBlock:preloaded_block];
    });
  };

  std::for_each(urls.begin(), urls.end(), std::move(PreloadSingleTemplate));
}

void DynamicComponentLoaderDarwin::ReportErrorInner(ErrCode code, const std::string& msg) {
  __weak id<TemplateRenderCallbackProtocol> weakRender = _weak_render;
  __block NSString* ns_msg = [NSString stringWithUTF8String:msg.c_str()];
  [LynxThreadManager runBlockInMainQueue:^{
    id<TemplateRenderCallbackProtocol> strongRender = weakRender;
    if (strongRender) {
      [strongRender onErrorOccurred:code message:ns_msg];
    }
  }];
}

void DynamicComponentLoaderDarwin::SetEnableLynxResourceService(bool enable) {
  [_fetcher_wrapper setEnableLynxService:enable];
}

}  // namespace tasm
}  // namespace lynx
