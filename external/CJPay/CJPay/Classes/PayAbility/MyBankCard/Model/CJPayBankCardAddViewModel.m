//
//  CJPayBankCardAddViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardAddViewModel.h"
#import "CJPayBankCardAddCell.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayBankCardAddViewModel

- (Class)getViewClass {
    return [CJPayBankCardAddCell class];
}

- (CGFloat)getViewHeight {
    if (!Check_ValidString(self.noPwdBindCardDisplayDesc)) {
        return 60;
    }
    return 72 + [self.noPwdBindCardDisplayDesc cj_sizeWithFont:[UIFont cj_fontOfSize:12] width:CJ_SCREEN_WIDTH - 56].height;
}

@end
