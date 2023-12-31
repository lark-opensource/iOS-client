//
//  WKWebView+IESBridgeExecutor.m
//  IESWebKit
//
//  Created by li keliang on 2019/10/10.
//

#import "WKWebView+IESBridgeExecutor.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <objc/runtime.h>


@implementation WKWebView (IESBridgeExecutor)
- (NSURL *)ies_commitURL {
    NSURL* commitUrl = objc_getAssociatedObject(self, _cmd);
    if (!commitUrl) {
        return self.ies_url;
    }
    
    return commitUrl;
}

- (void)set_iesCommitURL:(NSURL*)url {
    objc_setAssociatedObject(self, @selector(ies_commitURL), url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)ies_url
{
    return self.URL;
}

- (void)ies_executeJavaScript:(NSString *)javaScriptString completion:(IESBridgeExecutorCompletion)completion
{
    btd_dispatch_async_on_main_queue(^{
        [self evaluateJavaScript:javaScriptString completionHandler:completion];
    });
}

- (IESBridgeEngine *)ies_bridgeEngine
{
    IESBridgeEngine *engine = objc_getAssociatedObject(self, _cmd);
    if (!engine) {
        engine = [[IESBridgeEngine alloc] initWithExecutor:self];
        objc_setAssociatedObject(self, _cmd, engine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return engine;
}

@end
