//
//  CJPayBridgePlugin_copyToClipboard.m
//  Aweme
//
//  Created by ByteDance on 2023/6/28.
//

#import "CJPayBridgePlugin_copyToClipboard.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPaySDKMacro.h"

#import "CJPayPrivacyMethodUtil.h"
#import "CJPayBridgeBlockRegister.h"

@implementation CJPayBridgePlugin_copyToClipboard

+ (void)registerBridge {
    TTRegisterBridgeMethod
    
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.copyToClipboard"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginCopyToClipboard = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginCopyToClipboard isKindOfClass:CJPayBridgePlugin_copyToClipboard.class]) {
            [(CJPayBridgePlugin_copyToClipboard *)pluginCopyToClipboard copyToClipboardWithParam:params callback:callback engine:engine controller:controller command:command];
        } else {
            TTBRIDGE_CALLBACK_FAILED_MSG(@"参数错误");
        }
    }];
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}


- (void)copyToClipboardWithParam:(NSDictionary *)params
                        callback:(TTBridgeCallback)callback
                          engine:(id<TTBridgeEngine>)engine
                      controller:(UIViewController *)controller
                         command:(TTBridgeCommand *)command{
    NSString *copyStr = [params cj_stringValueForKey:@"text"]?:@"";
    if (copyStr.length == 0) {
        callback(TTBridgeMsgFailed, @{ @"code": @0, @"msg" : @"参数格式错误"}, nil);
        return;
    }
    [CJPayPrivacyMethodUtil pasteboardSetString:copyStr withPolicy:@"bpea-caijing_jsb_copy_to_clipboard" bridgeCommand:command completionBlock:^(NSError * _Nullable error) {
        if (error) {
            CJPayLogError(@"error in bpea-caijing_jsb_copy_to_clipboard");
            callback(TTBridgeMsgFailed, @{ @"code": @0, @"msg" : @"没有剪贴板访问权限"}, nil);
            return;
        }
        callback(TTBridgeMsgSuccess, @{ @"code": @1, @"msg" : @"成功"}, nil);
        return;
    }];
    
}

@end
