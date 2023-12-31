//
//  WKWebView+TTNet.m
//  BDWebKit
//
//  Created by Nami on 2019/11/27.
//

#import <UIKit/UIKit.h>
#import "WKWebView+TTNet.h"
#import "BDTTNetAdapter.h"
#import "NSObject+BDWRuntime.h"
#import "WKWebView+BDPrivate.h"
#import <BDWebCore/WKWebView+Plugins.h>

@implementation WKWebView (TTNet)

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration useTTNet:(BOOL)useTTNet {
    
    if (self = [self initWithFrame:frame configuration:configuration]) {
        if (useTTNet) {
            self.bdw_offlineType = BDWebViewOfflineTypeTaskScheme;
        }
    }
    return self;
}

- (BOOL)bdw_requestByTTNet {
    if (@available(iOS 11.0, *)) {
        id handler = [self.configuration urlSchemeHandlerForURLScheme:@"http"];
        return handler != nil;
    }
    return NO;
}

- (BOOL)bdw_enableFreeFlow {
    return [[self bdw_getAttachedObjectForKey:@"bdw_enableFreeFlow"] boolValue];
}

- (void)setBdw_enableFreeFlow:(BOOL)enableFreeFlow {
    [self bdw_attachObject:@(enableFreeFlow) forKey:@"bdw_enableFreeFlow"];
}

- (id<WKWebViewNetworkDelegate>)bdw_networkDelegate {
    return [self bdw_getAttachedObjectForKey:@"bdw_networkDelegate" isWeak:YES];
}

- (void)setBdw_networkDelegate:(id<WKWebViewNetworkDelegate>)networkDelegate {
    [self bdw_attachObject:networkDelegate forKey:@"bdw_networkDelegate" isWeak:YES];
}

@end
