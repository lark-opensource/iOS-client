//
//  CJPayFrontCashierResultModel.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayFrontCashierResultModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayChooseCardResultModel

@end

@implementation BDChooseCardCommonModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hasSfficientBlockBack = YES;
    }
    return self;
}

@end

@implementation CJPayFrontCashierContext

- (CJPayBDCreateOrderResponse *)orderResponse {
    return self.latestOrderResponseBlock ? self.latestOrderResponseBlock() : nil;
}

- (BOOL)isPreStandardDesk {
    NSString *cashierSceneStr = [self.extParams cj_stringValueForKey:@"cashier_scene"];
    return [cashierSceneStr isEqualToString:@"standard"];
}

- (BOOL)isNeedResultPage {
    NSString *needResultPageStr = [self.extParams cj_stringValueForKey:@"need_result_page"];
    return [needResultPageStr isEqualToString:@"1"];
}

@end

@implementation CJPayFrontCashierResultModel

@end
