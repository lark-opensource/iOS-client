//
//  WKWebView+BDOffline.m
//  BDWebKit
//
//  Created by wealong on 2019/12/5.
//

#import "WKWebView+BDOffline.h"
#import <objc/runtime.h>

@implementation WKWebView (BDOffline)

- (void)setBdw_hitPreload:(BOOL)bdw_hitPreload {
    [self bdw_attachObject:@(bdw_hitPreload) forKey:@"BDW_HitPreload"];
}

- (BOOL)bdw_hitPreload {
    return [[self bdw_getAttachedObjectForKey:@"BDW_HitPreload"] boolValue];
}

- (void)setBdw_channelInterceptor:(IESAdSplashChannelInterceptor *)bdw_channelInterceptor {
    [self bdw_attachObject:bdw_channelInterceptor forKey:@"BDW_ChannelInterceptor"];
}

- (IESAdSplashChannelInterceptor *)bdw_channelInterceptor {
    return [self bdw_getAttachedObjectForKey:@"BDW_ChannelInterceptor"];
}

- (void)setChannelInterceptorList:(NSArray<IESFalconCustomInterceptor> *)channelInterceptorList {
    [self bdw_attachObject:channelInterceptorList forKey:@"BDW_ChannelInterceptorList"];
}

- (NSArray<IESFalconCustomInterceptor> *)channelInterceptorList {
    return [self bdw_getAttachedObjectForKey:@"BDW_ChannelInterceptorList"];
}

- (BOOL)didFinishOrFail
{
    return [[self bdw_getAttachedObjectForKey:@"didFinishOrFail"] boolValue];
}


- (void)setDidFinishOrFail:(BOOL)didFinishOrFail
{
    [self bdw_attachObject:@(didFinishOrFail) forKey:@"didFinishOrFail"];
}

@end
