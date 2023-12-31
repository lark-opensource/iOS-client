//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxKryptonLoader.h"
#import "LynxImageLoader.h"
#import "LynxResourceFetcher.h"
#import "LynxService.h"
#import "LynxServiceTrackEventProtocol.h"
#include "canvas/base/log.h"
#include "js_proxy_darwin.h"
#include "shell/lynx_shell.h"

@interface LynxKryptonResourceLoadDelegate : NSObject <LynxResourceLoadDelegate>
@property(nonatomic, retain) id<KryptonStreamLoadDelegate> delegate;
@end

@implementation LynxKryptonResourceLoadDelegate
- (void)onStart:(NSInteger)contentLength {
  [_delegate onStart:contentLength];
}

- (void)onData:(NSData*)data {
  [_delegate onData:data];
}

- (void)onEnd {
  [_delegate onEnd];
  _delegate = nil;
}

- (void)onError:(NSString*)msg {
  [_delegate onError:msg];
  _delegate = nil;
}
@end

@implementation LynxKryptonLoader {
  NSInteger _runtimeId;
}

- (void)setRuntimeId:(NSInteger)runtimeId {
  _runtimeId = runtimeId;
}

- (void)loadURL:(NSString*)url callback:(KryptonLoaderCallback)callback {
  DCHECK(callback != nullptr);
  LynxView* view = [self findLynxView];
  if (!view) {
    callback(@"loadUrl failed! view = nil", nil);
    return;
  }

  NSURL* nsUrl = [NSURL URLWithString:url];
  if ([nsUrl.scheme isEqualToString:@"data"]) {
    [LynxKryptonLoader loadURLFallback:nsUrl callback:callback];
    return;
  }

  auto internalCallback =
      ^(NSData* _Nullable data, NSError* _Nullable error, NSURL* _Nullable imageURL) {
        if (error) {
          [LynxKryptonLoader loadURLFallback:nsUrl callback:callback];
        } else {
          KRYPTON_LOGI("internalLoad success ") << [data length];
          if (callback) {
            callback(nil, data);
          }
        }
      };

  id<LynxResourceFetcher> fetcher = view.resourceFetcher;
  if (fetcher && [fetcher respondsToSelector:@selector(loadResourceWithURL:type:completion:)]) {
    KRYPTON_LOGI("internalLoad with fetcher ");
    [fetcher loadResourceWithURL:nsUrl
                            type:LynxFetchResUnknown
                      completion:^(BOOL isSyncCallback, NSData* _Nullable data,
                                   NSError* _Nullable error, NSURL* _Nullable resUrl) {
                        internalCallback(data, error, resUrl);
                      }];
    return;
  }

  KRYPTON_LOGI("internalLoad with imageLoader ");
  [[LynxImageLoader sharedInstance]
      loadCanvasImageFromURL:nsUrl
                 contextInfo:@{LynxImageFetcherContextKeyLynxView : view}
                  processors:@[]
                imageFetcher:view.imageFetcher
                   completed:internalCallback];
}

- (void)loadURL:(nullable NSString*)url
    withStreamLoadDelegate:(nonnull id<KryptonStreamLoadDelegate>)delegate {
  DCHECK(delegate != nil);
  NSURL* nsUrl = [NSURL URLWithString:url];

  if (![nsUrl.scheme isEqualToString:@"data"]) {
    id<LynxResourceFetcher> fetcher = [[self findLynxView] resourceFetcher];
    if ([fetcher respondsToSelector:@selector(loadResourceWithURL:delegate:)]) {
      auto lynxDelegate = [LynxKryptonResourceLoadDelegate new];
      lynxDelegate.delegate = delegate;
      [fetcher loadResourceWithURL:nsUrl delegate:lynxDelegate];
      return;
    }
  }

  return [self loadURL:url
              callback:^(NSString* _Nullable err, NSData* _Nullable data) {
                if (err) {
                  [delegate onError:err];
                } else {
                  [delegate onStart:[data length]];
                  [delegate onData:data];
                  [delegate onEnd];
                }
              }];
}

- (NSString*)redirectURL:(NSString*)url {
  auto proxy = lynx::shell::JSProxyDarwin::GetJSProxyById(_runtimeId);
  if (proxy) {
    id<LynxResourceFetcher> fetcher = proxy->GetLynxView().resourceFetcher;
    if (fetcher && [fetcher respondsToSelector:@selector(redirectURL:)]) {
      NSString* redirect = [fetcher redirectURL:url];
      if (redirect != nil) {
        url = redirect;
      }
    }
  }
  return url;
}

- (UIImage*)loadImageData:(NSData*)data {
  return [LynxService(LynxServiceImageProtocol) decodeImage:data];
}

- (void)reportLoaderTrackEvent:(NSString*)eventName format:(NSString*)format data:(id)formatData {
  [LynxService(LynxServiceTrackEventProtocol) kProbe_SpecialEventName:eventName
                                                               format:format
                                                                 data:formatData];
}

- (LynxView*)findLynxView {
  auto js_proxy = lynx::shell::JSProxyDarwin::GetJSProxyById(_runtimeId);
  return js_proxy ? js_proxy->GetLynxView() : nil;
}

+ (void)loadURLFallback:(NSURL*)nsUrl callback:(KryptonLoaderCallback)callback {
  NSString* logUrl = [nsUrl description];
  if (logUrl.length > 200) {
    logUrl = [logUrl substringToIndex:200];
  }
  KRYPTON_LOGI("load data fallback ") << ([logUrl UTF8String] ?: "");
  NSURLSessionDataTask* task = [NSURLSession.sharedSession
        dataTaskWithURL:nsUrl
      completionHandler:^(NSData* received, NSURLResponse* response, NSError* error) {
        KRYPTON_LOGI("load data fallback complete");
        if (error) {
          callback([error localizedDescription], nil);
        } else {
          callback(nil, received);
        }
      }];
  [task resume];
}

@end
