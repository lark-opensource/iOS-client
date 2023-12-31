//
//  CJPayBridgePlugin_request.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_request.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTReachability/TTReachability.h>
#import "CJPaySDKMacro.h"
#import "CJPayBizWebViewController.h"
#import "CJPayBaseRequest.h"

@implementation CJPayBridgePlugin_request

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_request, request), @"ttcjpay.request");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)requestWithParam:(NSDictionary *)data
                callback:(TTBridgeCallback)callback
                  engine:(id<TTBridgeEngine>)engine
              controller:(UIViewController *)controller
{
    NSDictionary *connectionErrorResponse =  @{@"error_code": @(-99),
                                               @"error_msg": @"Network error, please try again"};

    TTReachability *reachAbility = [TTReachability reachabilityForInternetConnection];
    if (reachAbility.currentReachabilityStatus == NotReachable) {
        CJPayLogInfo(@"jsb::request 无网，直接返回");
        if (callback) {
            callback(TTBridgeMsgSuccess, connectionErrorResponse, nil);
        }
        return;
    }
    
    NSDictionary *param = (NSDictionary *)data;
    NSString *url = [param cj_stringValueForKey:@"url"];
    NSString *method = [param cj_stringValueForKey:@"method"];
    NSDictionary *paramsDic = [param cj_dictionaryValueForKey:@"params"] ?: @{};
    NSDictionary *header = [param cj_dictionaryValueForKey:@"header"];
    NSString *dataType = [param cj_stringValueForKey:@"dataType"];
    
    CJPayRequestSerializeType requestSerializeType = CJPayRequestSerializeTypeURLEncode;
    
    if ([dataType isEqualToString:@"JSON"]) {
        requestSerializeType = CJPayRequestSerializeTypeJSON;
    }
    NSMutableDictionary *mutableHeaderDic = [NSMutableDictionary new];
    [mutableHeaderDic cj_setObject:@"H5" forKey:@"x-from"];
    [mutableHeaderDic addEntriesFromDictionary:header];
    
    if ([controller isKindOfClass:CJPayBizWebViewController.class]) {
        CJPayBizWebViewController *webVC = (CJPayBizWebViewController *)controller;
        BOOL isSaasEnv = [webVC isCaijingSaasEnv];
        // 财经容器在SaaS环境下发请求时，header里需带上accessToken
        if (isSaasEnv && ![mutableHeaderDic valueForKey:@"cj_need_access_token"]) {
            [mutableHeaderDic cj_setObject:@"1" forKey:@"cj_need_access_token"];
        }
    }
    
    [CJPayBaseRequest startRequestWithUrl:url method:method requestParams:paramsDic headerFields:[mutableHeaderDic copy] serializeType:requestSerializeType callback:^(NSError *error, id jsonObj) {
        if (error && error.code == -1001) {
            if (callback) {
                callback(TTBridgeMsgSuccess, connectionErrorResponse, nil);
            }
            return;
        }
        
        if (callback) {
            if (jsonObj) {
                callback(TTBridgeMsgSuccess, jsonObj, nil);
            } else {
                TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"response 为空")
            }
        }
    } needCommonParams:YES];
}

@end
