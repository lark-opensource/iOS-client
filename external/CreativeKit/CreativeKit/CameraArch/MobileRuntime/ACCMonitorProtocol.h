//
//  ACCMonitorProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/11.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

typedef NS_OPTIONS(NSUInteger, TTMonitorExtraParamsOption){
    TTMonitorExtraParamsOptionNONE = 0 << 0,
    TTMonitorExtraParamsOptionDNS = 1 << 0
};

@protocol ACCMonitorProtocol <NSObject>

@optional

+ (void)trackService:(nullable NSString *)serviceName attributes:(nullable NSDictionary *)attributes;

+ (void)trackService:(nullable NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;

+ (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue extraParamsOption:(TTMonitorExtraParamsOption)option;

/**
*  Start timing, overwrite existing key if it conflicts with an existing key
*/
+ (void)startTimingForKey:(nonnull id<NSCopying>)key;

/**
 *  End timing and report duration to monitor; YES if successful, NO if no key found
 */
+ (BOOL)endTimingForKey:(nonnull id<NSCopying>)key service:(nullable NSString *)service label:(nullable NSString *)label;

/**
 *  Ends timing, reports duration to monitor, and provides duration information. Returns YES if successful, NO if no key found
 */
+ (BOOL)endTimingForKey:(nonnull id<NSCopying>)key service:(nullable NSString *)service label:(nullable NSString *)label duration:(nullable NSTimeInterval *)duration;

/**
 *  Cancellation of timing
 */
+ (void)cancelTimingForKey:(nonnull id<NSCopying>)key;

+ (void)trackService:(nullable NSString *)serviceName floatValue:(float)value extra:(nullable NSDictionary *)extraValue;

+ (void)trackData:(nullable NSDictionary *)data logTypeStr:(nullable NSString *)logType;

+ (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key;


@end

FOUNDATION_STATIC_INLINE Class<ACCMonitorProtocol> ACCMonitor() {
    id<ACCMonitorProtocol> monitor = [ACCBaseServiceProvider() resolveObject:@protocol(ACCMonitorProtocol)];
    return [monitor class];
}
