// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestGeckoUtil.h"
#import <ByteDanceKit/BTDMacros.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdLogProxy.h>

@implementation IESForestGeckoUtil

+ (void)syncChannel:(NSString *)channel accessKey:(NSString *)accessKey
{
    if (BTD_isEmptyString(accessKey) || BTD_isEmptyString(channel)) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams *_Nonnull params) {
            params.accessKey = accessKey;
            params.channels = @[channel];
            params.disableThrottle = NO;
            params.forceRequest = YES;
            params.requestWhenHasLocalVersion = NO;
         } completion:nil];
    });
}

@end
