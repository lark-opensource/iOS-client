//
//  CJPayBridgePlugin_sendPageStatus.m
//  Pods
//
//  Created by 尚怀军 on 2021/8/13.
//

#import "CJPayBridgePlugin_sendPageStatus.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "CJPayBizWebViewController+WebviewMonitor.h"

@implementation CJPayBridgePlugin_sendPageStatus

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendPageStatus, sendPageStatus), @"ttcjpay.sendPageStatus");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)sendPageStatusWithParam:(NSDictionary *)param
                       callback:(TTBridgeCallback)callback
                         engine:(id<TTBridgeEngine>)engine
                     controller:(UIViewController *)controller {
    
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    NSDictionary *dic = (NSDictionary *)param;
    NSInteger code = [dic cj_integerValueForKey:@"code"];
    NSString *urlStr = [dic cj_stringValueForKey:@"url"];
    NSString *errorMsg = [dic cj_stringValueForKey:@"err_msg"];
    
    if (!Check_ValidString(urlStr)) {
        TTBRIDGE_CALLBACK_FAILED
        return;
    }
    
    if (![NSURL URLWithString:urlStr]) {
        TTBRIDGE_CALLBACK_FAILED
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    [CJMonitor trackService:@"wallet_rd_webview_page_status"
                     metric:@{}
                   category:@{@"code": @(code), @"path": CJString(url.path)}
                      extra:@{@"url": CJString(urlStr), @"error_msg": CJString(errorMsg)}];
    [webViewController.pageStatusDic cj_setObject:@(YES) forKey:CJString(url.path)];
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
