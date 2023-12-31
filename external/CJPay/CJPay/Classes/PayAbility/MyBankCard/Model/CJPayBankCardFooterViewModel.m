//
//  CJPayBankCardFooterViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/29.
//

#import "CJPayBankCardFooterViewModel.h"
#import "CJPayBankCardFooterCell.h"
#import "CJPayUIMacro.h"

@implementation CJPayBankCardFooterViewModel

- (Class)getViewClass {
    return [CJPayBankCardFooterCell class];
}

- (CGFloat)getViewHeight {
    return _cellHeight;
}

@end
