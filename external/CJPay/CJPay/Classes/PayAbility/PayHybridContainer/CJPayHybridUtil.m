//
//  CJPayHybridUtil.m
//  CJPay
//
//  Created by RenTongtong on 2023/7/28.
//

#import "CJPayHybridUtil.h"
#import "CJPayHybridService.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayHalfPageHybridViewController.h"
#import "CJPayNavigationController.h"
#import "CJPayDeskUtil.h"
#import "CJPayUIMacro.h"

@interface CJPayHybridUtil () <CJPayHybridService>


@end

@implementation CJPayHybridUtil

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedUtil), CJPayHybridService)
})

+ (instancetype)sharedUtil {
    static CJPayHybridUtil *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayHybridUtil alloc] init];
    });
    return instance;
}

#pragma mark - CJPayHybridService

- (void)openSchema:(NSString *)schema withInfo:(NSDictionary *)sdkInfo routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate
{
    btd_dispatch_async_on_main_queue(^{
        CJPayHalfPageHybridViewController *hybridVC = [[CJPayHalfPageHybridViewController alloc] initWithSchema:schema sdkInfo:sdkInfo];
        if (routeDelegate && [routeDelegate respondsToSelector:@selector(routeToVC:animated:)]) {
            [routeDelegate routeToVC:hybridVC animated:YES];
        }
    });
}

@end
