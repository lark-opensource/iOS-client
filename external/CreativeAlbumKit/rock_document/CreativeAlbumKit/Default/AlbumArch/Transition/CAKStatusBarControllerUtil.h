//
//  CAKStatusBarControllerUtil.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CAKStatusBarControllerFindType) {
    CAKStatusBarControllerFindHidden,
    CAKStatusBarControllerFindStyle,
};

@protocol CAKStatusBarEvilController <NSObject>

@optional
- (BOOL)cak_statusBarHidden;
- (UIStatusBarStyle)cak_statusBarStyle;

@end

@interface CAKStatusBarControllerUtil : NSObject

// use currentStatusBarViewControllerForType: if possible
+ (UIViewController * _Nullable)effectiveStatusBarControllerFrom:(UIViewController * _Nullable)viewController for:(CAKStatusBarControllerFindType)type;

// find the window which controlling overall appearance in main scene
+ (UIWindow * _Nullable)windowForControllingOverallAppearance;

+ (id <CAKStatusBarEvilController> _Nullable)currentStatusBarControllerForType:(CAKStatusBarControllerFindType)type;

@end
