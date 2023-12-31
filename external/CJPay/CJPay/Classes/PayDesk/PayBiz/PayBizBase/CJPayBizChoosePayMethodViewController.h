//
//  CJPayBizChoosePayMethodViewController.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayIntegratedCashierProcessManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayIntegratedCashierProcessManager;

@interface CJPayBizChoosePayMethodViewController : CJPayHalfPageBaseViewController<CJPayMethodTableViewDelegate>

#pragma mark - views
@property (nonatomic, strong) CJPayBytePayMethodView *payMethodView;

#pragma mark - delegte
@property (nonatomic, weak) id<CJChangePayMethodDelegate> delegate;

#pragma mark - data
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *outDefaultConfig;
@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse;
@property (nonatomic, copy) NSArray<NSString *> *notSufficientFundsIDs;
@property (nonatomic, copy) NSDictionary<NSString *,NSString *> *channelDisableReason; //渠道不可用原因
@property (nonatomic, copy) NSString *creditPayInstallment;

#pragma mark - flag
@property (nonatomic, assign) BOOL showNotSufficientFundsHeaderLabel;
@property (nonatomic, assign) BOOL isShowDetentionAlert;
@property (nonatomic, strong) CJPaySubPayTypeIconTipModel *iconTips;

#pragma mark - method
- (instancetype)initWithOrderResponse:(CJPayCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                       processManager:(CJPayIntegratedCashierProcessManager *)processManager;

- (void)notifyNotsufficient:(NSString *)bankCardId;
- (void)updateNotSufficientFundsViewTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
