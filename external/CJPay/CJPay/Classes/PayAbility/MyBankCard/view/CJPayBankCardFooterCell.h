//
//  CJPayBankCardFooterCell.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/29.
//

#import "CJPayStyleBaseListCellView.h"
#import "CJPayButton.h"
#import "CJPayAccountInsuranceTipView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardFooterCell : CJPayStyleBaseListCellView

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property(nonatomic,strong) CJPayButton *qaButton;

@end

NS_ASSUME_NONNULL_END
