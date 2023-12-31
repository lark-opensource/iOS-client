//
//  TMAPluginUIWidgetCustomImpl.m
//  Pods
//
//  Created by zhangkun on 27/07/2018.
//

#import <UIKit/UIKit.h>
#import "TMAPluginUIWidgetCustomImpl.h"
#import <OPFoundation/EMAAlertController.h>
#import "EMAAppEngine.h"
#import <OPFoundation/UIImage+EMA.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/BDPAppController.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPBlankDetectConfig.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

@interface TMAPluginUIWidgetCustomImpl() <BDPToastPluginDelegate, BDPModalPluginDelegate, BDPNavigationPluginDelegate, BDPWebviewPluginDelegate, BDPAlertPluginDelegate, BDPCustomResponderPluginDelegate>
@property (nonatomic, weak) EMAHUD *hudView;
@end


@implementation TMAPluginUIWidgetCustomImpl

#pragma mark - BDPToastPluginDelegate

- (void)bdp_showToastWithModel:(BDPToastPluginModel *)model
{
    BDPLogInfo(@"bdp_showToastWithModel");
    UIViewController *controller = [BDPAppController currentAppPageController:nil fixForPopover:false];
    [self bdp_showToastWithModel:model inController:controller];
}

- (void)bdp_showToastWithModel:(BDPToastPluginModel *)model inController:(UIViewController *)controller
{
    BDPLogInfo(@"bdp_showToastWithModel");
    NSString *title = model.title;
    NSString *icon = model.icon;
    NSTimeInterval duration = (model.duration > 0) ? (model.duration / 1000.0) : 1.5;   // 默认时间：1.5s
    BOOL mask = model.mask;

    UIWindow *window = controller.view.window;
    
    UIView *view = controller.view;
    if ([controller isKindOfClass:UINavigationController.class]) {
        view = ((UINavigationController *)controller).topViewController.view ?: controller.view;
    }
    if (!view) {
        view = [self topVCView:window];
    }
    [EMAHUD removeHUDOn:view window:window];
    EMAHUD *hudView;
    if ([icon isEqualToString:@"loading"]) {
        hudView = [EMAHUD showLoading:title on:view window:window delay: duration disableUserInteraction:mask];
    } else if ([icon isEqualToString:@"success"]) {
        hudView = [EMAHUD showSuccess:title on:view window:window delay: duration disableUserInteraction:mask];
    } else if ([icon isEqualToString:@"fail"]) {
        hudView = [EMAHUD showFailure:title on:view window:window delay: duration disableUserInteraction:mask];
    } else {
        hudView = [EMAHUD showTips:title on:view window:window delay: duration disableUserInteraction:mask];
    }
    self.hudView = hudView;
}

- (void)bdp_hideToast:(UIWindow * _Nullable)window
{
    BDPLogInfo(@"bdp_hideToast");
    [self.hudView remove];
    [EMAHUD removeHUDWithWindow:window];

    UIView *view = [self topVCView:window];
    [EMAHUD removeHUDOn:view window:window];
}
#pragma mark - BDPModalPluginDelegate

- (void)bdp_showModalWithModel:(BDPModalPluginModel *)model confirmCallback:(void (^)())confirmCallback cancelCallback:(void (^)())cancelCallback inController:(UIViewController *)controller {
    BDPLogInfo(@"bdp_showModalWithModel");
    
    // 适配DarkMode:使用主端提供的UDDialog
    UDDialog *alert = [UDOCDialogBridge createDialog];
    
    [UDOCDialogBridge setTitleWithDialog:alert text:model.title];
    [UDOCDialogBridge setContentWithDialog:alert text:model.content];
    if (model.showCancel) {
        [UDOCDialogBridge addSecondaryButtonWithDialog:alert text:model.cancelText dismissCompletion:^{
            !cancelCallback ? : cancelCallback();
        }];
    }
    
    [UDOCDialogBridge addButtonWithDialog:alert text:model.confirmText dismissCompletion:^{
        !confirmCallback ? : confirmCallback();
    }];
    
    UIViewController *vc = controller;
    if (!vc) {
        vc = [OPNavigatorHelper topMostAppControllerWithWindow:controller.view.window];
    }
    if ([UDRotation isAutorotateFrom:vc]) {
        [UDOCDialogBridge setAutorotatableWithDialog:alert enable:YES];
    }
    [vc presentViewController:alert animated:YES completion:nil];
}

#pragma mark - BDPNavigationPluginDelegate

- (void)bdp_configNavigationControllerWithParam:(NSDictionary *)param currentViewController:(UIViewController *)currentViewController
{
    BDPLogInfo(@"bdp_configNavigationController, param=%@", param);
    BOOL isBarHidden = [param bdp_boolValueForKey:@"navigationBarHidden"];
    BOOL allowGestureBack = [param bdp_boolValueForKey:@"navigationGestureBack"];

    [currentViewController.navigationController setNavigationBarHidden:isBarHidden animated:YES];
    //侧滑一半放弃后不禁止侧滑功能
    //    [currentViewController.navigationController.interactivePopGestureRecognizer setEnabled:allowGestureBack];
}

/// 返回其他导航栏更多按钮
- (UIImage *)bdp_moreButtonImage {
    return [UIImage ema_imageNamed:@"ema_toolbar_more"];
}

/// 返回其他导航栏关闭按钮
- (UIImage *)bdp_closeButtonImage {
    return [UIImage ema_imageNamed:@"ema_toolbar_close"];
}

/// 返回圆角属性
- (CGFloat)bdp_toolbarCornerRadiusWithHeight:(CGFloat)height {
    return height / 2;
}

#pragma mark - BDPWebviewPluginDelegate

- (NSURLRequest *)bdp_synchronizeCookieForWebview:(WKWebView *)webview
                                          request:(NSURLRequest *)request
                             uniqueID:(BDPUniqueID *)uniqueID
{
    if (![EMAAppEngine.currentEngine.onlineConfig isWebviewSynchronizeCookieInWhiteListOfUniqueID:uniqueID]) {
        return request;
    }
    if (!webview || !request || !request.URL || BDPIsEmptyString(request.URL.absoluteString)) {
        return request;
    }
    NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:request.URL];
    if (BDPIsEmptyArray(cookies)) {
        return request;
    }
    NSDictionary<NSString *, NSString *> *cookiesHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    NSMutableURLRequest *mutRequest = [request mutableCopy];
    [cookiesHeader enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [mutRequest setValue:obj forHTTPHeaderField:key];
    }];
    WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:[TMAPluginUIWidgetCustomImpl _cookieJSStringForCookies:cookies] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [webview.configuration.userContentController addUserScript:cookieScript];

    return mutRequest.copy;
}

- (BDPBlankDetectConfig *)bdp_getWebviewDetectConfig {
    return [EMAAppEngine.currentEngine.onlineConfig getDetectConfig];
}

+ (NSString *)_cookieJSStringForCookies:(NSArray<NSHTTPCookie *> *)cookies
{
    NSMutableString *script = [NSMutableString string];
    for (NSHTTPCookie *cookie in cookies) {
        [script appendFormat:@"document.cookie='%@'; \n", [self _cookieJSFromatStringForCookie:cookie]];
    }
    return script;
}

+ (NSString *)_cookieJSFromatStringForCookie:(NSHTTPCookie *)cookie
{
    NSString *string = [NSString stringWithFormat:@"%@=%@;domain=%@;expiresDate=%@;path=%@;sessionOnly=%@;isSecure=%@",
                        cookie.name,
                        cookie.value,
                        cookie.domain,
                        cookie.expiresDate,
                        cookie.path ?: @"/",
                        cookie.isSecure ? @"TRUE":@"FALSE",
                        cookie.sessionOnly ? @"TRUE":@"FALSE"];
    return string;
}

#pragma mark - TMAPluginUIWidgetDelegate

+ (id<BDPBasePluginDelegate>)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

#pragma mark - BDPAlertPluginDelegate

- (UIViewController *)bdp_showAlertWithTitle:(NSString *)title
                                     content:(NSString *)content
                                     confirm:(NSString *)confirm
                              fromController:(UIViewController *)fromController
                             confirmCallback:(dispatch_block_t)confirmCallback
                                  showCancel:(BOOL)showCancel
{
    return (UIViewController*)[EMALarkAlert showAlertWithTitle:title ?: @""
                                                       content:content
                                                       confirm:confirm ?: @""
                                                fromController:fromController
                                               confirmCallback:confirmCallback
                                                    showCancel:showCancel];
}

#pragma maek - BDPCustomResponderPluginDelegate

- (UIViewController *)bdp_customTopMostViewControllerFor:(UIViewController *)rootViewController fixForPopover:(BOOL)fixForPopover {
    return [OPNavigatorHelper topMostOf:rootViewController searchSubViews:NO fixForPopover:fixForPopover];
}

#pragma mark -
- (void)setHudView:(EMAHUD *)hudView {
    if (_hudView == hudView) return;

    [_hudView remove];
    _hudView = hudView;
}

#pragma mark - helper

- (UIView *)topVCView:(UIWindow * _Nullable)window {
    UIViewController *topVC = [OPNavigatorHelper topMostAppControllerWithWindow:window];
    UIView *view = topVC.view;
    if ([topVC isKindOfClass:UINavigationController.class]) {
        view = ((UINavigationController *)topVC).topViewController.view ?: topVC.view;
    }
    return view;
}

@end

