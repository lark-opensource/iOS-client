//
//  BDWebView+BDServerTrust.m
//  ByteWebView
//
//  Created by Nami on 2019/3/6.
//

#import "WKWebView+BDWebServerTrust.h"
#import "NSObject+BDWRuntime.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import "BDWebSSLPlugin.h"

@implementation WKWebView (BDWebServerTrust)

- (BOOL)bdw_enableServerTrustHandler {
    return [[self bdw_getAttachedObjectForKey:@"bdw_enableServerTrustHandler"] boolValue];
}

- (void)setBdw_enableServerTrustHandler:(BOOL)bdw_enableServerTrustHandler {
    [self bdw_attachObject:@(bdw_enableServerTrustHandler) forKey:@"bdw_enableServerTrustHandler"];
    if (bdw_enableServerTrustHandler) {
        [self IWK_loadPlugin:BDWebSSLPlugin.new];
    }
}

- (BOOL)bdw_skipAndPassAllServerTrust {
    return [[self bdw_getAttachedObjectForKey:@"bdw_skipAndPassAllServerTrust"] boolValue];
}

- (void)setBdw_skipAndPassAllServerTrust:(BOOL)bdw_skipAndPassAllServerTrust {
    [self bdw_attachObject:@(bdw_skipAndPassAllServerTrust) forKey:@"bdw_skipAndPassAllServerTrust"];
}

- (BOOL)bdw_enableServerTrustAsync {
    return [[self bdw_getAttachedObjectForKey:@"bdw_enableServerTrustAsync"] boolValue];
}

- (void)setBdw_enableServerTrustAsync:(BOOL)bdw_enableServerTrustAsync {
    [self bdw_attachObject:@(bdw_enableServerTrustAsync) forKey:@"bdw_enableServerTrustAsync"];
}

- (id<BDWebServerTrustDelegate>)bdw_serverTrustDelegate {
    return [self bdw_getAttachedObjectForKey:@"bdw_serverTrustDelegate" isWeak:YES];
}

- (void)setBdw_serverTrustDelegate:(id<BDWebServerTrustDelegate>)bdw_serverTrustDelegate {
    [self bdw_attachObject:bdw_serverTrustDelegate forKey:@"bdw_serverTrustDelegate" isWeak:YES];
}

- (BDWebServerTrustChallengeHandler *)bdw_serverTrustChallengeHandler {
    BDWebServerTrustChallengeHandler *handler = (BDWebServerTrustChallengeHandler *)[self bdw_getAttachedObjectForKey:@"bdw_serverTrustChallengeHandler"];
    if (!handler) {
        handler = [[BDWebServerTrustChallengeHandler alloc] initWithWebView:self];
        [self bdw_attachObject:handler forKey:@"bdw_serverTrustChallengeHandler"];
    }
    return handler;
}

@end
