//
//  CJPayDyPayVerifyManager.h
//  Pods
//
//  Created by 利国卿 on 2022/9/19.
//

#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayDefaultChannelShowConfig;
@class CJPayFrontCashierContext;

@interface CJPayDyPayVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, assign) BOOL isPayAgainRecommend; //是否是推荐二次支付验证流程
@property (nonatomic, assign) BOOL isPayOuterMerchant; //是否是对外商户（即外部商户唤端）
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *bindcardConfig;
@property (nonatomic, strong) CJPayFrontCashierContext *payContext;

@end

NS_ASSUME_NONNULL_END
