//
//  CJPayBridgePlugin_ showToast.m
//  CJPay
//
//  Created by 王新华 on 3/2/20.
//

#import "CJPayBridgePlugin_showToast.h"
#import "CJPayUIMacro.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"

@implementation CJPayBridgePlugin_showToast

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_showToast, showToast),
                            @"ttcjpay.showToast");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)showToastWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    [CJToast toastText:[param cj_stringValueForKey:@"message"] inWindow:self.engine.sourceController.cj_window];
    TTBRIDGE_CALLBACK_SUCCESS;
}

@end
