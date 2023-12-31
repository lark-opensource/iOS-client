//
//  CJPayBridgePlugin_openPage.m
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import "CJPayBridgePlugin_openPage.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

#import "CJPayWebViewUtil.h"

#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_openPage

- (instancetype)init {
    self = [super init];
    if (self) {
        CJPayLogInfo(@"CJPayBridgePlugin_openPage: %p", self);
    }
    return self;
}

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_openPage, openPage), @"ttcjpay.openPage");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)openPageWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller
{
    NSDictionary *dic = (NSDictionary *)param;
    NSString *urlString = [dic cj_stringValueForKey:@"url"];
    NSString *gotoType = [dic cj_stringValueForKey:@"goto_type"];

    if (!Check_ValidString(urlString)) {
        TTBRIDGE_CALLBACK_FAILED
        return;
    }

    if ([gotoType isEqualToString:@"0"]) {
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:controller toUrl:urlString];
    } else if ([gotoType isEqualToString:@"1"]) {
        [[CJPayWebViewUtil sharedUtil] openCJScheme:urlString fromVC:controller useModal:YES];
    }

    TTBRIDGE_CALLBACK_SUCCESS
}

@end
