//
//  BDXGurdService.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXGurdService.h"
#import "BDXGurdConfigDelegate.h"
#import "BDXGurdConfigImpl.h"
#import "BDXGurdNetDelegateImpl.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/BTDMacros.h>
#import <IESGeckoKit/IESGeckoKit.h>

@implementation BDXGurdService

+ (NSString *)accessKey
{
    return [self.configDelegate accessKey];
}

+ (void)registerAccessKey:(NSString *)accessKey
{
    self.configDelegate = nil;
    [self setupIfNeeded];
    [IESGurdKit registerAccessKey:accessKey];
    if (!self.configDelegate) {
        BDXGurdConfigImpl *configDelegate = [[BDXGurdConfigImpl alloc] init];
        configDelegate.accessKeyName = accessKey;
        [self setConfigDelegate:configDelegate];
    }
}

+ (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey
{
    return [IESGurdKit rootDirForAccessKey:accessKey];
}

+ (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel;
{
    return [IESGurdKit rootDirForAccessKey:accessKey channel:channel];
}

+ (IESGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdKit fileTypeForAccessKey:accessKey channel:channel];
}

+ (uint64_t)packageVersionForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdKit packageVersionForAccessKey:accessKey channel:channel];
}

+ (void)clearCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdKit clearCacheForAccessKey:accessKey channel:channel];
}

+ (void)syncResourcesWithTask:(BDXGurdSyncTask *)task completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    [IESGurdKit
        syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams *_Nonnull params) {
            params.accessKey = task.accessKey;
            params.channels = task.channelsArray;
            params.groupName = task.groupName;
            params.businessDomain = [self.configDelegate isBusinessDomainEnabled] ? task.businessDomain : nil;
            params.resourceVersion = task.resourceVersion;
            params.disableThrottle = task.disableThrottle;
            params.forceRequest = (task.options & BDXGurdSyncResourcesOptionsForceRequest);
            params.pollingPriority = (IESGurdPollingPriority)task.pollingPriority;
            params.downloadPriority = (IESGurdDownloadPriority)task.downloadPriority;
        }
                          completion:completion];
}

+ (BOOL)hasCacheForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdKit hasCacheForPath:path accessKey:accessKey channel:channel];
}

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdKit dataForPath:path accessKey:accessKey channel:channel];
}

+ (BOOL)isRequestThrottledWithStatusDictionary:(NSDictionary *)statusDictionary
{
    return (IESGurdStatusForBusiness(statusDictionary) == IESGurdSyncStatusRequestThrottle);
}

#pragma mark - Private

+ (void)setupIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [IESGurdKit setGetDeviceID:^NSString *_Nonnull {
            return [BDTrackerProtocol deviceID];
        }];

        if ([self.configDelegate isNetworkDelegateEnabled]) {
            [IESGurdKit setNetworkDelegate:[[BDXGurdNetDelegateImpl alloc] init]];
        }

        NSString *platformDomain = [self.configDelegate platformDomain];
        if (platformDomain) {
            [IESGurdKit setPlatformDomain:platformDomain];
        }
    });
}

#pragma mark - Accessor

static id<BDXGurdConfigDelegate> kConfigDelegate = nil;
+ (id<BDXGurdConfigDelegate>)configDelegate
{
    return kConfigDelegate;
}

+ (void)setConfigDelegate:(id<BDXGurdConfigDelegate>)configDelegate
{
    kConfigDelegate = configDelegate;
}

@end
