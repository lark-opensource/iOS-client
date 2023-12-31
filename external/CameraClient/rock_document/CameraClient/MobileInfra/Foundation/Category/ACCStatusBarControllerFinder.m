//
//  ACCStatusBarControllerFinder.m
//  CameraClient
//
//  Created by Puttin on 08/03/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCStatusBarControllerFinder.h"
#import <objc/runtime.h>
#import <CreativeKit/UIApplication+ACC.h>

#define ACCBase64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]

NSString * const ACCACCUpdateFinderLogicNeeded = @"ACCACCUpdateFinderLogicNeeded";

@interface UIViewController (ACCStatusBarController) <ACCStatusBarController> @end

@implementation ACCStatusBarControllerFinder

+ (void)initialize
{
    if (self == [ACCStatusBarControllerFinder class]) {
        Class class = NSClassFromString(ACCBase64Decode(@"X1VJUm9vdFByZXNlbnRhdGlvbkNvbnRyb2xsZXI="));//_UIRootPresentationController
        if (!class) {
            return;
        }
        
        SEL hiddenSEL = NSSelectorFromString(@"acc_statusBarHidden");
        IMP hiddenIMP = imp_implementationWithBlock(^(NSObject *self) {
            SEL visibilitySEL = NSSelectorFromString(ACCBase64Decode(@"X3ByZWZlcnJlZFN0YXR1c0JhclZpc2liaWxpdHk="));//_preferredStatusBarVisibility
            if ([self respondsToSelector:visibilitySEL]) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:visibilitySEL]];
                [invocation setSelector:visibilitySEL];
                [invocation setTarget:self];
                [invocation invoke];
                int returnValue;
                [invocation getReturnValue:&returnValue];
                return returnValue;
            }
            
            NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
            return (int)0x2; //Xcode11
        });
        if (!class_addMethod(class, hiddenSEL, hiddenIMP, method_getTypeEncoding(class_getInstanceMethod(UIViewController.class, hiddenSEL)))) {
            Method method = class_getInstanceMethod(class, hiddenSEL);
            if (!method) {
                return;
            }
            
            method_setImplementation(method, hiddenIMP);
        }
        
        SEL styleSEL = NSSelectorFromString(@"acc_statusBarStyle");
        IMP styleIMP = imp_implementationWithBlock(^(NSObject *self) {
            SEL styleSEL = NSSelectorFromString(@"preferredStatusBarStyle");
            if ([self respondsToSelector:styleSEL]) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:styleSEL]];
                [invocation setSelector:styleSEL];
                [invocation setTarget:self];
                [invocation invoke];
                NSInteger returnValue;
                [invocation getReturnValue:&returnValue];
                return returnValue;
            }
            
            NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
            return (NSInteger)0x1; //Xcode11
        });
        if (!class_addMethod(class, styleSEL, styleIMP, method_getTypeEncoding(class_getInstanceMethod(UIViewController.class, styleSEL)))) {
            Method method = class_getInstanceMethod(class, styleSEL);
            if (!method) {
                return;
            }
            
            method_setImplementation(method, styleIMP);
        }
    }
}

+ (UIViewController *)effectiveStatusBarControllerFrom:(UIViewController *)viewController for:(ACCStatusBarControllerFindType)type {
    if (!viewController) {
        viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    if (!viewController) {
        viewController = [UIApplication acc_currentWindow].rootViewController;
    }
    if (!viewController) {
        return nil;
    }
    
    UIViewController *result;
    
    NSString *privateMethodName;
    switch (type) {
        case ACCStatusBarControllerFindStyle:
            privateMethodName = ACCBase64Decode(@"X2VmZmVjdGl2ZVN0YXR1c0JhclN0eWxlVmlld0NvbnRyb2xsZXI="); //_effectiveStatusBarStyleViewController
            break;
        case ACCStatusBarControllerFindHidden:
            privateMethodName = ACCBase64Decode(@"X2VmZmVjdGl2ZVN0YXR1c0JhckhpZGRlblZpZXdDb250cm9sbGVy"); //_effectiveStatusBarHiddenViewController
            break;
    }
    SEL sel = NSSelectorFromString(privateMethodName);
    
    if ([viewController respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        result = [viewController performSelector:sel];
#pragma clang diagnostic pop
    } else {
        NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
        result = [self planBFrom:viewController for:type];
    }
    
    return result;
}

+ (UIViewController *)planBFrom:(UIViewController *)viewController for:(ACCStatusBarControllerFindType)type {
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
            case ACCStatusBarControllerFindStyle:
                childViewController = viewController.childViewControllerForStatusBarStyle;
                break;
            case ACCStatusBarControllerFindHidden:
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
    NSString *privateMethodName = ACCBase64Decode(@"X2ZpbmRXaW5kb3dGb3JDb250cm9sbGluZ092ZXJhbGxBcHBlYXJhbmNl"); //_findWindowForControllingOverallAppearance
    SEL sel = NSSelectorFromString(privateMethodName);
    if ([window respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        result = [window performSelector:sel];
#pragma clang diagnostic pop
    } else {
        NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
    }
    return result;
}

+ (id <ACCStatusBarController>)currentStatusBarControllerForType:(ACCStatusBarControllerFindType)type
{
    id <ACCStatusBarController> result = nil;
    if (@available(iOS 13.0, *)) {
        /*
         iOS 13 introduce UIWindowScene & UIStatusBarManager
         check -[UIStatusBarManager updateStatusBarAppearance]
         */
        UIWindow *window = [self windowForControllingOverallAppearance];
        result = [self effectiveStatusBarControllerFrom:window.rootViewController for:type];
        if (!result) {
            NSString *_rootPresentationControllerMethodName = ACCBase64Decode(@"X3Jvb3RQcmVzZW50YXRpb25Db250cm9sbGVy");//_rootPresentationController
            SEL sel = NSSelectorFromString(_rootPresentationControllerMethodName);
            if ([window respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                result = [window performSelector:sel];
#pragma clang diagnostic pop
                if (![result respondsToSelector:@selector(acc_statusBarHidden)]
                    || ![result respondsToSelector:@selector(acc_statusBarStyle)]
                    ) {
                    result = nil;
                    NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
                }
            } else {
                NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
            }
        }
    }
    else {
        // Only iOS under iOS 13 has +[UIViewController _currentStatusBarStyleViewController 😢
        Class VC = UIViewController.class;
        
        NSString *privateMethodName;
        switch (type) {
            case ACCStatusBarControllerFindStyle:
                privateMethodName = ACCBase64Decode(@"X2N1cnJlbnRTdGF0dXNCYXJTdHlsZVZpZXdDb250cm9sbGVy"); //_currentStatusBarStyleViewController
                break;
            case ACCStatusBarControllerFindHidden:
                privateMethodName = ACCBase64Decode(@"X2N1cnJlbnRTdGF0dXNCYXJIaWRkZW5WaWV3Q29udHJvbGxlcg=="); //_currentStatusBarHiddenViewController
                break;
        }
        SEL sel = NSSelectorFromString(privateMethodName);
        
        if ([VC respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            result = [VC performSelector:sel];
#pragma clang diagnostic pop
        } else {
            NSAssert(NO, ACCACCUpdateFinderLogicNeeded);
        }
    }
    return result;
}

@end

@implementation UIViewController (ACCStatusBarController)

- (UIStatusBarStyle)acc_statusBarStyle
{
    return self.preferredStatusBarStyle;
}

- (BOOL)acc_statusBarHidden
{
    return self.prefersStatusBarHidden;
}

@end
