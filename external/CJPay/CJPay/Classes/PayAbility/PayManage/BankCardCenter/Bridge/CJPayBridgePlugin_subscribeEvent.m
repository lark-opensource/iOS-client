//
//  CJPayBridgePlugin_subscribeEvent.m
//  Aweme
//
//  Created by chenbocheng.moon on 2022/12/2.
//

#import "CJPayBridgePlugin_subscribeEvent.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayUIMacro.h"
#import "CJPayBindCardManager.h"

@implementation CJPayBridgePlugin_subscribeEvent

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_subscribeEvent, subscribeEvent), @"ttcjpay.subscribeEvent");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)subscribeEventWithParam:(NSDictionary *)param
            callback:(TTBridgeCallback)callback
              engine:(id<TTBridgeEngine>)engine
          controller:(UIViewController *)controller {
    NSArray *eventNameArray = [param cj_arrayValueForKey:@"event_name_list"];
    if ([eventNameArray containsObject:@"CJPayAddBankCardSucceedEvent"] && callback) {
        [CJPayBindCardManager sharedInstance].bindCardSuccessBlock = ^(){
            TTBRIDGE_CALLBACK_SUCCESS;
        };
    }
}

@end
