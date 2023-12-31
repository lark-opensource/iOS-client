//
//  CJPayBridgePlugin_sendLog.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_sendLog.h"
#import "NSDictionary+CJPay.h"
#import "CJPayABTestManager.h"
#import "CJPayUIMacro.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayTracker.h"

@implementation CJPayBridgePlugin_sendLog

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendLog, sendLog), @"ttcjpay.sendLog");
}


+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)sendLogWithParam:(NSDictionary *)data
                callback:(TTBridgeCallback)callback
                  engine:(id<TTBridgeEngine>)engine
              controller:(UIViewController *)controller
{
    NSDictionary *param = (NSDictionary *)data;
    NSString *eventName = [param cj_stringValueForKey:@"event"];
    NSDictionary *paramsDic = [param cj_dictionaryValueForKey:@"params"];
    NSMutableDictionary *trueParams = [NSMutableDictionary dictionaryWithDictionary:@{@"app_platform": @"web"}]; //h5 埋点加参数区分
    [trueParams addEntriesFromDictionary:paramsDic];
    if (Check_ValidString(eventName)) {
        NSString *experimentKey = [paramsDic cj_stringValueForKey:@"libraExperimentKey"];
        if ([eventName isEqualToString:@"exposureLibraExperiment"] &&
            Check_ValidString(experimentKey)) {
            // 前端获取实验值，在Native完成曝光
        [CJPayABTest getABTestValWithKey:experimentKey];
        } else {
            [CJTracker event:eventName params:trueParams];
        }
        TTBRIDGE_CALLBACK_SUCCESS
    } else {
        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"event为空")
    }
}

@end
