//
//  CJPayBridgePlugin_dypay.m
//  Aweme
//
//  Created by 陈博成 on 2023/3/31.
//

#import "CJPayBridgePlugin_dypay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "NSDictionary+CJPay.h"
#import "CJPayDyPayModule.h"
#import "CJPayProtocolManager.h"
#import "CJPayAPI.h"
#import "CJPaySDKMacro.h"
#import <WebKit/WebKit.h>

@interface CJPayBridgePlugin_dypay() <CJPayAPIDelegate>

@property (nonatomic, copy) TTBridgeCallback callback;

@end

@implementation CJPayBridgePlugin_dypay

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_dypay, dypay), @"ttcjpay.dypay");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)dypayWithParam:(NSDictionary *)param
               callback:(TTBridgeCallback)callback
                 engine:(id<TTBridgeEngine>)engine
             controller:(UIViewController *)controller {
    if (!Check_ValidDictionary(param) || param.count == 0) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [self p_errorCode:CJPayErrorCodeBizParamsError], nil);
        return;
    }
    
    self.callback = callback;
    NSString *url = @"";
    if ([engine.sourceObject isKindOfClass:WKWebView.class]) {
        WKWebView *wkwebview = (WKWebView *)engine.sourceObject;
        url = wkwebview.URL.absoluteString;
    }
    
    if (!Check_ValidString(url)) {
        CJPayLogInfo(@"cannot get url");
    }
    
    NSMutableDictionary *mtbParam = [NSMutableDictionary dictionaryWithDictionary:[[param cj_stringValueForKey:@"sdk_info"] cj_toDic]];
    [mtbParam addEntriesFromDictionary:@{@"invoke_source":@"0"}];//换端来源：0-抖3端内，1-抖3端外
    [mtbParam addEntriesFromDictionary:@{@"refer_url":url}];//后台需要对url鉴权
    [mtbParam addEntriesFromDictionary:@{@"platform":@"JSAPI"}];//埋点用
    [CJPayAPI lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayDyPayModule) i_openDyPayDeskWithParams:mtbParam delegate:self];
}

#pragma mark CJPayAPIDelegate

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    CJPayErrorCode resultCode = response.error.code;
    CJ_CALL_BLOCK(self.callback, TTBridgeMsgSuccess, [self p_errorCode:resultCode], nil);
}

#pragma mark private

- (NSDictionary *)p_errorCode:(CJPayErrorCode)code {
    NSString *codeStr = @"-1";
    NSString *msg = @"未知错误";
    switch (code) {
        case CJPayErrorCodeSuccess:
            codeStr = @"0";
            msg = @"支付成功";
            break;
        case CJPayErrorCodeCancel:
            codeStr = @"1";
            msg = @"支付取消";
            break;
        case CJPayErrorCodeFail:
            codeStr = @"2";
            msg = @"支付失败，可能有多种原因";
            break;
        case CJPayErrorCodeBizParamsError:
            codeStr = @"3";
            msg = @"业务传参错误";
            break;
        case CJPayErrorCodeOrderFail:
            codeStr = @"4";
            msg = @"下单失败";
            break;
        default:
            break;
    }
    
    return @{
        @"code": codeStr,
        @"msg": msg,
        @"data": @""
       };
}

@end
