//
//  CJPayBridgePlugin_getAppInfo.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/3/24.
//

#import "CJPayBridgePlugin_getAppInfo.h"
#import "CJPayRequestParam.h"

@implementation CJPayBridgePlugin_getAppInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_getAppInfo, getAppInfo), @"ttcjpay.getAppInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)getAppInfoWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    if ([CJPayRequestParam gAppInfoConfig].infoConfigBlock) {
        NSDictionary *result = [CJPayRequestParam gAppInfoConfig].infoConfigBlock();
        if (callback) {
            callback(TTBridgeMsgSuccess, result, nil);
        }
    } else {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"客户端未实现配置");
    }
}

@end
