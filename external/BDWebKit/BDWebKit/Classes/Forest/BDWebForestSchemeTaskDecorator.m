#import <IESForestKit/IESForestKit.h>
#import <IESForestKit/IESForestRequest.h>
#import "BDWebForestSchemeTaskDecorator.h"
#import "BDWebForestPluginObject.h"
#import "BDWebForestUtil.h"

@implementation BDWebForestSchemeTaskDecorator

- (NSURLRequest *)bdw_decorateRequest:(NSURLRequest *)request
{
    // add common params for Gecko CDN multiversion url
    if ([IESForestKit isCDNMultiVersionResource:request.URL.absoluteString]) {
        NSDictionary *commonParams = [IESForestKit cdnMultiVersionCommonParameters];
        NSURL *newURL = [BDWebForestUtil urlWithURLString:request.URL.absoluteString queryParameters:commonParams];
        return [NSURLRequest requestWithURL:newURL];
    }

    return request;
}

- (void)bdw_decorateSchemeTask:(id<BDWebURLSchemeTask>)schemeTask
{
    // only decorate when ForestInterceptor enabled
    if (!schemeTask.bdw_webView.bdw_enableForestInterceptorForTTNetSchemeHandler) {
        return;
    }

    NSString* urlString = schemeTask.bdw_request.URL.absoluteString;
    IESForestRequest *request = [[IESForestKit sharedInstance] createRequestWithURLString:urlString parameters:nil];
    if (!request.disableCDNCache) {
        schemeTask.taskHttpCachePolicy = BDWebHTTPCachePolicyEnableCache;
    }
}

@end
