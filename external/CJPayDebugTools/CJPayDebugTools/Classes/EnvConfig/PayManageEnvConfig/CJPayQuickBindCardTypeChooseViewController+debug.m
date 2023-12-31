//
//  CJPayQuickBindCardTypeChooseViewController+debug.m
//  Pods
//
//  Created by 尚怀军 on 2021/1/25.
//

#import "CJPayQuickBindCardTypeChooseViewController+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <CJPay/CJPayCreateOneKeySignOrderResponse.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayQuickBindCardTypeChooseViewController (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"getExtralParams")
                               with:@selector(debug_getExtralParams)];
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"appendHeaderWithRequest:")
                               with:@selector(debug_appendHeaderWithRequest:)];
}

- (NSDictionary *)debug_getExtralParams {
    CJPayQuickBindCardTypeChooseViewModel *viewModel = [self p_getViewModel];
    CJPayCreateOneKeySignOrderResponse *oneKeyResponse = [self p_getOneKeyOrderResponse];
    if ([CJPayDebugManager boeIsOpen] && viewModel && oneKeyResponse) {
        NSDictionary *extraParams = @{
            @"merchant_id" : CJString(viewModel.merchantId),
            @"app_id" : CJString(viewModel.appId),
            @"sign" : CJString(oneKeyResponse.sign),
            @"member_biz_order_no" : CJString(oneKeyResponse.memberBizOrderNo)
        };
        return extraParams;
    } else {
        return [self debug_getExtralParams];
    }
}

- (void)debug_appendHeaderWithRequest:(NSMutableURLRequest *)request {
    [self debug_appendHeaderWithRequest:request];
    if ([CJPayDebugManager boeIsOpen]) {
        [CJPayDebugManager p_setBOEHeader:request];
    }
}

- (CJPayQuickBindCardTypeChooseViewModel *)p_getViewModel {
    SEL sel = NSSelectorFromString(@"viewModel");
    if (sel && [self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        CJPayQuickBindCardTypeChooseViewModel *viewModel = [self performSelector:sel];
#pragma clang diagnostic pop
        return viewModel;
    } else {
        return  nil;;
    }
}

- (CJPayCreateOneKeySignOrderResponse *)p_getOneKeyOrderResponse {
    SEL sel = NSSelectorFromString(@"oneKeyCreateOrderResponse");
    if (sel && [self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        CJPayCreateOneKeySignOrderResponse *oneKeyOrderResponse = [self performSelector:sel];
#pragma clang diagnostic pop
        return oneKeyOrderResponse;
    } else {
        return  nil;;
    }
}

@end
