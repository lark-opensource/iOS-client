//
//  IESGurdResourceManager+Business.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/26.
//

#import "IESGeckoResourceManager.h"

#import "IESGurdPackagesConfigResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESGurdPackagesConfigCompletion)(IESGurdSyncStatus status, IESGurdPackagesConfigResponse * _Nullable response);

@interface IESGurdResourceManager (Business)

+ (void)requestConfigWithURLString:(NSString *)URLString
                            params:(NSDictionary *)params
                           logInfo:(NSDictionary *)logInfo
                        completion:(IESGurdPackagesConfigCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
