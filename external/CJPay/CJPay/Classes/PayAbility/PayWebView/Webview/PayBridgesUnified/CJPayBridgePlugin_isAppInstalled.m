//
//  CJPayBridgePlugin_isAppInstalled.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_isAppInstalled.h"
#import "NSDictionary+CJPay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>

@implementation CJPayBridgePlugin_isAppInstalled

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_isAppInstalled, isAppInstalled), @"ttcjpay.isAppInstalled");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)isAppInstalledWithParam:(NSDictionary *)data
                       callback:(TTBridgeCallback)callback
                         engine:(id<TTBridgeEngine>)engine
                     controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)data;
    NSString *url = [dic cj_stringValueForKey:@"open_url"];
    if (url && url.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]];
            if (callback) {
                callback(TTBridgeMsgSuccess, @{@"installed": isInstalled ? @"1" : @"0"}, nil);
            }
        });
    } else {
        if (callback) {
            callback(TTBridgeMsgSuccess, @{@"installed": @"0"}, nil);
        }
    }
}

@end
