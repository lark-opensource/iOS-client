//
//  ACCStatusBarControllerFinder.h
//  CameraClient
//
//  Created by Puttin on 08/03/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ACCStatusBarControllerFindType) {
    ACCStatusBarControllerFindHidden,
    ACCStatusBarControllerFindStyle,
};

@protocol ACCStatusBarController <NSObject>
- (BOOL)acc_statusBarHidden;
- (UIStatusBarStyle)acc_statusBarStyle;
@end

@interface ACCStatusBarControllerFinder : NSObject

// use currentStatusBarViewControllerForType: if possible
+ (UIViewController *)effectiveStatusBarControllerFrom:(UIViewController *)viewController for:(ACCStatusBarControllerFindType)type;

// find the window which controlling overall appearance in main scene
+ (UIWindow *)windowForControllingOverallAppearance;

+ (id <ACCStatusBarController>)currentStatusBarControllerForType:(ACCStatusBarControllerFindType)type;

@end
