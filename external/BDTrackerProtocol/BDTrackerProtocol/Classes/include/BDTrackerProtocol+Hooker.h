//
//  BDTrackerProtocol+Hooker.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/12/16.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDTrackerProtocolHooker <NSObject>

@optional
- (void)onEventV3:(NSString *)event
        parameter:(nullable NSDictionary *)parameter;
- (void)onCustomEventKey:(NSString *)key
               parameter:(nullable NSDictionary *)parameter;

/// this will only call on inhouse package
- (void)onEvent:(NSDictionary *)event withKey:(NSString *)key;

@end

@interface BDTrackerProtocol (Hooker)

+ (void)addHooker:(id<BDTrackerProtocolHooker>)hooker forKey:(NSString *)key;
+ (void)removeHookerForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
