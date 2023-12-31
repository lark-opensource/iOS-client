//
//  CJPayPayAgainViewModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPaySecondPayShowStyle) {
    CJPaySecondPayNoneStyle = 0,//线上样式
    CJPaySecondPayRecSimpleStyle = 1,//二次支付精简样式
};

@class CJPayQueryPayTypeRequest;
@class CJPayPayAgainTradeCreateRequest;
@class CJPayIntegratedChannelModel;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayHintInfo;
@class CJPayCreateOrderResponse;
@class CJPayOrderConfirmResponse;
@class CJPayFrontCashierContext;


@interface CJPayPayAgainViewModel : NSObject

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentShowConfig;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultShowConfig;
@property (nonatomic, strong, readonly) CJPayIntegratedChannelModel *cardListModel;
@property (nonatomic, strong, readonly) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, strong, readonly) CJPayFrontCashierContext *payContext;
@property (nonatomic, copy) NSDictionary *extParams;
@property (nonatomic, copy) NSString *installment;
@property (nonatomic, copy) NSDictionary *payDisabledFundID2ReasonMap; //支付方式不可用卡及其不可用原因记录

- (instancetype)initWithConfirmResponse:(CJPayOrderConfirmResponse *)confirmResponse createRespons:(CJPayBDCreateOrderResponse *)createResponse;

- (instancetype)initWithHintInfo:(CJPayHintInfo *)hintInfo;

- (void)fetchNotSufficientTradeCreateResponseWithCompletion:(nullable void(^)(BOOL))completionBlock;
- (void)fetchNotSufficientCardListResponseWithCompletion:(nullable void(^)(BOOL))completionBlock;
- (void)fetchCombinationPaymentResponseWithCompletion:(nullable void(^)(BOOL))completionBlock;

- (NSDictionary *)trackerParams;// 埋点通用参数

@end

NS_ASSUME_NONNULL_END
