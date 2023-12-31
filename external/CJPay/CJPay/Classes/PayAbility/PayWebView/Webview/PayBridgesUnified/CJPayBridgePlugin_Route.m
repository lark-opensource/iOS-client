//
//  CJPayBridgePlugin_Route.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_Route.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "UIViewController+CJTransition.h"
#import "CJPayBizWebViewController+ThemeAdaption.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebviewStyle.h"

@implementation CJPayBridgePlugin_Route

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_Route, setWebviewInfo), @"ttcjpay.setWebviewInfo");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_Route, closeWebview), @"ttcjpay.closeWebview");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_Route, goH5), @"ttcjpay.goH5");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)goH5WithParam:(NSDictionary *)param
             callback:(TTBridgeCallback)callback
               engine:(id<TTBridgeEngine>)engine
           controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    NSDictionary *dic = (NSDictionary *)param;
    NSString *url = [dic cj_stringValueForKey:@"url"];
    CJPayBizWebViewController *vc = [[CJPayBizWebViewController alloc] initWithUrlString:url];
    [vc.webviewStyle amendByDic:dic];
    vc.closeCallBack = [webViewController.closeCallBack copy];

    if (webViewController.navigationController) {
        [webViewController.navigationController pushViewController:vc animated:YES];
    } else {
        [webViewController presentViewController:vc animated:NO completion:nil];
    }
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (void)setWebviewInfoWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)param;
    NSString *webIdentify = [dic cj_stringValueForKey:@"id"];
    controller.cjVCIdentify = webIdentify;
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (void)closeWebviewWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)param;
    NSArray<NSString *> *closeWebIdentifys = [dic cj_arrayValueForKey:@"id"];
    if ([self removeAllWebVCWith:closeWebIdentifys fromVC:controller]) {
        TTBRIDGE_CALLBACK_SUCCESS
    } else {
        TTBRIDGE_CALLBACK_FAILED
    }
}

- (BOOL)removeAllWebVCWith:(NSArray<NSString *> *)ids fromVC:(UIViewController *)curVC {
    UINavigationController *nav = curVC.navigationController;
    if (!nav) {
        return NO;
    }
    NSArray<UIViewController *> *vcs = nav.viewControllers;
    if (vcs.count <= 1 || ids.count < 1) {
        return NO;
    }
    NSMutableArray *newVCs = [NSMutableArray new];
    [vcs enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *curWebVCId = obj.cjVCIdentify;
        BOOL shouldRemove = Check_ValidString(curWebVCId) && [ids containsObject:curWebVCId];
        if (!shouldRemove) {
            [newVCs btd_addObject:obj];
        } else {
            [self p_setCloseType:obj type:@"nav_close"];
        }
    }];
    if (newVCs.count < 1) {
        [newVCs btd_addObject:curVC];
        [self p_setCloseType:curVC type:@""];//不关闭了，重置回去
        
    }
    nav.viewControllers = [newVCs copy];
    return newVCs.count != vcs.count;
}

- (void)p_setCloseType:(UIViewController *)controller type:(NSString *)type{
    if ([controller isKindOfClass:CJPayBizWebViewController.class]) {
        CJPayBizWebViewController *vc = (CJPayBizWebViewController *)controller;
        vc.pageCloseType = type;
    }
}

@end
