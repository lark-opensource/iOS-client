//
//  CJPayBridgePlugin_setVisible.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_setVisible.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayBizWebViewController.h"

@implementation CJPayBridgePlugin_setVisible

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_setVisible, setVisible), @"ttcjpay.setVisible");
    // 对H5的bridge也需要注册，不然鉴权不过
    TTRegisterAllBridge(@"", @"ttcjpay.visible");
    TTRegisterAllBridge(@"", @"ttcjpay.invisible");
}

- (void)setVisibleWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    webViewController.shouldNotifyH5LifeCycle = YES;
    
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
