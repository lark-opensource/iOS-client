//
//  CJPayBridgePlugin_prefetchData.m
//  CJPay
//
//  Created by wangxinhua on 2020/5/13.
//

#import "CJPayBridgePlugin_prefetchData.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController.h"
#import "CJPayDataPrefetcher.h"

@implementation CJPayBridgePlugin_prefetchData

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_prefetchData, prefetchData), @"ttcjpay.prefetchData");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)prefetchDataWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    if (![controller isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"web容器不属于CJPay，无法获取到数据");
        return;
    }
    CJPayBizWebViewController *webvc = (CJPayBizWebViewController *)controller;
    [webvc.dataPrefetcher fetchData:^(id response, NSError *error) {
        NSDictionary *connectionErrorResponse =  @{@"error_code": @(-99),
        @"error_msg": @"Network error, please try again"};
        if (error && error.code == -1001) {
            if (callback) {
                callback(TTBridgeMsgSuccess, connectionErrorResponse, nil);
            }
            return;
        }

        if (callback) {
            if (response) {
                callback(TTBridgeMsgSuccess, response, nil);
            } else {
                TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"response 为空")
            }
        }
    }];
}

@end
