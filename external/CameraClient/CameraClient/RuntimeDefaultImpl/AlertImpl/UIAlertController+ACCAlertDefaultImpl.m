//
//  UIAlertController+ACCAlertDefaultImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/16.
//

#import "UIAlertController+ACCAlertDefaultImpl.h"
#import <objc/runtime.h>
#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>

#define ACCDefaultImplTransition64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]

@interface UIAlertController (ACCAlertDefaultImplPrivate)

@property (nonatomic, strong) UIWindow *acc_alertWindow;

@end

@implementation UIAlertController (ACCAlertDefaultImplPrivate)

@dynamic acc_alertWindow;

- (void)setAcc_alertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(acc_alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)acc_alertWindow {
    return objc_getAssociatedObject(self, @selector(acc_alertWindow));
}

@end

@implementation UIAlertController (ACCAlertDefaultImpl)

AWELazyRegisterPremainClassCategory(UIAlertController, ACCAlertDefaultImpl)
{
    [self btd_swizzleInstanceMethod:@selector(viewDidDisappear:) with:@selector(acc_viewDidDisappear:)];
}

- (void)acc_show
{
    [self acc_show:YES];
}

- (void)acc_showFromView:(UIView *)view
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [view isKindOfClass:[UIView class]]) {
        self.popoverPresentationController.sourceView = view;
        self.popoverPresentationController.sourceRect = view.bounds;
        [[BTDResponder topViewControllerForView:view] presentViewController:self animated:YES completion:nil];
    }else{
        [self acc_show];
    }
}

- (void)acc_show:(BOOL)animated
{
    self.acc_alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.acc_alertWindow.accessibilityViewIsModal = YES;
    self.acc_alertWindow.rootViewController = [[UIViewController alloc] init];
    self.acc_alertWindow.windowLevel = UIWindowLevelAlert + 1;
    //    [self.alertWindow makeKeyAndVisible]; // convenience. most apps call this to show the main window and also make it key. otherwise use view hidden property (Apple Document)
    self.acc_alertWindow.hidden = NO; // 只做显示 不更改keyWindow
    
    UIAlertController *alert = self;
    NSString *_temporaryPresentationControllerKey = ACCDefaultImplTransition64Decode(@"X3RlbXBvcmFyeVByZXNlbnRhdGlvbkNvbnRyb2xsZXI="); //_temporaryPresentationController
    if (self.preferredStyle == UIAlertControllerStyleActionSheet && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && //iPad & action Sheet
        (![self valueForKey:_temporaryPresentationControllerKey] || //popoverPresentationController not exist
         ([[self valueForKey:_temporaryPresentationControllerKey] isKindOfClass:[UIPopoverPresentationController class]] &&
          [(UIPopoverPresentationController *)[self valueForKey:_temporaryPresentationControllerKey] sourceView] == nil) //popoverPresentationController exist but sourceView is nil
         ))
    {
        // iPad 未设置 Anchor View
        
        //_temporaryPresentationController is used to stop popoverPresentationController auto create behavior
        // if use popoverPresentationController.sourceView directly would cause popoverPresentationController and self retain each other
        // because we don't have sourceView or self never presented
        alert = [UIAlertController alertControllerWithTitle:self.title message:self.message preferredStyle:UIAlertControllerStyleAlert];
        [self.actions enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //we need to copy the action
            //because the original UIAlertController dealloc would _clearActionHandlers
            [alert addAction:[obj copy]];
        }];
        //tranfer alertWindow
        alert.acc_alertWindow = self.acc_alertWindow;
        self.acc_alertWindow = nil;
    }
    
    [alert.acc_alertWindow.rootViewController presentViewController:alert animated:animated completion:nil];
}

- (void)acc_viewDidDisappear:(BOOL)animated
{
    [self acc_viewDidDisappear:animated];
    
    self.acc_alertWindow.accessibilityViewIsModal = NO;
    self.acc_alertWindow.hidden = YES;
    self.acc_alertWindow = nil;
}

- (NSArray *)acc_viewArray:(UIView *)root
{
    static NSArray *_subviews = nil;
    _subviews = nil;
    for (UIView *v in root.subviews) {
        if (_subviews) {
            break;
        }
        if ([v isKindOfClass:[UILabel class]]) {
            _subviews = root.subviews;
            return _subviews;
        }
        [self acc_viewArray:v];
    }
    return _subviews;
}

- (UILabel *)acc_titleLabel
{
    return [self acc_viewArray:self.view][0];
}

- (UILabel *)acc_messageLabel
{
    return [self acc_viewArray:self.view][1];
}

@end
