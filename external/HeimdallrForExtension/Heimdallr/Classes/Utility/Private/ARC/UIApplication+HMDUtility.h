//
//  UIApplication+HMDUtility.h
//  Pods
//
//  Created by bytedance on 2020/5/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (HMDUtility)

+ (BOOL)isAppExtension;
+ (UIApplication *)hmdSharedApplication;
+ (NSString *)appExtensionPointIdentifier;

@end

NS_ASSUME_NONNULL_END
