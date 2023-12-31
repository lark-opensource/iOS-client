//
//  ACCNetworkReachabilityProtocol.h
//  CameraClient
//
//  Created by zhangyuanming on 2020/9/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCNetworkReachabilityStatus) {
    ACCNetworkReachabilityStatusUnknown          = -1,
    ACCNetworkReachabilityStatusNotReachable     = 0,
    ACCNetworkReachabilityStatusReachableViaWWAN = 1,
    ACCNetworkReachabilityStatusReachableViaWiFi = 2,
};

@protocol ACCNetworkReachabilityProtocol <NSObject>

@property (nonatomic, assign, getter = isReachable, readonly) BOOL reachable;
@property (nonatomic, assign, readonly) ACCNetworkReachabilityStatus status;

- (void)addNotificationObserver:(id)observer selector:(SEL)aSelector object:(nullable id)anObject;
- (void)removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
