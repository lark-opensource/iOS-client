//
//  HTSAppContext.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSBootAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class HTSAppContext;
@class HTSOpenURLContext;
@class HTSNotificationContext;
@class HTSUserActivityContext;
@class HTSBackgroundFetchContext;
@class HTSShortcutContext;
@class HTSBgURLSessionContext;
@class HTSHandleNotificationContext;

FOUNDATION_EXPORT HTSAppContext * HTSCurrentContext(void);

@interface HTSAppContext : NSObject

@property (readonly) NSDictionary * launchOptions;
@property (readonly) UIApplication * application;
@property (readonly) BOOL backgroundLaunch;
@property (readonly) HTSBootAppDelegate * appDelegate;
@property (readonly) HTSOpenURLContext * openURLContext;
@property (readonly) HTSNotificationContext * notificationContext;
@property (readonly) HTSUserActivityContext * userActivityContext;
@property (readonly) HTSBackgroundFetchContext * backgroundFetchContext;
@property (readonly) HTSShortcutContext * shortcutContext API_AVAILABLE(ios(9.0));
@property (readonly) HTSBgURLSessionContext * bgURLSessionContext;
@property (readonly) HTSHandleNotificationContext * handleNotificationContext;
/// ios 15 以后是否系统后台冷启动
@property (readonly) BOOL isSystemBackgroundLaunch;

@end

@interface HTSOpenURLContext : NSObject

@property (readonly) NSURL *openURL;
@property (readonly) NSDictionary *options API_AVAILABLE(ios(9.0));
@property (readonly) NSString *sourceApplication;
@property (readonly) id annotation;

@end

typedef void (^HTSBackgroundFetchResultHandler)(UIBackgroundFetchResult);

@interface HTSNotificationContext : NSObject

@property (readonly) NSError *registerError;
@property (readonly) NSData *deviceToken;
@property (readonly) NSDictionary *remoteUserInfo;
@property (readonly) HTSBackgroundFetchResultHandler notificationResultHander;
@property (readonly) UILocalNotification *localNotification API_DEPRECATED("Use UserNotifications Framework", ios(4.0, 10.0));
@property (readonly) UIUserNotificationSettings *settings API_DEPRECATED("Use UserNotifications Framework", ios(8.0, 10.0));

@end

typedef void(^HTSUserActivityRestoreHandler)(NSArray<id <UIUserActivityRestoring>> *);
@interface HTSUserActivityContext : NSObject

@property (readonly) NSString *activityType;
@property (readonly) NSUserActivity *userActivity;
@property (readonly) NSError *userActivityError;
@property (readonly) HTSUserActivityRestoreHandler restoreHandler;

@end

typedef void (^HTSShortcutCompletionHandler)(BOOL);
API_AVAILABLE(ios(9.0))
@interface HTSShortcutContext : NSObject 

@property (readonly) UIApplicationShortcutItem *item;
@property (readonly) HTSShortcutCompletionHandler completionHandler;

@end

@interface HTSBackgroundFetchContext : NSObject

@property (readonly) HTSBackgroundFetchResultHandler bgFetchResultHandler;

@end

@interface HTSBgURLSessionContext : NSObject

@property (readonly) NSString * identifier;
@property (readonly) void (^completionHandler)(void);

@end

@interface HTSHandleNotificationContext : NSObject

@property (copy, nonatomic, readonly) NSDictionary *userInfo;
@property (copy, nonatomic, readonly) NSString *categoryIdentifier;
@property (copy, nonatomic, readonly) NSString *actionIdentifier;
@property (copy, nonatomic, readonly) NSString *userText;
@property (copy, nonatomic, readonly) NSString *identifier;
@property (assign, nonatomic, readonly) BOOL isColdLaunch;

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo
              categoryIdentifier:(NSString *)categoryIdentifier
                actionIdentifier:(NSString *)actionIdentifier
                        userText:(NSString *)userText
                      identifier:(NSString *)identifier
                    isColdLaunch:(BOOL)isColdLaunch;

@end

NS_ASSUME_NONNULL_END
