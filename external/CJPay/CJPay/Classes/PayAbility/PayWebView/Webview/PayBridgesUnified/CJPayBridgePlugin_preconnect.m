//
//  CJPayBridgePlugin_preconnect.m
//  CJPay
//
//  Created by RenTongtong on 2023/8/31.
//

#import "CJPayBridgePlugin_preconnect.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "NSDictionary+CJPay.h"
#import <TTNetworkManager/TTNetworkManager.h>

@implementation CJPayBridgePlugin_preconnect

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_preconnect, preconnect), @"ttcjpay.preconnect");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)preconnectWithParam:(NSDictionary *)data
                   callback:(TTBridgeCallback)callback
                     engine:(id<TTBridgeEngine>)engine
                 controller:(UIViewController *)controller
{
    NSArray<NSString *> *urls = [data cj_arrayValueForKey:@"urls"];
    if ([urls isKindOfClass:[NSArray class]] && urls.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([url isKindOfClass:[NSString class]]) {
                    [[TTNetworkManager shareInstance] preconnectUrl:url];
                }
            }];
        });
        TTBRIDGE_CALLBACK_SUCCESS
    } else {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"参数错误");
    }
}

@end
