//
//  BDPayFrontCashiedController.h
//  CJPay
//
//  Created by 王新华 on 3/11/20.
//

#import <Foundation/Foundation.h>
#import "CJPayHomeVCProtocol.h"
#import "CJPayFrontCashierManager.h"
#import "CJPayManagerDelegate.h"
#import "CJPayBalanceBaseController.h"

@class CJPayBDOrderResultResponse;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;

NS_ASSUME_NONNULL_BEGIN

@class CJPayBalanceVerifyManager;
// 前置支付的控制器，非视图
@interface CJPayBalanceRechargeController : CJPayBalanceBaseController

@property (nonatomic, strong) CJPayBalanceVerifyManager *frontCashierVerifyManager;
@property (nonatomic, strong) CJPayFrontCashierContext *payContext;

- (void)startPaymentWithContext:(CJPayFrontCashierContext *)context completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion;

@end

@interface CJPayBalanceRechargeController(HomeVCProtocol)<CJPayHomeVCProtocol>


@end

NS_ASSUME_NONNULL_END
