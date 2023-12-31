//
//  CJPayFrontCardListViewController.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/12.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayNotSufficientFundsView;
@class BDChooseCardCommonModel;
@interface CJPayFrontCardListViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong, readonly) CJPayNotSufficientFundsView *notSufficientFundsView;

+ (void)showVCWithCommonModel:(BDChooseCardCommonModel *)cardCommonModel;

- (instancetype)initWithCardCommonModel:(BDChooseCardCommonModel *)cardCommonModel;

@end

NS_ASSUME_NONNULL_END
