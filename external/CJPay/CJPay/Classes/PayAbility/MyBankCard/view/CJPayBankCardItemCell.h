//
//  CJPayBankCardItemCell.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBaseListCellView.h"

#import "CJPayStyleBaseListCellView.h"

@class CJPayBankCardView;
NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardItemCell : CJPayStyleBaseListCellView

@property(nonatomic, strong) CJPayBankCardView *cardView;
@property(nonatomic, strong) UIView *shadowView;
@property(nonatomic, strong) CALayer *shadowLayer;


@end

NS_ASSUME_NONNULL_END
