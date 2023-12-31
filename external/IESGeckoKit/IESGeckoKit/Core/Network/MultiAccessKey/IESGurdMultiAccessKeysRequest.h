//
//  IESGurdMultiAccessKeysRequest.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/11/10.
//

#import "IESGurdPackageBaseRequest.h"

#import "IESGurdFetchResourcesParams+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdMultiAccessKeysRequest : IESGurdPackageBaseRequest

@property (nonatomic, assign) IESGurdPackagesConfigRequestType requestType;

@property (nonatomic, assign) int syncTaskId;

@property (nonatomic, assign) BOOL markIdentifier; // 标记资源 identifier

@property (nonatomic, assign) IESGurdDownloadPriority lazyDownloadPriority;

- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params;

- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params
                    completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;

- (NSDictionary *)paramsForRequest;

- (NSDictionary<NSString *, NSArray<NSString *> *> *)targetChannelsMap;

- (NSDictionary<NSString *, NSArray<NSString *> *> *)targetGroupsMap;

- (NSDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *)requestCompletions;

- (NSDictionary<NSString *, NSNumber *> *)downloadPrioritiesMap;

- (BOOL)isParamsValid;

@end

@interface IESGurdMultiAccessKeysRequest (DebugInfo)

- (NSString *)paramsString;

@end

NS_ASSUME_NONNULL_END
