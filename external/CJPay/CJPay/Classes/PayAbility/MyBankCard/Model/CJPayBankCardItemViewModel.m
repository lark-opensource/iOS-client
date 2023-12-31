//
//  CJPayBankCardItemViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardItemViewModel.h"
#import "CJPayBankCardModel.h"
#import "CJPayBankCardItemCell.h"

@implementation CJPayBankCardItemViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.canJumpCardDetail = YES;
    }
    return self;
}

- (Class)getViewClass {
    return [CJPayBankCardItemCell class];
}

- (CGFloat)getViewHeight {
    return self.isSmallStyle ? 92 : 126;
}

- (CJPayBankCardModel *)cardModel {
    if (!_cardModel) {
         _cardModel = [CJPayBankCardModel new];
    }
    return _cardModel;
}

@end
