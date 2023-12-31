//
//  CJPayBridgePlugin_setTitle.m
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import "CJPayBridgePlugin_setTitle.h"

#import "CJPayBizWebViewController.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayUIMacro.h"

#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_setTitle

+ (void)registerBridge {
    TTRegisterBridgeMethod
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_setTitle, setTitle), @"ttcjpay.setTitle");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)setTitleWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    NSString *title = [self titleFromParam:param];
    [webViewController setNavTitle:title];
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (NSString *)titleFromParam:(id)param
{
    if ([param isKindOfClass:NSString.class]) {
        return param;
    }
    
    if ([param isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)param;
        NSString *title = [dict cj_stringValueForKey:@"title"] ?: @"";
        return title;
    }
    
    return @"";
}

@end
