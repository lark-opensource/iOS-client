//
//  TTVideoNetUtils.h
//  Pods
//
//  Created by 江月 on 2019/4/2.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TTVideoEngineNetWorkStatus) {
    TTVideoEngineNetWorkStatusNotReachable  = 0,
    TTVideoEngineNetWorkStatusUnknown       = 1,
    TTVideoEngineNetWorkStatusWWAN          = 10,
    TTVideoEngineNetWorkStatusWiFi          = 20,
};

typedef NS_ENUM(NSUInteger, TTVideoEngineNetWorkWWANStatus) {
    TTVideoEngineNetWorkWWANStatusUnknown = 0,
    TTVideoEngineNetWorkWWANStatus2G = 1,
    TTVideoEngineNetWorkWWANStatus3G = 2,
    TTVideoEngineNetWorkWWANStatus4G = 3,
    TTVideoEngineNetWorkWWANStatus5G = 4,
};

FOUNDATION_EXTERN NSString *kTTVideoEngineNetWorkReachabilityChangedNotification;
FOUNDATION_EXTERN NSString *TTVideoEngineNetWorkReachabilityNotificationState;

@interface TTVideoEngineNetWorkReachability : NSObject

@property (nonatomic, assign, readonly) TTVideoEngineNetWorkWWANStatus currentWWANState;

+ (instancetype)shareInstance;

- (void)startNotifier __attribute__((annotate("oclint:suppress")));

- (void)stopNotifier;

- (TTVideoEngineNetWorkStatus)currentReachabilityStatus;

@end
