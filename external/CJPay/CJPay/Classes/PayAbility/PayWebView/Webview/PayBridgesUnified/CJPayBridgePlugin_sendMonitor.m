//
//  CJPayBridgePlugin_sendMonitor.m
//  CJPay
//
//  Created by wangxinhua on 2020/6/5.
//

#import "CJPayBridgePlugin_sendMonitor.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_sendMonitor

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendMonitor, sendMonitor), @"ttcjpay.sendMonitor");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)sendMonitorWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    NSDictionary *metric = [param cj_dictionaryValueForKey:@"metric"];
    NSDictionary *category = [param cj_dictionaryValueForKey:@"category"];
    NSDictionary *extra = [param cj_dictionaryValueForKey:@"params"];
    NSString *serviceName = [param cj_stringValueForKey:@"event"];
    if (Check_ValidString(serviceName)) {
        [CJMonitor trackService:serviceName metric:metric ?: @{} category:category ?: @{} extra:extra ?: @{}];
        TTBRIDGE_CALLBACK_SUCCESS;
    } else {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"service_name is null");
    }
}

@end
