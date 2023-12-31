//
//  HMDInjectedInfo+UniqueKey.h
//  AFgzipRequestSerializer
//
//  Created by fengyadong on 2019/7/1.
//

#import "HMDInjectedInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInjectedInfo (UniqueKey)

- (void)confUniqueKeyForData:(NSMutableDictionary *)data
                   timestamp:(long long)timestamp
                   eventType:(NSString *)eventType;

- (void)confUniqueKeyForData:(NSMutableDictionary *)data
                   timestamp:(long long)timestamp
                   eventType:(NSString *)eventType
                       appID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
