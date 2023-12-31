//
//  CJPayBridgePlugin_disableDragBack.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_disableDragBack.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayBizWebViewController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_disableDragBack

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_disableDragBack, disableDragBack), @"ttcjpay.disableDragBack");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)disableDragBackWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    if (controller && [controller isKindOfClass:[UIViewController class]] && ![controller isKindOfClass:[CJPayBizWebViewController class]] ) {
        // 非web类型的宿主容器支持开启和关闭侧滑关闭能力
        NSDictionary *dic = (NSDictionary *)param;
        if ([dic cj_intValueForKey:@"disable"] == 1) {
          controller.cjAllowTransition = NO;
        } else {
          controller.cjAllowTransition = YES;
        }
        TTBRIDGE_CALLBACK_SUCCESS
        return;
    }
    
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }

    NSDictionary *dic = (NSDictionary *)param;
    if ([dic cj_intValueForKey:@"disable"] == 1) {
        webViewController.allowsPopGesture = NO;
    } else {
        webViewController.allowsPopGesture = YES;
    }
    
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
