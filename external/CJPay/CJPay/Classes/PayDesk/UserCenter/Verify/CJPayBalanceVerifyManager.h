//
//  CJPayBalanceVerifyManager.h
//  Pods
//
//  Created by wangxiaohong on 2021/12/6.
//

#import "CJPayBaseVerifyManager.h"
#import "CJPayFrontCashierManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayBalanceVerifyType) {
    CJPayBalanceVerifyTypeRecharge = 0,
    CJPayBalanceVerifyTypeWithdraw
};

@interface CJPayBalanceVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, assign) CJPayBalanceVerifyType balanceVerifyType;

@property (nonatomic, strong) CJPayFrontCashierContext *payContext;

@end

NS_ASSUME_NONNULL_END
