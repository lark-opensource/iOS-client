//
//  CJPayBridgePlugin_ttpay.m
//  Pods
//
//  Created by 王新华 on 2020/11/21.
//

#import "CJPayBridgePlugin_ttpay.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayPrivateServiceHeader.h"
#import "CJPayUIMacro.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayAPI.h"

@interface CJPayBridgePlugin_ttpay()<CJPayAPIDelegate>

@property (nonatomic, copy) TTBridgeCallback bridgeCallback;
@property (nonatomic, weak) UIViewController *webVC;

@end

@implementation CJPayBridgePlugin_ttpay

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_ttpay, ttpay), @"ttcjpay.ttpay");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)ttpayWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    self.webVC = controller;
    self.bridgeCallback = [callback copy];
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"当前不包含 统一 吊起支付SDK能力");
        return;
    }
    [CJPayAPI lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_openUniversalPayDeskWithParams:param referVC:controller withDelegate:self];
}

#pragma mark - apiDelegate
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (!success && self.bridgeCallback) {
        self.bridgeCallback(TTBridgeMsgSuccess, @{@"code": @(105), @"msg": @"吊起通用能力失败", @"data": @""}, ^(NSString * _Nonnull result) {
        });
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if (self.bridgeCallback) {
        self.bridgeCallback(TTBridgeMsgSuccess, [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_processCallbackDataWithResponse:response], nil);
    }
}

@end
