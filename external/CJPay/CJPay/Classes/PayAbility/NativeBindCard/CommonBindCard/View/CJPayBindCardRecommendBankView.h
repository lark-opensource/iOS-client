//
//  CJPayBindCardRecommendBankView.h
//  CJPay-CJPayDemoTools-Example
//
//  Created by chenbocheng on 2022/6/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayQuickBindCardModel;
@interface CJPayBindCardRecommendBankView : UIView

- (BOOL)isTipsShow;
- (void)updateContent:(NSArray<CJPayQuickBindCardModel *> *)recommendBanks;

@end

NS_ASSUME_NONNULL_END
