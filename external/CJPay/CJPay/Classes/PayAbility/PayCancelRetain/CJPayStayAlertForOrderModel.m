//
//  CJPayStayAlertForOrderModel.m
//  Pods
//
//  Created by bytedance on 2021/5/14.
//

#import "CJPayStayAlertForOrderModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayStayAlertForOrderModel

- (instancetype)initWithTradeNo:(NSString *)tradeNo
{
    self = [super init];
    if (self) {
        _tradeNo = tradeNo;
        _shouldShow = YES;
        _hasShow = NO;
    }
    return self;
}

- (BOOL)shouldShowWithIdentifer:(NSString *)identifer
{
    if (!identifer || identifer.length < 1) {
        return NO;
    }
    if (![self.tradeNo isEqualToString:identifer]) {
        return YES;
    }
    return self.shouldShow == YES && self.hasShow == NO;
}

- (BOOL)isSkipPwdDowngradeWithTradeNo:(NSString *)tradeNo {
    if (!Check_ValidString(tradeNo)) {
        return NO;
    }
    return [self.skipPwdDowngradeTradeNo isEqualToString:tradeNo];
}

@end
