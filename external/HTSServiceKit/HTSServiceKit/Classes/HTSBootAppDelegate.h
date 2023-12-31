//
//  HTSBootAppDelegate.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSEventPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@class HTSHandleNotificationContext;

@interface HTSBootAppDelegate : NSObject<UIApplicationDelegate>

@property (nullable, nonatomic, strong) UIWindow *window;

/// 当前的启动配置，业务方通过继承把配置注入进来
- (NSDictionary *)currentBootConfig;

/// 当前支持的orientation，默认是Portrait
@property (nonatomic, assign) UIInterfaceOrientationMask supportOrientation;

#pragma mark - Plugin

- (id<HTSAppEventPlugin>)appEventPlugin;


- (BOOL)autoMarkLuanchCompletion;

/// whether run only task per runloop, default is no
- (BOOL)runOneBootTaskPerRunloop;

/// whether run launch completion task until feed is ready, default is no
- (BOOL)delayLaunchCompletionTaskUntilFeedReady;

- (void)onAppHandleNotificationWithContext:(HTSHandleNotificationContext *)context;

/// ios 15 以后判断是否是系统后台启动
- (BOOL)isSystemBackgroundLaunch;

@end

NS_ASSUME_NONNULL_END
