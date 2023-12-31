//
//  IESGurdAutoRequest.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/23.
//

#import "IESGurdAutoRequest.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines+Private.h"

@implementation IESGurdAutoRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestType = IESGurdPackagesConfigRequestTypeQueue;
        self.markIdentifier = YES;
        self.modelActivePolicy = IESGurdPackageModelActivePolicyFilterLazy;
    }
    return self;
}

static NSInteger kSyncCount = 1;
- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    params.businessIdentifier = [NSString stringWithFormat:@"sync%zd", kSyncCount];
    kSyncCount++;
    
    [super updateConfigWithParams:params completion:completion];
}

#pragma mark - Public

- (void)updateConfigWithParamsInfosArray:(NSArray<IESGurdSettingsRequestParamsInfo *> *)paramsInfosArray
{
    [paramsInfosArray enumerateObjectsUsingBlock:^(IESGurdSettingsRequestParamsInfo *paramsInfo, NSUInteger idx, BOOL *stop) {
        NSString *accessKey = paramsInfo.accessKey;
        
        [paramsInfo.groupNamesArray enumerateObjectsUsingBlock:^(NSString *groupName, NSUInteger idx, BOOL *stop) {
            IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
            params.accessKey = accessKey;
            params.groupName = groupName;
            [self updateConfigWithParams:params completion:nil];
        }];
        
        IESGurdFetchResourcesParams *params = [[IESGurdFetchResourcesParams alloc] init];
        params.accessKey = accessKey;
        params.channels = paramsInfo.channelsArray;
        [self updateConfigWithParams:params completion:nil];
    }];
}

#pragma mark - IESGurdPackageBaseRequestSubclass

- (NSDictionary *)requestMetaDictionary
{
    return @{ @"req_type" : @(self.requestType),
              kIESGurdRequestColdLaunchKey : @(1) };
}

- (NSDictionary *)logInfo
{
    return @{ @"req_type" : @(self.requestType),
              @"api_version" : @"update_v6",
    };
}

@end
