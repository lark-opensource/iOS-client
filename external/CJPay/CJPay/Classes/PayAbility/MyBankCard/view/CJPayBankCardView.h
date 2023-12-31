//
//  CJPayBankCardView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class CJPayBankCardModel;
@interface CJPayBankCardView : UIView

- (void)updateCardView:(CJPayBankCardModel *)model;
- (void)hideSendSMSLabel;

@end

NS_ASSUME_NONNULL_END
