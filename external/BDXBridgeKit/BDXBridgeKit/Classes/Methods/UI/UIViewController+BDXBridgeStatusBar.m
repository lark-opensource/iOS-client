//
//  UIViewController+BDXBridgeStatusBar.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "UIViewController+BDXBridgeStatusBar.h"
#import "BDXBridgeConfigureStatusBarMethod.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <objc/runtime.h>

static IMP bdx_animationIMP = nil;
static IMP bdx_hiddenIMP = nil;
static IMP bdx_styleIMP = nil;

@implementation UIViewController (BDXBridgeStatusBar)
+ (void)bdx_engineReady
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method animationMethod = class_getInstanceMethod(self, @selector(bdx_preferredStatusBarUpdateAnimation));
        bdx_animationIMP = method_getImplementation(animationMethod);
        Method hiddenMethod = class_getInstanceMethod(self, @selector(bdx_prefersStatusBarHidden));
        bdx_hiddenIMP = method_getImplementation(hiddenMethod);
        Method styleMethod = class_getInstanceMethod(self, @selector(bdx_preferredStatusBarStyle));
        bdx_styleIMP = method_getImplementation(styleMethod);
    });  
}

- (UIStatusBarAnimation)bdx_preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (BOOL)bdx_prefersStatusBarHidden
{
    return self.bdx_statusBarHidden;
}

- (UIStatusBarStyle)bdx_preferredStatusBarStyle
{
    return self.bdx_statusBarStyle;
}

- (void)bdx_configureStatusBarWithParamModel:(BDXBridgeConfigureStatusBarMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
   [UIViewController bdx_engineReady]; 
    // In order to avoid affecting other swizzling, we will swizzle once before configuring, and then swizzle back after finishing configuring.
    [self.class swizzleIfNeeded:YES];
    dispatch_block_t completionBlock = ^void() {
        [self.class swizzleIfNeeded:NO];
        bdx_invoke_block(completionHandler, nil, nil);
    };
    
    BOOL viewControllerBased = [([NSBundle.mainBundle objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] ?: @YES) boolValue];
    self.bdx_statusBarHidden = !paramModel.visible;
    switch (paramModel.style) {
        case BDXBridgeStatusStyleLight:
            self.bdx_statusBarStyle = UIStatusBarStyleLightContent;
            break;
        case BDXBridgeStatusStyleDark:
            if (@available(iOS 13.0, *)) {
                self.bdx_statusBarStyle = UIStatusBarStyleDarkContent;
            }
            break;
        default:
            break;
    }
    
    // Update background color of status bar.
    // NOTE: only support changing before iOS 13.
    if (paramModel.backgroundColor) {
        if (@available(iOS 13.0, *)) {} else {
            UIView *statusBar = [[UIApplication.sharedApplication valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
            if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
                statusBar.backgroundColor = paramModel.backgroundColor;
            }
        }
    }
    
    // Update status bar style & hidden status.
    if (viewControllerBased) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:completionBlock];
        [self setNeedsStatusBarAppearanceUpdate];
        [CATransaction commit];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [UIApplication.sharedApplication setStatusBarStyle:self.bdx_statusBarStyle animated:YES];
        [UIApplication.sharedApplication setStatusBarHidden:self.bdx_statusBarHidden withAnimation:UIStatusBarAnimationFade];
#pragma GCC diagnostic pop
    }
}

#pragma mark - Accessors

- (void)setBdx_statusBarHidden:(BOOL)bdx_statusBarHidden
{
    objc_setAssociatedObject(self, @selector(bdx_statusBarHidden), @(bdx_statusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdx_statusBarHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdx_statusBarStyle:(UIStatusBarStyle)bdx_statusBarStyle
{
    objc_setAssociatedObject(self, @selector(bdx_statusBarStyle), @(bdx_statusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIStatusBarStyle)bdx_statusBarStyle
{
    return (UIStatusBarStyle)[objc_getAssociatedObject(self, _cmd) integerValue];
}

#pragma mark - Helpers

+ (BOOL)hasBeenSwizzled
{
    Method animationMethod = class_getInstanceMethod(self, @selector(preferredStatusBarUpdateAnimation));
    IMP animationIMP = method_getImplementation(animationMethod);
    Method hiddenMethod = class_getInstanceMethod(self, @selector(prefersStatusBarHidden));
    IMP hiddenIMP = method_getImplementation(hiddenMethod);
    Method styleMethod = class_getInstanceMethod(self, @selector(preferredStatusBarStyle));
    IMP styleIMP = method_getImplementation(styleMethod);
    return animationIMP == bdx_animationIMP && hiddenIMP == bdx_hiddenIMP && styleIMP == bdx_styleIMP;
}

+ (void)swizzleIfNeeded:(BOOL)swizzle
{
    BOOL shouldSwizzle = swizzle ? ![self hasBeenSwizzled] : [self hasBeenSwizzled];
    if (shouldSwizzle) {
        [self btd_swizzleInstanceMethod:@selector(preferredStatusBarUpdateAnimation) with:@selector(bdx_preferredStatusBarUpdateAnimation)];
        [self btd_swizzleInstanceMethod:@selector(prefersStatusBarHidden) with:@selector(bdx_prefersStatusBarHidden)];
        [self btd_swizzleInstanceMethod:@selector(preferredStatusBarStyle) with:@selector(bdx_preferredStatusBarStyle)];
    }
}

@end
