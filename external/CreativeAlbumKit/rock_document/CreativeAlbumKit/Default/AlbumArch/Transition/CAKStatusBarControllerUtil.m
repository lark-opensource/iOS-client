//
//  CAKStatusBarControllerUtil.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import "CAKStatusBarControllerUtil.h"
#import <objc/runtime.h>

#define AWEBase64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]

static NSString * const UpdateFinderLogicNeeded = @"UpdateFinderLogicNeeded";

@interface UIViewController (CAKStatusBarEvilController) <CAKStatusBarEvilController>

@end

@implementation UIViewController (CAKStatusBarEvilController)

- (UIStatusBarStyle)cak_statusBarStyle
{
    return self.preferredStatusBarStyle;
}

- (BOOL)cak_statusBarHidden
{
    return self.prefersStatusBarHidden;
}

@end

@implementation CAKStatusBarControllerUtil

+ (UIViewController *)effectiveStatusBarControllerFrom:(UIViewController *)viewController for:(CAKStatusBarControllerFindType)type {
    if (!viewController) {
        viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    if (!viewController) {
        viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    if (!viewController) {
        return nil;
    }
    
    UIViewController *result;
    
    NSString *privateMethodName;
    switch (type) {
        case CAKStatusBarControllerFindStyle:
            privateMethodName = AWEBase64Decode(@"X2VmZmVjdGl2ZVN0YXR1c0JhclN0eWxlVmlld0NvbnRyb2xsZXI="); //_effectiveStatusBarStyleViewController
            break;
        case CAKStatusBarControllerFindHidden:
            privateMethodName = AWEBase64Decode(@"X2VmZmVjdGl2ZVN0YXR1c0JhckhpZGRlblZpZXdDb250cm9sbGVy"); //_effectiveStatusBarHiddenViewController
            break;
    }
    SEL sel = NSSelectorFromString(privateMethodName);
    
    if ([viewController respondsToSelector:sel]) {
        result = [viewController performSelector:sel];
    } else {
        NSAssert(NO, UpdateFinderLogicNeeded);
        result = [self planBFrom:viewController for:type];
    }
    
    return result;
}

+ (UIViewController *)planBFrom:(UIViewController *)viewController for:(CAKStatusBarControllerFindType)type {
    if (!viewController) {
        return nil;
    }
    
    while (viewController.presentedViewController) {
        UIViewController *presentedController = viewController.presentedViewController;
        if (presentedController.isBeingDismissed) {
            break;
        }
        if (presentedController.modalPresentationStyle == UIModalPresentationFullScreen ||
            presentedController.modalPresentationCapturesStatusBarAppearance) {
            viewController = presentedController;
        } else {
            break;
        }
    }
    
    BOOL stop = NO;
    while (!stop) {
        UIViewController *childViewController;
        switch (type) {
            case CAKStatusBarControllerFindStyle:
                childViewController = viewController.childViewControllerForStatusBarStyle;
                break;
            case CAKStatusBarControllerFindHidden:
                childViewController = viewController.childViewControllerForStatusBarHidden;
                break;
        }
        if (childViewController) {
            viewController = childViewController;
        } else {
            stop = YES;
        }
    }
    
    return viewController;
}

+ (UIWindow *)windowForControllingOverallAppearance
{
    UIWindow *result = nil;
    //see also _findWindowForControllingOverallAppearanceInWindowScene:
    Class window = UIWindow.class;
    NSString *privateMethodName = AWEBase64Decode(@"X2ZpbmRXaW5kb3dGb3JDb250cm9sbGluZ092ZXJhbGxBcHBlYXJhbmNl"); //_findWindowForControllingOverallAppearance
    SEL sel = NSSelectorFromString(privateMethodName);
    if ([window respondsToSelector:sel]) {
        result = [window performSelector:sel];
    } else {
        NSAssert(NO, UpdateFinderLogicNeeded);
    }
    return result;
}

+ (id <CAKStatusBarEvilController>)currentStatusBarControllerForType:(CAKStatusBarControllerFindType)type
{
    id <CAKStatusBarEvilController> result = nil;
    if (@available(iOS 13.0, *)) {
        /*
         iOS 13 introduce UIWindowScene & UIStatusBarManager
         check -[UIStatusBarManager updateStatusBarAppearance]
         */
        UIWindow *window = [self windowForControllingOverallAppearance];
        result = [self effectiveStatusBarControllerFrom:window.rootViewController for:type];
        if (!result) {
            NSString *_rootPresentationControllerMethodName = AWEBase64Decode(@"X3Jvb3RQcmVzZW50YXRpb25Db250cm9sbGVy");//_rootPresentationController
            SEL sel = NSSelectorFromString(_rootPresentationControllerMethodName);
            if ([window respondsToSelector:sel]) {
                result = [window performSelector:sel];
                if (![result respondsToSelector:@selector(cak_statusBarHidden)]
                    || ![result respondsToSelector:@selector(cak_statusBarStyle)]
                    ) {
                    result = nil;
                    NSAssert(NO, UpdateFinderLogicNeeded);
                }
            } else {
                NSAssert(NO, UpdateFinderLogicNeeded);
            }
        }
    }
    else {
        // Only iOS under iOS 13 has +[UIViewController _currentStatusBarStyleViewController 😢
        Class VC = UIViewController.class;
        
        NSString *privateMethodName;
        switch (type) {
            case CAKStatusBarControllerFindStyle:
                privateMethodName = AWEBase64Decode(@"X2N1cnJlbnRTdGF0dXNCYXJTdHlsZVZpZXdDb250cm9sbGVy"); //_currentStatusBarStyleViewController
                break;
            case CAKStatusBarControllerFindHidden:
                privateMethodName = AWEBase64Decode(@"X2N1cnJlbnRTdGF0dXNCYXJIaWRkZW5WaWV3Q29udHJvbGxlcg=="); //_currentStatusBarHiddenViewController
                break;
        }
        SEL sel = NSSelectorFromString(privateMethodName);
        
        if ([VC respondsToSelector:sel]) {
            result = [VC performSelector:sel];
        } else {
            NSAssert(NO, UpdateFinderLogicNeeded);
        }
    }
    return result;
}


@end
