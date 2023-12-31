//
//  CJPayBankCardNoCardTipViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayBankCardNoCardTipViewModel.h"
#import "CJPayBankCardNoCardTipCell.h"

@implementation CJPayBankCardNoCardTipViewModel

- (Class)getViewClass {
    return [CJPayBankCardNoCardTipCell class];
}

- (CGFloat)getViewHeight {
    return 78;
}

@end
