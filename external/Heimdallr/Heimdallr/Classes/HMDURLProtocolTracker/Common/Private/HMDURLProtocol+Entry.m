//
//  HMDURLProtocol+Entry.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/4/25.
//

#import "HMDURLProtocol+Entry.h"
#import "NSURLSessionConfiguration+HMDURLProtocol.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDURLCacheManager+Private.h"
#import "NSURLRequest+HMDURLProtocol.h"

@implementation HMDURLProtocol (Entry)

+ (void)start
{
    [NSURLSessionConfiguration hmd_start];
    [NSURLProtocol registerClass:HMDURLProtocol.class];
    [HMDURLProtocol changeCustomURLCaceheState:((HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].config)];
    [NSMutableURLRequest hmd_setupDataTempFolderPath];
}

+ (void)stop
{
    [NSURLSessionConfiguration hmd_stop];
    [NSURLProtocol unregisterClass:HMDURLProtocol.class];
    [[HMDURLCacheManager sharedInstance] stop];
}

+ (void)updateHMDURLProtocolConfig:(HMDHTTPTrackerConfig *)config {
    [HMDURLProtocol changeCustomURLCaceheState:config];
}

+ (void)changeCustomURLCaceheState:(HMDHTTPTrackerConfig *)config {
    if ([config isKindOfClass:[HMDHTTPTrackerConfig class]]) {
        BOOL isAllowOn = config.enableCustomURLCache;
        if (isAllowOn) {
            [[HMDURLCacheManager sharedInstance] start];
        } else {
            [[HMDURLCacheManager sharedInstance] stop];
        }
    }
}

@end
