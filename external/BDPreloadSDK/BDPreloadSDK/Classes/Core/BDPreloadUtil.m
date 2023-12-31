//
//  BDPreloadUtil.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/22.
//

#import "BDPreloadUtil.h"

#import <TTReachability/TTReachability.h>

@implementation BDPreloadUtil

+ (dispatch_queue_t)preloadTaskQueue {
    static dispatch_queue_t preloadTaskQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preloadTaskQueue = dispatch_queue_create("com.bytdance.preload", DISPATCH_QUEUE_SERIAL);
    });
    return preloadTaskQueue;
}

+ (BOOL)isWifiConnected {
    static TTReachability * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TTReachability reachabilityForInternetConnection];
    });
    
    NetworkStatus netStatus = [instance currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi) {
        return YES;
    }
    
    return NO;
}

+ (void)taskAsyncInPreloadQueue:(dispatch_block_t)block {
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(BDPreloadUtil.preloadTaskQueue)) {
        block();
    } else {
       dispatch_async(BDPreloadUtil.preloadTaskQueue, block);
    }
}

@end
