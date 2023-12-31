//
//  BDPreloadMonitor.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/22.
//

#import <Foundation/Foundation.h>
#import "NSOperation+BDPreloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPreloadMonitor : NSObject

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene;

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene error:(nullable NSError *)error;

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene trafficSize:(long long)trafficSize extra:(nullable NSDictionary *)extra;

+ (void)trackPreloadWithKey:(NSString *)key scene:(NSString *)scene trafficSize:(long long)trafficSize error:(nullable NSError *)error extra:(nullable NSDictionary *)extra;

+ (void)push:(NSOperation *)task;

+ (void)pop:(NSString *)preloadKey;

+ (void)popAll;

@end

NS_ASSUME_NONNULL_END
