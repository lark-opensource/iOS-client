//
//  UIWindow+EMA.h
//  EEMicroAppSDK
//
//  Created by bupozhuang on 2019/1/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (EMA)

+ (CGSize)ema_currentContainerSize:(UIWindow * _Nullable)window;
+ (CGSize)ema_currentWindowSize:(UIWindow * _Nullable)window;

@end

NS_ASSUME_NONNULL_END
