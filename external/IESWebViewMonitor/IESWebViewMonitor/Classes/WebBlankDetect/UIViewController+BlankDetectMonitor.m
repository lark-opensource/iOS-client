//
//  UIViewController+BlankDetectMonitor.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/23.
//

#import "UIViewController+BlankDetectMonitor.h"
#import <objc/runtime.h>
#import <BDWebKit/BDWebViewBlankDetect.h>

static void MethodSwizzle(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@interface UIViewController (BlankDetectMonitorInternal)

@property (nonatomic, assign) BOOL bdwm_isTurnOnBlankDetect;
@property (nonatomic, assign) BOOL bdwm_haveDetected;
@property (nonatomic, weak) WKWebView *bdwm_containedWebView;
@property (nonatomic, copy) BDWebViewMonitorBizSwitchBlock bdwm_bizSwitchBlock;

@end

@implementation UIViewController (BlankDetectMonitorInternal)

#pragma mark - getter and setter

- (const void *)temp_computedKeyFromString:(NSString *)key {
    return (char *)((__bridge void*)self) + [key hash] + [key characterAtIndex:0] + [key characterAtIndex:key.length - 1];
}

- (void)setBdwm_isTurnOnBlankDetect:(BOOL)bdwm_isTurnOnBlankDetect {
    objc_setAssociatedObject(self
                             , [self temp_computedKeyFromString:@"bdwm_isTurnOnBlankDetect"]
                             , @(bdwm_isTurnOnBlankDetect)
                             , OBJC_ASSOCIATION_RETAIN);
    if (bdwm_isTurnOnBlankDetect) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MethodSwizzle(self.class,@selector(dismissViewControllerAnimated:completion:),@selector(bdwm_dismissViewControllerAnimated:completion:));
        });
    }
}

- (BOOL)bdwm_isTurnOnBlankDetect {
    return objc_getAssociatedObject(self, [self temp_computedKeyFromString:@"bdwm_isTurnOnBlankDetect"]);
}

- (void)setBdwm_haveDetected:(BOOL)bdwm_haveDetected {
    objc_setAssociatedObject(self
                             , [self temp_computedKeyFromString:@"bdwm_haveDetected"]
                             , @(bdwm_haveDetected)
                             , OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bdwm_haveDetected {
    return objc_getAssociatedObject(self, [self temp_computedKeyFromString:@"bdwm_haveDetected"]);
}

- (void)setBdwm_containedWebView:(WKWebView *)bdwm_containedWebView {
    id __weak weakObject = bdwm_containedWebView;
    id (^block)(void) = ^{ return weakObject; };
    objc_setAssociatedObject(self,
                             [self temp_computedKeyFromString:@"bdwm_containedWebView"],
                             block,
                             OBJC_ASSOCIATION_COPY);
}

- (WKWebView *)bdwm_containedWebView {
    id (^block)(void) = objc_getAssociatedObject(self,
                                                 [self temp_computedKeyFromString:@"bdwm_containedWebView"]);
    return (block ? block() : nil);
}

- (void)setBdwm_bizSwitchBlock:(BDWebViewMonitorBizSwitchBlock)bdwm_bizSwitchBlock {
    objc_setAssociatedObject(self
                             , [self temp_computedKeyFromString:@"bdwm_bizSwitchBlock"]
                             , bdwm_bizSwitchBlock
                             , OBJC_ASSOCIATION_COPY);
}

- (BDWebViewMonitorBizSwitchBlock)bdwm_bizSwitchBlock {
    BDWebViewMonitorBizSwitchBlock block = objc_getAssociatedObject(self,
                                                 [self temp_computedKeyFromString:@"bdwm_bizSwitchBlock"]);
    return block;
}

#pragma mark - logic

- (void)bdwm_viewDidDisappear:(BOOL)animated {
    [self tryDetectWebViewBlankIfNeeded];
    [self bdwm_viewDidDisappear:animated];
}

- (void)bdwm_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self tryDetectWebViewBlankIfNeeded];
    [self bdwm_dismissViewControllerAnimated:flag completion:completion];
}

- (BOOL)tryDetectChildVCWebViewBlankIfNeeded {
    if (self.bdwm_containedWebView) {
        return NO;
    }
    
    if (self.childViewControllers.count > 0) {
        for (UIViewController *vc in self.childViewControllers) {
            if ([vc shouldDetectBlank]) {
                [vc tryDetectWebViewBlankIfNeeded];
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)shouldDetectBlank {
    if (!self.bdwm_containedWebView || ![self.bdwm_containedWebView isKindOfClass:WKWebView.class]  // 不是webview的不检查
        || !self.bdwm_isTurnOnBlankDetect   // 没有开启的不检查
        || self.bdwm_haveDetected) {  // 检过的不检查
        return NO;
    }
    if (self.bdwm_bizSwitchBlock) { // 业务接入方决定是否需要检测
        return self.bdwm_bizSwitchBlock(self.bdwm_containedWebView.URL.absoluteString);
    }
    return YES;
}

- (void)tryDetectWebViewBlankIfNeeded {
    BOOL detectChild = [self tryDetectChildVCWebViewBlankIfNeeded];
    if (detectChild) {
        return;
    }
    
    if (![self shouldDetectBlank]) {
        return;
    }
    
    self.bdwm_haveDetected = YES;
    if (@available(iOS 11.0, *)) {
        [BDWebViewBlankDetect detectBlankByNewSnapshotWithWKWebView:self.bdwm_containedWebView CompleteBlock:^(BOOL isBlank, UIImage *image, NSError *error) {}];
    } else {
        [BDWebViewBlankDetect detectBlankByOldSnapshotWithView:self.bdwm_containedWebView CompleteBlock:^(BOOL isBlank, UIImage * _Nonnull image, NSError * _Nonnull error) {}];
    }
}

@end

#pragma mark --

@interface UINavigationController (BlankDetectMonitor)

@property (nonatomic, assign) BOOL bdwm_isTurnOnBlankDetect;

@end

@implementation UINavigationController (BlankDetectMonitor)

- (const void *)temp_computedKeyFromString:(NSString *)key {
    return (char *)((__bridge void*)self) + [key hash] + [key characterAtIndex:0] + [key characterAtIndex:key.length - 1];
}

- (void)setBdwm_isTurnOnBlankDetect:(BOOL)bdwm_isTurnOnBlankDetect {
    objc_setAssociatedObject(self
                             , [self temp_computedKeyFromString:@"bdwm_isTurnOnBlankDetect"]
                             , @(bdwm_isTurnOnBlankDetect)
                             , OBJC_ASSOCIATION_RETAIN);
    if (bdwm_isTurnOnBlankDetect) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MethodSwizzle(self.class,@selector(popViewControllerAnimated:),@selector(bdwm_popViewControllerAnimated:));
            MethodSwizzle(self.class,@selector(popToViewController:animated:),@selector(bdwm_popToViewController:animated:));
            MethodSwizzle(self.class,@selector(popToRootViewControllerAnimated:),@selector(bdwm_popToRootViewControllerAnimated:));
        });
    }
}

- (UIViewController *)bdwm_popViewControllerAnimated:(BOOL)animated {
    UIViewController *topVC = self.topViewController;
    [topVC tryDetectWebViewBlankIfNeeded];
    return [self bdwm_popViewControllerAnimated:animated];
}

-(NSArray *)bdwm_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIViewController *topVC = self.topViewController;
    [topVC tryDetectWebViewBlankIfNeeded];
    return [self bdwm_popToViewController:viewController animated:animated];
}

- (NSArray *)bdwm_popToRootViewControllerAnimated:(BOOL)animated {
    UIViewController *topVC = self.topViewController;
    [topVC tryDetectWebViewBlankIfNeeded];
    return [self bdwm_popToRootViewControllerAnimated:animated];
}

- (BOOL)bdwm_isTurnOnBlankDetect {
    return objc_getAssociatedObject(self, [self temp_computedKeyFromString:@"bdwm_isTurnOnBlankDetect"]);
}

@end

#pragma mark --

@implementation UIViewController (BlankDetectMonitor)

- (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView {
    [self switchWebViewBlankDetect:isOn webView:webView bizSwitchBlock:nil];
}

- (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView bizSwitchBlock:(nullable BDWebViewMonitorBizSwitchBlock)bizSwitchBlock {
    self.bdwm_isTurnOnBlankDetect = isOn;
    self.bdwm_containedWebView = webView;
    self.bdwm_bizSwitchBlock = bizSwitchBlock;
    
    if (isOn) {
        self.navigationController.bdwm_isTurnOnBlankDetect = YES;
    } else {
        self.navigationController.bdwm_isTurnOnBlankDetect = NO;
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if (vc.bdwm_isTurnOnBlankDetect) {
                self.navigationController.bdwm_isTurnOnBlankDetect = YES;
                break;
            }
        }
    }
}

@end

@implementation BDMonitorWebBlankDetector

+ (void)switchWebViewBlankDetect:(BOOL)isOn webView:(WKWebView *)webView viewController:(UIViewController *)viewController {
    if (viewController) {
        [viewController switchWebViewBlankDetect:isOn webView:webView];
    }
}

@end
