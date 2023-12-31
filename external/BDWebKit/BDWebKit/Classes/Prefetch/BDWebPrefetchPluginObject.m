//
//  BDWebPrefetchPluginObject.m
//  BDWebKit
//
//  Created by li keliang on 2020/5/12.
//

#import "BDWebPrefetchPluginObject.h"
#import <IESPrefetch/IESPrefetchJSNetworkRequestModel.h>
#import <BDWebCore/WKWebView+Plugins.h>
#import "IESPrefetchManager+Gecko.h"
#import <IESJSBridgeCore/WKWebView+IESBridgeExecutor.h>
#import <objc/runtime.h>

@implementation WKWebView (BDWKPrefetch)

- (NSString *)bdw_prefetchBusiness
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBdw_prefetchBusiness:(NSString *)bdw_prefetchBusiness
{
    objc_setAssociatedObject(self, @selector(bdw_prefetchBusiness), bdw_prefetchBusiness, OBJC_ASSOCIATION_COPY);
}

- (BOOL)bdw_disablePrefetch
{
    return [objc_getAssociatedObject(self, @selector(bdw_disablePrefetch)) boolValue];
}

- (void)setBdw_disablePrefetch:(BOOL)bdw_disablePrefetch
{
    objc_setAssociatedObject(self, @selector(bdw_disablePrefetch), @(bdw_disablePrefetch), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation BDWebPrefetchPluginObject

+ (void)enablePrefetch
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WKWebView IWK_loadPlugin:[BDWebPrefetchPluginObject new]];
    });
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    [self p_registerPrefetchBridgeForWebView:webView];
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request
{
    if(webView.bdw_disablePrefetch){
        return IWKPluginHandleResultContinue;
    }
    if (request.URL.absoluteString.length > 0) {
        [[IESPrefetchManager sharedInstance] prefetchDataWithWebUrl:request.URL.absoluteString];
    }
    return IWKPluginHandleResultContinue;
}


- (void)p_registerPrefetchBridgeForWebView:(WKWebView *)webView
{
    if (webView.bdw_prefetchBusiness.length > 0 && ![objc_getAssociatedObject(webView, _cmd) boolValue]) {
        objc_setAssociatedObject(webView, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        __weak WKWebView * weakWebView = webView;
        [webView.ies_bridgeEngine registerHandler:^NSDictionary * _Nullable(NSString * _Nullable callbackId, NSDictionary * _Nullable result, NSString * _Nullable JSSDKVersion, BOOL * _Nullable executeCallback) {
            __strong WKWebView * strongWebView = weakWebView;
            if (!result || ![result isKindOfClass:[NSDictionary class]]) {
                return @{@"code" : @(IESPiperStatusCodeFail)};
            }
            IESPrefetchJSNetworkRequestModel *requestModel = [[IESPrefetchJSNetworkRequestModel alloc] initWithDictionary:result];
            if (!requestModel) {
                return @{@"code" : @(IESPiperStatusCodeFail)};
            }
            
            NSString *business = strongWebView.bdw_prefetchBusiness;
            id<IESPrefetchLoaderProtocol> loader = [[IESPrefetchManager sharedInstance] loaderForBusiness:business];
            if (!loader) {
                return @{@"code" : @(IESPiperStatusCodeFail)};
            }
            [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
                IESPiperStatusCode code = (!error && data) ? IESPiperStatusCodeSucceed : IESPiperStatusCodeFail;
                params[@"cached"] = @(cached);
                params[@"code"] = @(code);
                BOOL isValid = [NSJSONSerialization isValidJSONObject:data];
                params[@"raw"] = isValid ? data : @{};
                [strongWebView.ies_bridgeEngine invokeJSWithCallbackID:callbackId statusCode:code params:params];
            }];
            *executeCallback = NO;
            return nil;
        } forJSMethod:@"__prefetch" authType:IESPiperAuthProtected];
    }
}

@end
