//
//  CJPayPayAgainHalfViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayOrderConfirmResponse;
@class CJPayBaseVerifyManager;
@class CJPayFrontCashierContext;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayHintInfo;

@protocol CJPayPayAgainDelegate <NSObject>

- (void)payWithContext:(CJPayFrontCashierContext *)context loadingView:(UIView *)loadingView;

@end

@interface CJPayPayAgainHalfViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap;
@property (nonatomic, weak) id<CJPayPayAgainDelegate> delegate;
@property (nonatomic, copy) NSDictionary *extParams; //埋点使用
@property (nonatomic, assign) BOOL isSuperPay;

@property (nonatomic, copy) void (^dismissCompletionBlock)(CJPayDefaultChannelShowConfig *recommendConfig);

@end

NS_ASSUME_NONNULL_END
