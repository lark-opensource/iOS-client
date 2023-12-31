//
//  UIWindow+EMA.m
//  EEMicroAppSDK
//
//  Created by bupozhuang on 2019/1/2.
//

#import "UIWindow+EMA.h"
#import <OPFoundation/OPFoundation-Swift.h>

@implementation UIWindow (EMA)

+ (CGSize)ema_currentContainerSize:(UIWindow * _Nullable)window
{
    UINavigationController *navigation = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:window];
    return navigation ? navigation.view.bounds.size : [self ema_currentWindowSize:window];
}

+ (CGSize)ema_currentWindowSize:(UIWindow * _Nullable)window
{
    return window ? window.bounds.size : UIScreen.mainScreen.bounds.size;
}

@end
