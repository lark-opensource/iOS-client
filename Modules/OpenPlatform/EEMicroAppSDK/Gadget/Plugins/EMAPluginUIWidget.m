//
//  EMAPluginUIWidget.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/17.
//

#import "EMAPluginUIWidget.h"
#import <OPFoundation/BDPI18n.h>
#import "EMAI18n.h"
#import <OPFoundation/EMAAlertController.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@implementation EMAPluginUIWidget

- (void)showPromptWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback context:(BDPPluginContext)context {
    /// 环境条件
    UIViewController *topVC = [OPNavigatorHelper topMostAppControllerWithWindow:context.controller.view.window];
    if (!topVC) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"Can not find a view controller to show prompt");
        return;
    }
    /// 参数处理
    NSString *title = [param bdp_stringValueForKey:@"title"];   // title为可选参数，无需判空处理
    NSString *placeholder = [param bdp_stringValueForKey:@"placeholder"];
    if (BDPIsEmptyString(placeholder)) {
        placeholder = EMAI18n.show_prompt_placeholder;
    }
    NSInteger maxLength = [param bdp_integerValueForKey:@"maxLength"];
    if (maxLength == -1) {
        maxLength = NSIntegerMax;
    }
    NSString *confirmText = [param bdp_stringValueForKey:@"confirmText"];
    if (BDPIsEmptyString(confirmText)) {
        confirmText = EMAI18n.show_prompt_ok;
    }
    NSString *cancelText = [param bdp_stringValueForKey:@"cancelText"];
    if (BDPIsEmptyString(cancelText)) {
        cancelText = BDPI18n.cancel;
    }
    /// showPrompt实现
    [self _showPromptWithTitle:title
                   placeholder:placeholder
                     maxLength:maxLength
                   confirmText:confirmText
                    cancelText:cancelText
              inViewController:topVC
                      callback:^(BOOL isConfirm, NSString *input) {
        NSMutableDictionary *ret = NSMutableDictionary.new;
        if (isConfirm) {
            [ret setValue:@(YES) forKey:@"confirm"];
            [ret setValue:@(NO) forKey:@"cancel"];
            [ret setValue:BDPIsEmptyString(input) ? @"" : input forKey:@"inputValue"];
        } else {
            [ret setValue:@(NO) forKey:@"confirm"];
            [ret setValue:@(YES) forKey:@"cancel"];
        }
        !callback ?: callback(BDPJSBridgeCallBackTypeSuccess, ret);
    }];
}

#pragma mark - private
- (void)_showPromptWithTitle:(NSString *)title
                 placeholder:(NSString *)placeholder
                   maxLength:(NSInteger)maxLength
                 confirmText:(NSString *)confirmText
                  cancelText:(NSString *)cancelText
            inViewController:(UIViewController *)viewController
                    callback:(void (^)(BOOL isConfirm, NSString *input))callback
{
    BDPLogInfo(@"showPromptWithTitle");

    UIWindow *window = viewController.view.window ?: OPWindowHelper.fincMainSceneWindow;
    
    EMAAlertControllerConfig *config = [EMAAlertControllerConfig new];
    config.alertWidth = MIN(window.bdp_width * 0.808, 303);
    config.titleAligment = NSTextAlignmentLeft;
    config.textviewEdgeInsets = UIEdgeInsetsMake(6, 0, 0, 0);
    config.textviewHeight = 128;
    config.textviewMaxLength = maxLength;
    EMAAlertController *alert = [EMAAlertController alertControllerWithTitle:title
                                                         textviewPlaceholder:placeholder
                                                              preferredStyle:UIAlertControllerStyleAlert
                                                                      config:config];
    [alert addAction:[EMAAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:^(EMAAlertAction * _Nonnull action) {
        !callback ?: callback(NO, nil);
    }]];
    [alert addAction:[EMAAlertAction actionWithTitle:confirmText style:UIAlertActionStyleDefault handler:^(EMAAlertAction * _Nonnull action) {
        !callback ?: callback(YES, alert.textview.text);
    }]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
