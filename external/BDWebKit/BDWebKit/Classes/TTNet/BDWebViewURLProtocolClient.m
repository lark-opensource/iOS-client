//
//  BDWebViewURLProtocolClient.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import "BDWebViewURLProtocolClient.h"
#import "WKWebView+BDPrivate.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "WKWebView+TTNet.h"
#import "BDWebKitUtil.h"

#define dispatch_main($block) ([NSThread isMainThread] ? $block() : dispatch_sync(dispatch_get_main_queue(), $block))

API_AVAILABLE(ios(11.0))
@interface BDWebViewURLProtocolClient ()
@property (nonatomic, weak) id<BDWebURLSchemeTask> schemeTask;
@property (nonatomic, weak) WKWebView *webView;
@end

@implementation BDWebViewURLProtocolClient

- (instancetype)initWithWebView:(WKWebView *)webView schemeTask:(id<BDWebURLSchemeTask>)schemeTask {
    self = [super init];
    if (self) {
        self.webView = webView;
        self.schemeTask = schemeTask;
    }
    return self;
}

#pragma mark - NSURLProtocolClient
- (void)URLProtocol:(NSURLProtocol *)protocol wasRedirectedToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if (_isStopped || ![self.webView bd_isPageValid]) {
        return;
    }
    
//    [self.schemeTask didReceiveResponse:redirectResponse];
}

- (void)URLProtocol:(NSURLProtocol *)protocol cachedResponseIsValid:(NSCachedURLResponse *)cachedResponse {
    
}

- (void)URLProtocol:(NSURLProtocol *)protocol didReceiveResponse:(NSHTTPURLResponse *)response cacheStoragePolicy:(NSURLCacheStoragePolicy)policy {
    dispatch_main(^(){
        if (self.isStopped || ![self.webView bd_isPageValid]) {
            return;
        }
        NSMutableDictionary *headers = [response.allHeaderFields mutableCopy];
        if (headers[@"Content-Type"] == nil) {
            NSString *extension = [response.URL.absoluteString pathExtension];
            NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension] ?: @"text/html";
            headers[@"Content-Type"] = contentType;
        }
        NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:response.statusCode HTTPVersion:@"HTTP/1.1" headerFields:headers];
        @try {
            [self.schemeTask bdw_didReceiveResponse:httpResponse];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didReceiveResponse:)]) {
               [self.webView.bdw_networkDelegate webView:self.webView didReceiveResponse:httpResponse];
            }
        } @catch (NSException *exception) {
            NSString *exceptionStr = exception.description?exception.description:@"";
            [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
        }
    });
}

- (void)URLProtocol:(NSURLProtocol *)protocol didLoadData:(NSData *)data {
    dispatch_main(^(){
        if (self.isStopped || ![self.webView bd_isPageValid]) {
            return;
        }
        @try {
            [self.schemeTask bdw_didLoadData:data];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didReceiveData:forURL:)]) {
               [self.webView.bdw_networkDelegate webView:self.webView didReceiveData:data forURL:self.schemeTask.bdw_request.URL];
            }
        } @catch (NSException *exception) {
            NSString *exceptionStr = exception.description?exception.description:@"";
            [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
        }
    });
}

- (void)URLProtocolDidFinishLoading:(NSURLProtocol *)protocol {
    dispatch_main(^(){
        if (self.isStopped || ![self.webView bd_isPageValid]) {
            return;
        }
        @try {
            [self.schemeTask bdw_didFinishLoading];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didFinishLoadURL:)]) {
               [self.webView.bdw_networkDelegate webView:self.webView didFinishLoadURL:self.schemeTask.bdw_request.URL];
            }
        } @catch (NSException *exception) {
            NSString *exceptionStr = exception.description?exception.description:@"";
            [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
        }
    });
}

- (void)URLProtocol:(NSURLProtocol *)protocol didFailWithError:(NSError *)error {
    dispatch_main(^(){
        if (self.isStopped || ![self.webView bd_isPageValid]) {
            return;
        }
        @try {
            [self.schemeTask bdw_didFailWithError:error];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didFailLoadURL:withError:)]) {
               [self.webView.bdw_networkDelegate webView:self.webView
                                          didFailLoadURL:self.schemeTask.bdw_request.URL
                                               withError:error];
            }
        } @catch (NSException *exception) {
            NSString *exceptionStr = exception.description?exception.description:@"";
            [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
        }
    });
    //    self.urlProtocol = nil;
}

- (void)URLProtocol:(NSURLProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)URLProtocol:(NSURLProtocol *)protocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

@end
