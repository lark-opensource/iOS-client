//
//  IESGurdResourceManager+MultiAccessKey.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/11/10.
//

#import "IESGeckoResourceManager.h"

#import "IESGurdMultiAccessKeysRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdResourceModel;

@interface IESGurdResourceManager (MultiAccessKey)

+ (void)fetchConfigWithURLString:(NSString *)URLString
          multiAccessKeysRequest:(IESGurdMultiAccessKeysRequest *)request;

+ (void)downloadLazyResources:(NSArray<IESGurdResourceModel *> *)packagesArray
                   completion:(IESGurdSyncStatusDictionaryBlock)completion;

@end

NS_ASSUME_NONNULL_END
