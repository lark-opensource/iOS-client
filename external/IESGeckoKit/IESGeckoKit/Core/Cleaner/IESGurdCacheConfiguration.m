//
//  IESGurdCacheConfiguration.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#import "IESGurdCacheConfiguration.h"

@implementation IESGurdCacheConfiguration

@end

@implementation IESGurdCacheConfiguration (Conveniences)

+ (instancetype)FIFOConfiguration
{
    IESGurdCacheConfiguration *configuration = [[self alloc] init];
    configuration.cachePolicy = IESGurdCleanCachePolicyFIFO;
    configuration.channelLimitCount = 10;
    return configuration;
}

+ (instancetype)LRUConfiguration
{
    IESGurdCacheConfiguration *configuration = [[self alloc] init];
    configuration.cachePolicy = IESGurdCleanCachePolicyLRU;
    configuration.channelLimitCount = 10;
    return configuration;
}

@end
