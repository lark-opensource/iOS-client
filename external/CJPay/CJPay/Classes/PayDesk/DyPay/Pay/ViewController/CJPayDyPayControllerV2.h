//
//  CJPayDyPayControllerV2.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/14.
//

#import <Foundation/Foundation.h>
#import "CJPayHomeVCProtocol.h"
#import "CJPayManagerDelegate.h"
#import "CJPayDouPayProcessController.h"
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDyPayVerifyManager;
@class CJPayFrontCashierContext;
@class CJPayDyPayVerifyManagerQueen;

@interface CJPayDyPayControllerV2 : NSObject

@property (nonatomic, copy) void(^trackEventBlock)(NSString *event, NSDictionary *params);

- (void)startPaymentWithParams:(NSDictionary *)params
           createOrderResponse:(CJPayBDCreateOrderResponse *)response
            isPayOuterMerchant:(BOOL)isPayOuterMerchant
               completionBlock:(void(^)(CJPayErrorCode resultCode, NSString *msg))completionBlock;

- (void)startSignPaymentWithParams:(NSDictionary *)params
               createOrderResponse:(CJPayBDCreateOrderResponse *)response
                   completionBlock:(nonnull void (^)(CJPayErrorCode errorCode, NSString * _Nonnull msg))completionBlock;

@end

NS_ASSUME_NONNULL_END
