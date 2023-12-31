//
//  UIApplication+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

@interface UIApplication (BTDAdditions)

/**
 @return 返回总的磁盘空间大小
 */
+ (nonnull NSNumber *)btd_totalDiskSpace;

/**
 @return 返回可用的磁盘空间大小
 */
+ (nonnull NSNumber *)btd_freeDiskSpace;

/**
 @return 返回当前线程内存的使用大小
 */
+ (int64_t)btd_memoryUsage;

/**

 @return 返回当前线程cpu使用率,如果有错误，返回-1
 */
+ (float)btd_cpuUsage;
/**
 app基本信息
 */
+ (nonnull NSString *)btd_appDisplayName;
+ (nonnull NSString *)btd_platformName;
+ (nonnull NSString *)btd_versionName;
+ (nonnull NSString*)btd_bundleVersion;
+ (nonnull NSString *)btd_appName;
+ (nonnull NSString *)btd_appID;
+ (nonnull NSString *)btd_bundleIdentifier;
+ (nonnull NSString *)btd_currentChannel;


/**
 获取当前应用的广义mainWindow

 @return uiwindow
 */
+ (nullable UIWindow *)btd_mainWindow;

@end
