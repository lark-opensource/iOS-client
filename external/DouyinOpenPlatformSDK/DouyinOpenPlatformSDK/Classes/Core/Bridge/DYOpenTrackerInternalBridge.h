//
//  DYOpenTrackerInternalBridge.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define DYOPEN_TRACK_EVENT(__EVENT_STRING__, __PARAMS_DICT__) \
if ([(id<DYOpenTrackerInternalBridge>)self respondsToSelector:@selector(internal_dyopenTrackEvent:params:)]) {\
    [(id<DYOpenTrackerInternalBridge>)self internal_dyopenTrackEvent:__EVENT_STRING__ params:__PARAMS_DICT__];\
}

#define DYOPEN_TRACK_API_EVENT(__IS_SUPPORT_BOOL__) \
DYOPEN_TRACK_EVENT(@"dysdk_api_invoke", (@{\
    @"api_name": [NSString stringWithFormat:@"%s", __FUNCTION__] ?: @"",\
    @"is_support": @(__IS_SUPPORT_BOOL__).stringValue,\
}));

#define DYOPEN_TRACK_COMMON_PARAMS (([(id<DYOpenTrackerInternalBridge>)self respondsToSelector:@selector(internal_dyopenCommonTrackParams)]) ? [(id<DYOpenTrackerInternalBridge>)self internal_dyopenCommonTrackParams] : nil)

@protocol DYOpenTrackerInternalBridge <NSObject>

@optional
/// Track
- (void)internal_dyopenTrackEvent:(NSString *_Nonnull)eventName params:(NSDictionary *_Nullable)params;
+ (void)internal_dyopenTrackEvent:(NSString *_Nonnull)eventName params:(NSDictionary *_Nullable)params;

/// 通参
+ (NSDictionary *_Nullable)internal_dyopenCommonTrackParams;

@end

NS_ASSUME_NONNULL_END
