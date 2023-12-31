//
//  IESGurdClearCacheManager+Remote.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import "IESGurdClearCacheManager.h"

#import "IESGurdConfigUniversalStrategies.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString *, IESGurdConfigUniversalStrategies *> IESGurdClearCacheStrategies;

@interface IESGurdClearCacheManager (Remote)

+ (void)clearCacheWithUniversalStrategies:(IESGurdClearCacheStrategies *)universalStrategies
                                  logInfo:(NSDictionary * _Nullable)logInfo;

@end

NS_ASSUME_NONNULL_END
