//
//  CJPayDyPayController.h
//  Pods
//
//  Created by xutianxi on 2023/02/28.
//

#import <Foundation/Foundation.h>
#import "CJPayHomeVCProtocol.h"
#import "CJPayManagerDelegate.h"

@class CJPayFrontCashierContext;
@class CJPayNavigationController;

NS_ASSUME_NONNULL_BEGIN

@class CJPayDyPayVerifyManager;
@class CJPayFrontCashierContext;
@class CJPayDyPayVerifyManagerQueen;

@interface CJPayDyPayController : NSObject<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayDyPayVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, strong) CJPayDyPayVerifyManagerQueen *verifyManagerQueen;
@property (nonatomic, strong, readonly) CJPayNavigationController *navigationController;
@property (nonatomic, assign) BOOL isPayOuterMerchant; //是否是对外商户（即外部商户唤端）

- (void)startPaymentWithParams:(NSDictionary *)params
           createOrderResponse:(CJPayBDCreateOrderResponse *)response
               completionBlock:(void(^)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus))completionBlock;
- (NSString *)creditPayInstallment;

@end

NS_ASSUME_NONNULL_END
