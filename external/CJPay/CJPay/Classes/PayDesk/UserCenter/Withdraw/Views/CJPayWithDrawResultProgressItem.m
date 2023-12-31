//
//  CJWithdrawResultProgressItem.m
//  CJPay
//
//  Created by liyu on 2019/10/15.
//

#import "CJPayWithDrawResultProgressItem.h"

@implementation CJPayWithDrawResultProgressItem

- (instancetype)initWithTitle:(NSString *)title
                      isFirst:(BOOL)isFirst
                       isLast:(BOOL)isLast {
    self = [super init];
    if (self) {
        _titleText = title;
        _isFirst = isFirst;
        _isLast = isLast;
    }
    return self;
}

@end

