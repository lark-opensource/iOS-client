//
//  IESGurdPackagesNormalRequest.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Example
//
//  Created by 陈煜钏 on 2021/9/17.
//

#import "IESGurdMultiAccessKeysRequest.h"

#import "IESGurdFetchResourcesParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPackagesNormalRequest : IESGurdMultiAccessKeysRequest

+ (instancetype)requestWithParams:(IESGurdFetchResourcesParams *)params
                       completion:(IESGurdSyncStatusDictionaryBlock)completion;

@end

NS_ASSUME_NONNULL_END
