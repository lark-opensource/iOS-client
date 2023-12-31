//
//  CJPayPayAgainPopUpViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayPayAgainHalfViewController.h"
#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayOrderConfirmResponse;
@class CJPayBaseVerifyManager;
@class CJPayFrontCashierContext;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@interface CJPayPayAgainPopUpViewController : CJPayPopUpBaseViewController <CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *createResponse;
@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;

@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap;
@property (nonatomic, weak) id<CJPayPayAgainDelegate> delegate;
@property (nonatomic, copy) NSDictionary *extParams; //埋点使用

@property (nonatomic, copy) void (^dismissCompletionBlock)(CJPayDefaultChannelShowConfig *recommendConfig);


@end

NS_ASSUME_NONNULL_END
