//
//  CJPayBankCardEmptyAddViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardEmptyAddViewModel.h"
#import "CJPayBankCardEmptyAddCell.h"
#import "CJPayUIMacro.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"

@implementation CJPayBankCardEmptyAddViewModel

- (Class)getViewClass {
    return [CJPayBankCardEmptyAddCell class];
}

- (CGFloat)getViewHeight {
    if (!Check_ValidString(self.noPwdBindCardDisplayDesc)) {
        return 132;
    }
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    CGFloat tableTopOffset = showInsuranceEntrance ? 12 : 0;
    return 134 + [self.noPwdBindCardDisplayDesc cj_sizeWithFont:[UIFont cj_fontOfSize:12] width:CJ_SCREEN_WIDTH - 32].height + tableTopOffset;
}

@end
