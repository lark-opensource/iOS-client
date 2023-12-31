//
//  IESGurdPackagesNormalRequest.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Example
//
//  Created by 陈煜钏 on 2021/9/17.
//

#import "IESGurdPackagesNormalRequest.h"
#import "IESGurdKit+Experiment.h"

@implementation IESGurdPackagesNormalRequest

+ (instancetype)requestWithParams:(IESGurdFetchResourcesParams *)params
                       completion:(IESGurdSyncStatusDictionaryBlock)completion
{
    IESGurdPackagesNormalRequest *request = [[self alloc] init];
    request.requestType = IESGurdPackagesConfigRequestTypeNormal;
    request.markIdentifier = YES;
    
    request.lazyDownloadPriority = params.modelActivePolicy == IESGurdPackageModelActivePolicyMatchLazy ? params.downloadPriority : IESGurdDownloadPriorityMedium;
    
    request.modelActivePolicy = params.modelActivePolicy;
    [request updateConfigWithParams:params completion:completion];

    return request;
}

static NSInteger kSyncCount = 1;
- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    params.businessIdentifier = [NSString stringWithFormat:@"sync%zd", kSyncCount];
    kSyncCount++;
    
    [super updateConfigWithParams:params completion:completion];
}

#pragma mark - IESGurdPackageBaseRequestSubclass

- (NSDictionary *)requestMetaDictionary
{
    return @{
        @"req_type" : @(self.requestType),
        @"sync_task_id" : @(self.syncTaskId)
    };
}

- (NSDictionary *)logInfo
{
    return @{ @"req_type" : @(self.requestType),
              @"api_version" : @"update_v6" };
}

@end
