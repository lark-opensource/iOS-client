//
//  CJPayBridgePlugin_openAppByScheme.m
//  CJPay
//
//  Created by liyu on 2020/7/28.
//

#import "CJPayBridgePlugin_openAppByScheme.h"

#import "CJPayBizWebViewController.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayPrivacyMethodUtil.h"
#import "CJPayBridgeBlockRegister.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_openAppByScheme

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    //BPEA跨端改造，使用block方式注册"ttcjpay.openAppByScheme"的jsb
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.openAppByScheme"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginOpenAppByScheme = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginOpenAppByScheme isKindOfClass:CJPayBridgePlugin_openAppByScheme.class]) {
            [(CJPayBridgePlugin_openAppByScheme *)pluginOpenAppByScheme openAppBySchemeWithParam:params callback:callback engine:engine controller:controller command:command];
        } else {
            TTBRIDGE_CALLBACK_FAILED_MSG(@"参数错误");
        }
    }];

}

- (void)openAppBySchemeWithParam:(NSDictionary *)param
                        callback:(TTBridgeCallback)callback
                          engine:(id<TTBridgeEngine>)engine
                      controller:(UIViewController *)controller
                         command:(TTBridgeCommand *)command {

    NSString *appScheme = param[@"app_scheme"];
    if ([appScheme length] == 0) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"参数错误")
        return;
    }
    
    NSURL *url = [NSURL URLWithString:appScheme];
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"app scheme无法打开")
        return;
    }
        
    // 调用AppJump敏感方法，需走BPEA鉴权
    [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                    withPolicy:@"bpea-caijing_jsb_goto_app_by_scheme"
                                 bridgeCommand:command
                                       options:@{}
                             completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        if (error) {
            CJPayLogError(@"error in bpea-caijing_jsb_goto_app_by_scheme");
            TTBRIDGE_CALLBACK_FAILED_MSG(@"无跳转App权限")
            return;
        }
        if (success) {
            TTBRIDGE_CALLBACK_SUCCESS
        } else {
            TTBRIDGE_CALLBACK_FAILED_MSG(@"open url错误")
        }
    }];
    

}

@end
