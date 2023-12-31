//
//  BDResourceLoaderPluginObject.m
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import "BDResourceLoaderPluginObject.h"

#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import <BDXResourceLoader/BDXResourceLoader.h>
#import <BDWebCore/WKWebView+Plugins.h>

#import "WKWebView+BDPrivate.h"
#import "BDWebInterceptor.h"
#import "WKWebView+BDInterceptor.h"
#import "BDWebRequestDecorator.h"


@implementation WKWebViewConfiguration (BDResouceLoaderPlugin)

- (BOOL)bdw_enableResourceLoaderWithTTNet
{
    return [objc_getAssociatedObject(self, @selector(bdw_enableResourceLoaderWithTTNet)) boolValue];
}

- (void)setBdw_enableResourceLoaderWithTTNet:(BOOL)bdw_enableResourceLoaderWithTTNet
{
    objc_setAssociatedObject(self,
                             @selector(bdw_enableResourceLoaderWithTTNet),
                             @(bdw_enableResourceLoaderWithTTNet),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdw_enableResourceLoaderWithFalcon
{
    return [objc_getAssociatedObject(self, @selector(bdw_enableResourceLoaderWithFalcon)) boolValue];
}

- (void)setBdw_enableResourceLoaderWithFalcon:(BOOL)bdw_enableResourceLoaderWithFalcon
{
    objc_setAssociatedObject(self,
                             @selector(bdw_enableResourceLoaderWithFalcon),
                             @(bdw_enableResourceLoaderWithFalcon),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdw_addCommonParamsWithGeckoResourceURL
{
    return [objc_getAssociatedObject(self, @selector(bdw_addCommonParamsWithGeckoResourceURL)) boolValue];
}

- (void)setBdw_addCommonParamsWithGeckoResourceURL:(BOOL)bdw_addCommonParamsWithGeckoResourceURL
{
    objc_setAssociatedObject(self,
                             @selector(bdw_addCommonParamsWithGeckoResourceURL),
                             @(bdw_addCommonParamsWithGeckoResourceURL),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface WKWebView (BDResouceLoaderPlugin)

@end

@implementation WKWebView (BDResouceLoaderPlugin)

- (BDResouceLoaderPluginTaskBuilder)bdwrl_taskBuilder
{
    return objc_getAssociatedObject(self, @selector(bdwrl_taskBuilder));
}

- (void)setBdwrl_taskBuilder:(BDResouceLoaderPluginTaskBuilder)bdwrl_taskBuilder
{
    objc_setAssociatedObject(self, @selector(bdwrl_taskBuilder), bdwrl_taskBuilder, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface BDWebCommonParamRequestDecorator : NSObject <BDWebRequestDecorator>

@end

@implementation BDWebCommonParamRequestDecorator

- (NSURLRequest *)bdw_decorateRequest:(NSURLRequest *)request
{
    return request;
}

- (void)bdw_decorateSchemeTask:(id<BDWebURLSchemeTask>)schemeTask
{
    if ([[BDXResourceLoader sharedInstance] isCompliantRemoteUrl:schemeTask.bdw_request.URL]) {
        schemeTask.useTTNetCommonParams = YES;
    }
}

- (void)bdw_decorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask
{
    if ([[BDXResourceLoader sharedInstance] isCompliantRemoteUrl:urlProtocolTask.bdw_request.URL]) {
        urlProtocolTask.useTTNetCommonParams = YES;
    }
}

@end

@interface BDResourceLoaderPluginObject ()

@end

@implementation BDResourceLoaderPluginObject

+ (void)setup
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WKWebView IWK_loadPlugin:[BDResourceLoaderPluginObject new]];
    });
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView
                    didInitWithFrame:(CGRect)rect
                       configuration:(WKWebViewConfiguration *)configuration
{
    if (@available(iOS 12.0, *)) {
        if (configuration.bdw_enableResourceLoaderWithTTNet) {
            Class rlURLProtoclClz = NSClassFromString(@"BDWebResourceLoaderURLProtocol");
            NSCAssert(rlURLProtoclClz != nil,
                      @"could not find BDWebResourceLoaderURLProtocol, make sure you depend BDWebKit/ResourceLoader/TTNet");
            
            if (rlURLProtoclClz) {
                [webView bdw_registerURLProtocolClass:rlURLProtoclClz];
            }
        }
    }
    
    if (configuration.bdw_enableResourceLoaderWithFalcon) {
        Class rlInterceporClz = NSClassFromString(@"BDFalconResourceLoaderInterceptor");
        if ([rlInterceporClz respondsToSelector:@selector(setupWithWebView:)]) {
            [rlInterceporClz performSelector:@selector(setupWithWebView:)
                                  withObject:webView];
        } else {
            NSCAssert(NO, @"BDFalconResourceLoaderInterceptor could not setup, make sure you depend BDWebKit/ResourceLoader/Falcon");
        }
    }
    
    if (configuration.bdw_addCommonParamsWithGeckoResourceURL) {
        [[BDWebInterceptor sharedInstance] registerCustomRequestDecorator:[BDWebCommonParamRequestDecorator class]];
    }
    
    return IWKPluginHandleResultContinue;
}

@end
