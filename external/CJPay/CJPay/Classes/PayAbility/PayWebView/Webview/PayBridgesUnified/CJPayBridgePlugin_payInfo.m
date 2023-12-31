//
//  CJPayBridgePlugin_payInfo.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_payInfo.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBinaryAdapter.h"


@implementation CJPayBridgePlugin_payInfo

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_payInfo, payInfo), @"ttcjpay.payInfo");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)payInfoWithParam:(NSDictionary *)param
                callback:(TTBridgeCallback)callback
                  engine:(id<TTBridgeEngine>)engine
              controller:(UIViewController *)controller
{
    NSDictionary *processInfo = [NSDictionary new];
    id<CJPayHomeBizAdapterDelegate> delegate = [CJPayBinaryAdapter shared].confirmPresenterDelegate;
    if (delegate && [delegate respondsToSelector:@selector(getPayInfoDic)]) {
        processInfo = [delegate getPayInfoDic];
    }
    
    if (callback) {
        callback(TTBridgeMsgSuccess, processInfo, nil);
    }
}

@end
