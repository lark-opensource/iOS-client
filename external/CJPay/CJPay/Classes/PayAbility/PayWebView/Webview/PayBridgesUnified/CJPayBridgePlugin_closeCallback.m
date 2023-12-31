//
//  CJPayBridgePlugin_closeCallback.m
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import "CJPayBridgePlugin_closeCallback.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController.h"
#import "CJPayWebViewUtil.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayProtocolManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_closeCallback

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_closeCallback, closeCallback), @"ttcjpay.closeCallback");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)closeCallbackWithParam:(NSDictionary *)data
                      callback:(TTBridgeCallback)callback
                        engine:(id<TTBridgeEngine>)engine
                    controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)data;
    NSString *serviceStr = [dic cj_stringValueForKey:@"service"];
    if ([serviceStr isEqualToString:@"98"] || [serviceStr isEqualToString:@"only_callback"]) {
        NSString *callBackId = [dic cj_stringValueForKey:@"callback_id"];
        CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
        response.scene = CJPaySceneWeb;
        response.data = data;
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_callBackWithCallBackId:callBackId
                                                                               response:response];
        return;
    }
    
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }

    int disabelAnimation = [dic cj_intValueForKey:@"disable_animation"];
    BOOL animation = disabelAnimation != 1 ? YES : NO;
    
    if ([[dic cj_stringValueForKey:@"service"] isEqualToString:@"100"]) {
        // 把webview的返回值传出去供其他处理
        if (webViewController.closeCallBack) {
            webViewController.closeCallBack(data);
        }
    } else {
        NSString *service = [dic cj_stringValueForKey:@"service"];
        if (!Check_ValidString(service)) {
            NSArray *vcs = controller.navigationController.viewControllers;
            if (vcs && vcs.count > 0) {
                if ([vcs.firstObject isKindOfClass:CJPayBizWebViewController.class]) {
                    [controller.navigationController dismissViewControllerAnimated:animation completion:nil];
                } else {
                    __block UIViewController *popToVC = vcs.firstObject;
                    [vcs enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:[CJPayBizWebViewController class]]) {
                            *stop = YES;
                        } else {
                            popToVC = obj;
                        }
                    }];
                    [controller.navigationController popToViewController:popToVC animated:animation];
                }
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBizNeedCloseAllWebVC
                                                                    object:nil
                                                                  userInfo:@{@"source": @"ttcjpay.closeCallback"}];
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBizPreCloseCallbackNoti object:data];
            [webViewController closeWebVCWithAnimation:animation completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBizCloseCallbackNoti object:data];
                // 把webview的返回值传出去供其他处理
                if (webViewController.closeCallBack) {
                    webViewController.closeCallBack(data);
                }
            }];
        }
    }
    TTBRIDGE_CALLBACK_SUCCESS;
}

@end
