//
//  CJPayBridgePlugin_callHostApp.m
//  CJPay
//
//  Created by liyu on 2020/1/17.
//

#import "CJPayBridgePlugin_callHostApp.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayWebViewUtil.h"
#import "CJPayOuterBridgePluginManager.h"
#import "NSDictionary+CJPay.h"

@implementation CJPayBridgePlugin_callHostApp

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_callHostApp, callHostApp),
                            @"ttcjpay.callHostApp");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeGlobal;
}

+ (instancetype)sharedPlugin
{
    static CJPayBridgePlugin_callHostApp *sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[CJPayBridgePlugin_callHostApp alloc] init];
    });
    return sharedPlugin;
}

- (void)callHostAppWithParam:(NSDictionary *)param
                    callback:(TTBridgeCallback)callback
                      engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller
{
    NSString *method = [param cj_stringValueForKey:@"method"];
    
    if (!([method isKindOfClass:NSString.class] && [method length] > 0)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"method参数错误")
        return;
    }
    
    if ([method isEqualToString:@"logout_account"]) {
        [[CJPayWebViewUtil sharedUtil] logoutAccount];
        TTBRIDGE_CALLBACK_SUCCESS;
        return;
    }
    

    id<CJPayOuterBridgeProtocol> bridge = [CJPayOuterBridgePluginManager bridgeForMethod:method];
    if (!bridge || ![bridge respondsToSelector:@selector(didReceive:WithCallback:inViewController:)]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"宿主未注册outer bridge")
        return;
    }
    
    void (^jsCallback)(id) = ^void(id data) {
        if (data == nil) {
            TTBRIDGE_CALLBACK_FAILED_MSG(@"无数据")
            return;
        }
        
        if (callback) {
            callback(TTBridgeMsgSuccess, data, nil);
        }
    };
    [bridge didReceive:param WithCallback:jsCallback inViewController:controller];
}

@end
