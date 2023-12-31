//
//  BDWebViewOfflineStatusLogicControl.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/28.
//

#import "BDWebViewOfflineStatusLogicControl.h"
#import <ByteDanceKit/BTDWeakProxy.h>

@implementation BDWebViewOfflineStatusLogicControl

static NSMutableArray *g_arrWebView;

+ (void)addWebViewWhenCreate:(WKWebView *)createdWebView {
    if (!createdWebView) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_arrWebView = [NSMutableArray array];
    });
    
    
    for (BTDWeakProxy *proxy in g_arrWebView) {
        if (proxy.target == createdWebView) {
            return;
        }
    }
    
    BTDWeakProxy *proxy = [BTDWeakProxy proxyWithTarget:createdWebView];
    [g_arrWebView addObject:proxy];
}

+ (WKWebView *)lastVisibleWebViewWhenDestroy:(WKWebView *)destroyWebView {
    WKWebView *lastVisibleWebView = nil;
    
    NSArray *reverseList = g_arrWebView.reverseObjectEnumerator.allObjects;
    NSMutableArray *removeList = [NSMutableArray array];
    for (BTDWeakProxy *proxy in reverseList) {
        WKWebView *webview = proxy.target;
        if (!webview || destroyWebView == webview) {
            [removeList addObject:proxy];
            continue;
        }
        
        if (webview.window && webview.superview) {
            lastVisibleWebView = webview;
            break;
        }
    }
    
    [g_arrWebView removeObjectsInArray:removeList];
    
    return lastVisibleWebView;
}

@end
