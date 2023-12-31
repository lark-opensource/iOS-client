//
//  CJPayDYRecommendPayAgainListViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/3/24.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN


@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayChannelBizModel;
@class CJPayBDMethodTableView;
@protocol CJPayDYRecommendPayAgainListDelegate <NSObject>

- (void)didClickPayMethod:(CJPayDefaultChannelShowConfig *)payChannel;
- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

@interface CJPayDYRecommendPayAgainListViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createResponse;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *outerRecommendShowConfig;
@property (nonatomic, copy) NSArray<NSString *> *disableCardIDs;
@property (nonatomic, copy) NSDictionary *payDisabledFundID2ReasonMap;
@property (nonatomic, weak) id<CJPayDYRecommendPayAgainListDelegate> delegate;
@property (nonatomic, strong, readonly) CJPayBDMethodTableView *payMethodView;

@end

NS_ASSUME_NONNULL_END
