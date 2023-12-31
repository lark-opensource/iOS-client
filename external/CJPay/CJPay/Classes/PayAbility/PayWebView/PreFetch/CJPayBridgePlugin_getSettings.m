//
//  CJPayBridgePlugin_getSettings.m
//  Pods
//
//  Created by xutianxi on 2022/08/15.
//

#import "CJPayBridgePlugin_getSettings.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayPrivateServiceHeader.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayCardOCRService.h"
#import "CJPayBioPaymentPlugin.h"

@implementation CJPayBridgePlugin_getSettings

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_getSettings, getSettings), @"ttcjpay.getSettings");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)getSettingsWithParam:(NSDictionary *)param
                    callback:(TTBridgeCallback)callback
                      engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller {
    NSDictionary *dict = [[CJPaySettingsManager shared].settingsDict copy] ?:@{};
    
    NSMutableDictionary *pluginsDic = [NSMutableDictionary new];
    [pluginsDic cj_setObject:CJ_OBJECT_WITH_PROTOCOL(CJPayCardOCRService) ? @"1" : @"0" forKey:@"ocr"];
    [pluginsDic cj_setObject:CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol) ? @"1" : @"0" forKey:@"face_verify"];
    [pluginsDic cj_setObject:CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) ? @"1" : @"0" forKey:@"biopayment"];
    
    if (!dict || dict.count <= 0) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code" : @"1",
                                                     @"msg" : @"settings 数据为空",
                                                     @"data" : @{},
                                                     @"plugins": pluginsDic,
                                                   }, nil);
        return;
    } else {
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{
            @"code" : @"0",
            @"data" : dict,
            @"plugins": pluginsDic,
        }, nil);
    }
}

@end
