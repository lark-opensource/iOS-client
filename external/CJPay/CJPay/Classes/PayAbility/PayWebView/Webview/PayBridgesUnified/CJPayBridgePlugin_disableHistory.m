//
//  CJPayBridgePlugin_disableHistory.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_disableHistory.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>

#import "CJPayBizWebViewController.h"
#import "CJPayBizWebViewController+Biz.h"
#import "UIViewController+CJTransition.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWKWebView.h"

@implementation CJPayBridgePlugin_disableHistory

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_disableHistory, disableHistory), @"ttcjpay.disableHistory");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)disableHistoryWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    @CJWeakify(webViewController)
    webViewController.cjBackBlock = ^{
        @CJStrongify(webViewController)
        if ([webViewController.cjVCIdentify isEqualToString:@"LOGOUT_RESULT"]) {  //注销成功结果页
            webViewController.allowsPopGesture = NO;
            NSDictionary *params = @{@"type":@"click.backbutton", @"data": @""};
            [webViewController sendEvent:@"ttcjpay.receiveSDKNotification" params:params];
        } else {
            [webViewController closeWebVCWithAnimation:YES completion:^{
                CJ_CALL_BLOCK(webViewController.closeCallBack, @{@"service": @"web", @"action": @"back"});
            }];
        }
    };

    TTBRIDGE_CALLBACK_SUCCESS
}

@end
