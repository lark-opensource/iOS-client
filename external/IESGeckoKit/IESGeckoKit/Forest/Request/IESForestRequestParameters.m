// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRequestParameters.h"

@implementation IESForestRequestParameters

- (instancetype)copyWithZone:(NSZone *)zone
{
    IESForestRequestParameters *copy = [[[self class] allocWithZone:zone] init];
    
    copy.disableGecko = [_disableGecko copy];
    copy.disableBuiltin = [_disableBuiltin copy];
    copy.disableCDN = [_disableCDN copy];
    copy.disableCDNCache = [_disableCDNCache copy];

    copy.accessKey = [_accessKey copy];
    copy.channel = [_channel copy];
    copy.bundle = [_bundle copy];
    copy.resourceVersion = [_resourceVersion copy];

    copy.waitGeckoUpdate = [_waitGeckoUpdate copy];
    copy.onlyLocal = [_onlyLocal copy];

    copy.fetcherSequence = [_fetcherSequence copy];
    copy.cdnRetryTimes = _cdnRetryTimes;

    copy.onlyPath = [_onlyPath copy];
    copy.enableMemoryCache = [_enableMemoryCache copy];
    copy.memoryExpiredTime = [_memoryExpiredTime copy];
    
    copy.sessionId = [_sessionId copy];
    copy.isPreload = _isPreload;
    copy.enableRequestReuse = _enableRequestReuse;
    copy.completionQueue = _completionQueue;

    copy.resourceScene = _resourceScene;
    copy.groupId = [_groupId copy];
    copy.customParameters = [_customParameters copy];
    copy.skipMonitor = _skipMonitor;
    
    copy.runWorkflowInGlobalQueue = [_runWorkflowInGlobalQueue copy];

    return copy;
}

@end
