//
//  ACCTrackProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/26.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCTrackProtocol <NSObject>

@optional

- (NSString *)deviceID;

- (void)trackEvent:(NSString *)event
             label:(NSString *)label
             value:(nullable NSString *)value
             extra:(nullable NSString *)extra
        attributes:(nullable NSDictionary *)attributes;

- (void)trackEvent:(NSString *)event
            params:(nullable NSDictionary *)params
   needStagingFlag:(BOOL)needStagingFlag;

- (void)track:(NSString *)event params:(NSDictionary *)params;

- (void)trackEvent:(NSString *)event params:(nullable NSDictionary *)params;

- (void)trackEvent:(NSString *)event attributes:(nullable NSDictionary *)attributes;

- (void)trackLogData:(NSDictionary *)dict;

@end

FOUNDATION_STATIC_INLINE id<ACCTrackProtocol> ACCTracker() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCTrackProtocol)];
}

NS_ASSUME_NONNULL_END
