//
//  CJPayDYRecommendPayAgainViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/3/23.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHintInfo;
@class CJPayDefaultChannelShowConfig;
@class CJPayBDCreateOrderResponse;
@class CJPayDYVerifyManager;

@protocol CJPayDYRecommendPayAgainDelegate <NSObject>

- (void)payWithChannel:(CJPayDefaultChannelShowConfig *)payChannel;
- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

@interface CJPayDYRecommendPayAgainViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createResponse;
@property (nonatomic, strong) CJPayDYVerifyManager *verifyManager;
@property (nonatomic, weak) id<CJPayDYRecommendPayAgainDelegate> delegate;
@property (nonatomic, copy) NSDictionary *payDisabledFundID2ReasonMap; //支付方式不可用及其原因

- (void)bindCardSuccessAndPayFailedWithData:(id)data;

@end

NS_ASSUME_NONNULL_END
