//
//  HTSAppLifeCycle.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSMacro.h"

#define GET_LIFECYCLE(CLASS_NAME) (CLASS_NAME *)HTSGetAppLifeCycle(CLASS_NAME.class)

/// 获取HTSAppLifeCycle的单例
FOUNDATION_EXPORT id HTSGetAppLifeCycle(Class cls);

NS_ASSUME_NONNULL_BEGIN

/// 在__DATA段里注册
#define HTS_APP_LIFECYCLE(_classname_)\
__attribute((used, section(_HTS_SEGMENT "," _HTS_LIFE_CIRCLE_SECTION )))\
static const char * _HTS_UNIQUE_VAR = #_classname_;


typedef NS_ENUM(NSUInteger, HTSLifeCyclePriority) {
    HTSLifeCyclePriorityRequired    = 1000,
    HTSLifeCyclePriorityHigh        = 750,
    HTSLifeCyclePriorityMedium      = 500,
    HTSLifeCyclePriorityLow         = 250,
    HTSLifeCyclePriorityDefault     = HTSLifeCyclePriorityMedium
};

/// 应用生命周期的监听
@protocol HTSAppLifeCycle <NSObject>

@optional

/// LifeCycle是一个转发层，不应该包括任何的自定义初始化代码
- (instancetype)init NS_UNAVAILABLE;

/// 优先级，越大越先响应，通常不需要配置
+ (NSUInteger)priority;

- (void)onAppWillResignActive;
- (void)onAppDidBecomeActive;
- (void)onAppWillTerminate;
- (void)onAppWillEnterForeground;
- (void)onAppDidEnterBackground;
- (void)onAppDidReceiveMemoryWarning;

- (void)onAppDidRegisterNotificationSetting API_DEPRECATED("Use UserNotifications Framework's -[UNUserNotificationCenter requestAuthorizationWithOptions:completionHandler:]", ios(8.0, 10.0));
- (void)onAppDidRegisterDeviceToken;
- (void)onAppDidFailToRegisterForRemoteNotifications;
- (void)onAppDidReceiveLocalNotification;
- (void)onAppDidReceiveRemoteNotification;
- (void)onAppHandleNotification;

- (void)onAppPerformBackgroundFetch;
- (void)onHandleAppShortcutAction API_AVAILABLE(ios(9.0));
- (void)onHandleEventsForBackgroundURLSession;
/// 处理OpenURL，如果已处理返回YES，否则返回NO，传给下一个
- (BOOL)onHandleAppOpenUrl;
- (BOOL)onHandleAppContinueUserActivity;

@end



NS_ASSUME_NONNULL_END
