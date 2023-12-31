//
//  CJPayBalanceResultPromotionView.h
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBalanceResultPromotionModel;

@interface CJPayBalanceResultPromotionView : UIView

- (void)updateWithPromotionModel:(CJPayBalanceResultPromotionModel *)promotionModel;

@end

NS_ASSUME_NONNULL_END
