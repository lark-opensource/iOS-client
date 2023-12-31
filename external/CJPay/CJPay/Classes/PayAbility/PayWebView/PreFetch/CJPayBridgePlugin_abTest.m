//
//  CJPayBridgePlugin_abTest.m
//  Pods
//
//  Created by renqiang on 2021/9/28.
//

#import "CJPayBridgePlugin_abTest.h"
#import "CJPaySDKMacro.h"
#import "CJPayABTestManager.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

@implementation CJPayBridgePlugin_abTest

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_abTest, abTest), @"ttcjpay.abTest");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)abTestWithParam:(NSDictionary *)param
               callback:(TTBridgeCallback)callback
                 engine:(id<TTBridgeEngine>)engine
             controller:(UIViewController *)controller {
    if (!(param && [param isKindOfClass:NSDictionary.class])) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code" : @"1", @"msg" : @"jsb data数据有误"}, nil);
        return;
    }
    
    NSString *abSettingKey = [param cj_stringValueForKey:@"ab_setting_key"];
    NSString *abSettingValue = nil;
    // isExposure  取值 0 | 1；0表示不曝光 1表示曝光 默认是1， nil 也曝光
    BOOL isExposure = ![[param cj_stringValueForKey:@"isExposure"] isEqualToString:@"0"];
    
    if (Check_ValidString(abSettingKey)) {
        abSettingValue = [CJPayABTest getABTestValWithKey:abSettingKey exposure:isExposure];
    } else {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code" : @"1", @"msg" : @"ab_setting_key为空"}, nil);
        return;
    }
    
    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{
        @"code" : @"0",
        @"data" : @{@"ab_setting_value" : CJString(abSettingValue)}}, nil);
}

@end
