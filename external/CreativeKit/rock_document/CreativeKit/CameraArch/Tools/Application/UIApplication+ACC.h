//
//  UIApplication+ACC.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (ACC)

+ (UIEdgeInsets)acc_safeAreaInsets;

+ (void)setACCHostDefaultSceneName:(NSString *)sceneName;
+ (UIWindow *)acc_currentWindow;

@end

NS_ASSUME_NONNULL_END
