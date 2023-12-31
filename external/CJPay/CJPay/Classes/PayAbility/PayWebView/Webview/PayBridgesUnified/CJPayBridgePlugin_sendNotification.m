//
//  CJPayBridgePlugin_sendNotification.m
//  CJPay
//
//  Created by liyu on 2020/1/16.
//

#import "CJPayBridgePlugin_sendNotification.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayBizWebViewController+H5Notification.h"

@implementation CJPayBridgePlugin_sendNotification

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_sendNotification, sendNotification), @"ttcjpay.sendNotification");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)sendNotificationWithParam:(NSDictionary *)data
                         callback:(TTBridgeCallback)callback
                           engine:(id<TTBridgeEngine>)engine
                       controller:(UIViewController *)controller
{
    if (data == nil || ![data isKindOfClass:NSDictionary.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"data 错误");
        return;
    }
    [NSNotificationCenter.defaultCenter postNotificationName:kH5CommunicationNotification object:data];
    TTBRIDGE_CALLBACK_SUCCESS;
}

@end
