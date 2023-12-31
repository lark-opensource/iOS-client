//
//  IESPrefetchDefines.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/8/1.
//

#import <Foundation/Foundation.h>

// Monitor Key
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorErrorCodeKey;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorErrorMsgKey;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorStatusKey;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorCacheStatusKey;

FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorConfigService;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorFetchService;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorTriggerService;
FOUNDATION_EXPORT NSString * const kIESPrefetchMonitorAPIService;

// error code
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorCapabilityNotImplemented;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorLoaderDisabled;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorJSONSerializationFailed;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorJSONEmptyOrInvalid;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorConfigProjectMissing;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorConfigVersionNotSupported;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorSchemaResolveFailed;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorRuleMatchFailed;
FOUNDATION_EXPORT NSInteger const kIESPrefetchErrorFetchDataWithoutCompletion;

FOUNDATION_EXPORT NSErrorDomain const kIESPrefetchLoaderErrorDomain;

typedef NSString *IESPrefetchOccasion NS_EXTENSIBLE_STRING_ENUM;

typedef NS_ENUM(NSUInteger, IESPrefetchCache) {
    IESPrefetchCacheNone = 0,
    IESPrefetchCachePending = 1,
    IESPrefetchCacheHit = 2,
    IESPrefetchCacheDisabled = 3,
};

FOUNDATION_EXPORT IESPrefetchOccasion const IESPrefetchOccasionLoadUrl;
FOUNDATION_EXPORT IESPrefetchOccasion const IESPrefetchOccasionLaunchApp;
