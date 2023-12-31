//
//  CJPayBindCardFirstStepCardTipView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import <UIKit/UIKit.h>
#import "CJPayBindCardNumberView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardFirstStepCardTipView : UIView

// 卡bin成功，更新银行卡信息
- (void)updateWithBankInfoModel:(CJPayMemBankInfoModel *)infoModel;
// 卡bin失败，更新
- (void)updateTips:(NSString *)tipsText;
- (void)updateTips:(NSString *)tipsText withColor:(UIColor *)color;

// tips位置展示营销信息
- (void)updateTipsWithSupportListResponse:(CJPayMemBankSupportListResponse *)response;
// tips 显示银行卡信息+营销信息
- (void)updateCardTipsWithQuickBindCardModel:(CJPayQuickBindCardModel *)quickBindCardModel;
- (BOOL)isShowContent;

@end

NS_ASSUME_NONNULL_END
