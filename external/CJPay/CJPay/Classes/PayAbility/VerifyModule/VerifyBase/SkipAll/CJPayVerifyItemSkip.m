//
//  CJPayVerifyItemSkip.m
//  Pods
//
//  Created by liutianyi on 2022/2/28.
//

#import "CJPayVerifyItemSkip.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"

@implementation CJPayVerifyItemSkip

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_startConfirmRequest];
}

- (void)p_startConfirmRequest {
    [self.manager submitConfimRequest:@{@"req_type":@"10"}
                       fromVerifyItem:self];
}

- (NSString *)checkType {
    return @"5";
}

@end
