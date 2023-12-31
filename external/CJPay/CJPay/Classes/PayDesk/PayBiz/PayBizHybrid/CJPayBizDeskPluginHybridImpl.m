//
//  CJPayBizDeskPluginHybridImpl.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/3/20.
//

#import "CJPayBizDeskPluginHybridImpl.h"

#import "CJPayBizDeskPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayBizHybridHomePageViewController.h"

@interface CJPayBizDeskPluginHybridImpl() <CJPayBizDeskPlugin>
@end

@implementation CJPayBizDeskPluginHybridImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayBizDeskPlugin);
});

- (UIViewController *)deskVCBizParams:(NSDictionary *)bizParams bizurl:(NSString *)bizUrl response:(CJPayCreateOrderResponse *)response completionBlock:(void (^)(CJPayOrderResultResponse * _Nullable, CJPayOrderStatus))completionBlock {
    CJPayBizHybridHomePageViewController *deskVC = [[CJPayBizHybridHomePageViewController alloc] initWithBizParams:bizParams bizurl:bizUrl response:response completionBlock:completionBlock];
    return deskVC;
}

@end
