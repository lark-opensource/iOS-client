//
//  BDNativeWebComponentPlugin.m
//  Pods
//
//  Created by bytedance on 2021/10/11.
//

#import "BDNativeMixRenderComponentPlugin.h"
#import <BDWebKit/WKWebView+BDNativeWeb.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#if __has_include(<BDWebKit/BDNativeLiveComponent.h>)
#import <BDWebKit/BDNativeLiveComponent.h>
#define USEBDNativeLiveComponent 1
#endif

#if __has_include(<BDWebKit/BDNativeLottieComponent.h>)
#import <BDWebKit/BDNativeLottieComponent.h>
#define USEBDNativeLottieComponent 1
#endif

@implementation BDNativeMixRenderComponentPlugin

- (void)enableNative:(WKWebView *)webView
{
    NSMutableArray<Class> *nativeComponents = [[NSMutableArray alloc] init];

    Class liveComponentClz = NSClassFromString(@"BDNativeLiveComponent");
    if (liveComponentClz != nil) {
        [nativeComponents addObject:liveComponentClz];
    }

    Class lottieComponentClz = NSClassFromString(@"BDNativeLottieComponent");
    if (lottieComponentClz != nil) {
        [nativeComponents addObject:lottieComponentClz];
    }

    if (nativeComponents.count > 0) {
        [webView bdNative_enableNativeWithComponents:nativeComponents];
    }
}

- (void)check:(WKWebView *)webView withURL:(NSURL *)url
{
    NSMutableDictionary *params = [[NSURL btd_URLWithString:url.absoluteString] btd_queryItemsWithDecoding].mutableCopy;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        if ([key isEqual:@"ttwebview_extension_mixrender"]) {
            NSInteger result = [obj integerValue];
            if (result == 1) {
                [self enableNative:webView];
            }
            *stop = YES;
        }
    }];
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (![webView bdNative_hasNativeEnabled]) {
        NSURL *URL = navigationAction.request.URL;
        [self check:webView withURL:URL];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginObjectPriority)priority
{
    return IWKPluginObjectPriorityHigh;
}

@end
