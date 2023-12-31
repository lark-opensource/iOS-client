// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxHeroViewControllerConfig : NSObject
@property(nonatomic, weak) id<UINavigationControllerDelegate> previousNavigationDelegate;
@property(nonatomic, weak) id<UITabBarControllerDelegate> previousTabBarDelegate;
@property(nonatomic, assign) BOOL enableHeroTransition;
@property(nonatomic, readonly, weak) UIViewController* vc;

- (instancetype)initWithVC:(UIViewController*)vc;

@end

@interface UIViewController (LynxHeroTransition)
@property(nonatomic, readonly) LynxHeroViewControllerConfig* lynxHeroConfig;
@end

NS_ASSUME_NONNULL_END
