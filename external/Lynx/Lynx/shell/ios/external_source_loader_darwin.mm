// Copyright 2021 The Lynx Authors. All rights reserved.

#import "shell/ios/external_source_loader_darwin.h"

#import "LynxError.h"
#import "TemplateRenderCallbackProtocol.h"

#include <future>

#include "base/string/string_utils.h"

namespace lynx {
namespace shell {

namespace {

void ReportError(__weak id<TemplateRenderCallbackProtocol> weakRender, NSInteger code,
                 NSString* message) {
  dispatch_async(dispatch_get_main_queue(), ^() {
    id<TemplateRenderCallbackProtocol> render = weakRender;
    [render onErrorOccurred:code message:message];
  });
}

void OnDynamicComponentLoaded(__weak id<TemplateRenderCallbackProtocol> weakRender,
                              std::weak_ptr<JSProxyDarwin> weak_proxy, NSString* url,
                              int32_t callback_id, NSData* data, NSString* error) {
  if (error != nil || data == nil || [data length] == 0) {
    NSString* msg =
        error != nil
            ? [[NSString alloc]
                  initWithFormat:@"Load dynamic component failed, the url is %@, and the "
                                 @"error message is %@",
                                 url, error]
            : [[NSString alloc]
                  initWithFormat:@"The dynamic component's binary template is empty, the url is %@",
                                 url];
    NSInteger code =
        msg != nil ? LynxErrorDynamicComponentLoadFail : LynxErrorDynamicComponentFileEmpty;
    ReportError(weakRender, code, msg);
    auto proxy = weak_proxy.lock();
    if (proxy != nullptr) {
      proxy->RejectDynamicComponentLoad([url UTF8String], callback_id, static_cast<int32_t>(code),
                                        [msg UTF8String]);
    }
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^() {
    id<TemplateRenderCallbackProtocol> render = weakRender;
    [render loadComponent:data withURL:url withCallbackId:callback_id];
  });
}
}  // namespace

std::string ExternalSourceLoaderDarwin::LoadScript(const std::string& url) {
  if (provider_ == nil) {
    return std::string();
  }

  NSString* ns_url = [NSString stringWithUTF8String:url.c_str()];

  __block std::promise<std::string> promise;
  std::future<std::string> future = promise.get_future();

  // avoid ios block default capture this cause dangling pointer
  __weak typeof(_render) weakRender = _render;

  LynxResourceRequest* request = [[LynxResourceRequest alloc] initWithUrl:ns_url];
  [provider_ request:request
          onComplete:^(LynxResourceResponse* response) {
            auto captured_promise = std::move(promise);
            std::string ret;
            if (response.error != nil) {
              NSString* description = response.error.localizedDescription;
              NSString* message = [[NSString alloc]
                  initWithFormat:
                      @"ExternalSourceLoaderDarwin LoadScript failed, url:%@, error message: %@",
                      ns_url, description];
              ReportError(weakRender, LynxErrorCodeExternalSource, message);
            } else {
              ret.assign(reinterpret_cast<const char*>([response.data bytes]),
                         static_cast<size_t>([response.data length]));
              if (ret.empty()) {
                NSString* message =
                    [[NSString alloc] initWithFormat:@"ExternalSourceLoaderDarwin LoadScript "
                                                     @"failed, url:%@, response with null data",
                                                     ns_url];
                ReportError(weakRender, LynxErrorCodeExternalSource, message);
              }
            }

            captured_promise.set_value(std::move(ret));
          }];

  using namespace std::chrono_literals;  // NOLINT
  static constexpr auto kLoadScriptTimeout = 5s;
  if (future.wait_for(kLoadScriptTimeout) != std::future_status::ready) {
    NSString* message = [[NSString alloc]
        initWithFormat:@"ExternalSourceLoaderDarwin::LoadScript timeout. url: %@", ns_url];
    ReportError(weakRender, LynxErrorCodeExternalSource, message);
    return std::string();
  }
  return future.get();
}

void ExternalSourceLoaderDarwin::LoadScriptAsync(const std::string& url, int32_t callback_id) {
  if (provider_ == nil) {
    return;
  }

  NSString* nsUrl = [NSString stringWithUTF8String:url.c_str()];
  LynxResourceRequest* request = [[LynxResourceRequest alloc] initWithUrl:nsUrl];

  // avoid ios block default capture this cause dangling pointer
  __weak typeof(_render) weakRender = _render;
  std::weak_ptr<JSProxyDarwin> weak_proxy = proxy_;

  [provider_
         request:request
      onComplete:^(LynxResourceResponse* response) {
        if (response.error != nil) {
          NSString* description = response.error.localizedDescription;
          NSString* message = [[NSString alloc]
              initWithFormat:
                  @"ExternalSourceLoaderDarwin LoadScriptAsync failed, url:%@, error message: %@",
                  nsUrl, description];
          ReportError(weakRender, LynxErrorCodeExternalSource, message);
          return;
        }

        std::string data{reinterpret_cast<const char*>([response.data bytes]),
                         static_cast<size_t>([response.data length])};
        if (data.empty()) {
          NSString* message =
              [[NSString alloc] initWithFormat:@"ExternalSourceLoaderDarwin LoadScriptAsync "
                                               @"failed, url:%@, response with null data",
                                               nsUrl];
          ReportError(weakRender, LynxErrorCodeExternalSource, message);
          return;
        }

        auto proxy = weak_proxy.lock();
        if (proxy != nullptr) {
          proxy->EvaluateScript([nsUrl UTF8String], std::move(data), callback_id);
        }
      }];
}

void ExternalSourceLoaderDarwin::LoadDynamicComponent(const std::string& url, int32_t callback_id) {
  NSString* nsUrl = [NSString stringWithUTF8String:url.c_str()];
  __weak typeof(_render) weakRender = _render;
  std::weak_ptr<JSProxyDarwin> weak_proxy = proxy_;
  if (_dynamicComponentProvider != nil) {
    LynxResourceRequest* request = [[LynxResourceRequest alloc] initWithUrl:nsUrl];
    [_dynamicComponentProvider
           request:request
        onComplete:^(LynxResourceResponse* response) {
          OnDynamicComponentLoaded(
              weakRender, weak_proxy, nsUrl, callback_id, response.data,
              response.error != nil ? [[response error] localizedDescription] : nil);
        }];
    return;
  }
  if (_dynamicComponentFetcher != nil) {
    [_dynamicComponentFetcher
        loadDynamicComponent:nsUrl
             withLoadedBlock:^(NSData* _Nullable data, NSError* _Nullable error) {
               OnDynamicComponentLoaded(weakRender, weak_proxy, nsUrl, callback_id, data,
                                        error != nil ? [error localizedDescription] : nil);
             }];

    return;
  }
  OnDynamicComponentLoaded(
      weakRender, weak_proxy, nsUrl, callback_id, nil,
      [[NSString alloc] initWithFormat:@"ExternalSourceLoaderDarwin Load dynamic component failed, "
                                       @"since there is no provider or fetcher."]);
}

void ExternalSourceLoaderDarwin::SetJSProxy(const std::shared_ptr<JSProxyDarwin>& proxy) {
  proxy_ = proxy;
}

}  // namespace shell
}  // namespace lynx
