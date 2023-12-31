//
//  CJPayBalanceWithdrawController.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <Foundation/Foundation.h>
#import "CJPayHomeVCProtocol.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayManagerDelegate.h"
#import "CJPayBalanceBaseController.h"

@class CJPayBDOrderResultResponse;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayBalanceVerifyManager;
NS_ASSUME_NONNULL_BEGIN

@interface CJPayBalanceWithdrawController : CJPayBalanceBaseController

@property (nonatomic, strong) CJPayBalanceVerifyManager *balanceWithdrawVerifyManager;

//余额提现
- (void)startWithdrawWithContext:(CJPayFrontCashierContext *)context completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion;

@end

@interface CJPayBalanceWithdrawController(HomeVCProtocol)<CJPayHomeVCProtocol>


@end

NS_ASSUME_NONNULL_END
