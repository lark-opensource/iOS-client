//
//  UIApplication+HMDUtility.h
//  Pods
//
//  Created by bytedance on 2020/5/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (HMDUtility)

+ (BOOL)hmd_isAppExtension;
+ (UIApplication * _Nullable)hmdSharedApplication;
+ (NSString * _Nullable)hmd_appExtensionPointIdentifier;

@end

NS_ASSUME_NONNULL_END
