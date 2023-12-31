//
//  IESGurdKit+ExtraParams.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/3/18.
//

#import "IESGurdKit+ExtraParams.h"

@implementation IESGurdKit (ExtraParams)

+ (void)setAppId:(NSString *)appId
{
    NSAssert(NO, @"Use +[IESGurdKit setupWithAppId:appVersion:cacheRootDirectory:] instead");
}

+ (void)registerAccessKey:(NSString *)accessKey channels:(NSArray *)channels
{
    [self registerAccessKey:accessKey];
}

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString * _Nullable)resourceVersion
                        completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    [self syncResourcesWithAccessKey:accessKey
                            channels:channelArray
                     resourceVersion:resourceVersion
                           forceSync:NO
                          completion:completion];
}

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString * _Nullable)resourceVersion
                         forceSync:(BOOL)forceSync
                        completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        params.accessKey = accessKey;
        params.channels = channelArray;
        params.resourceVersion = resourceVersion;
        params.forceRequest = forceSync;
    } completion:completion];
}

@end
