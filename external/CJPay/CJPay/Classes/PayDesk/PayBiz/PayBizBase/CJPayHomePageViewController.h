//
//  CJPayHomePageViewController.h
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import <UIKit/UIKit.h>
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayOrderResultResponse.h"
#import "CJPayEnumUtil.h"
#import "CJPayHomeBaseContentView.h"
#import "CJPayCountDownTimerView.h"

@class CJPaySubPayTypeIconTipModel;
NS_ASSUME_NONNULL_BEGIN
@protocol CJPayIntegratedCashierHomeVCProtocol <CJPayBaseLoadingProtocol>

- (void)updateOrderResponse:(CJPayCreateOrderResponse *)response;
- (void)notifyNotsufficient:(NSString *)bankCardId;
- (void)closeDesk;
- (void)enableConfirmBtn:(BOOL) enable;
//回归这里的逻辑
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayOrderStatus)orderStatus;
- (void)invalidateCountDownView; //关闭定时器

@optional
- (NSDictionary *)trackerParams;

@end

@protocol CJChangePayMethodDelegate <NSObject>

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *_Nonnull)defaultModel;

@optional
- (void)bindCard:(CJPayDefaultChannelShowConfig *)bindCardConfig;
- (void)closeDesk;
- (void)combinePayWithType:(CJPayChannelType)type;

@end

@class CJPayIntegratedCashierProcessManager;
@class CJPayBizChoosePayMethodViewController;

@interface CJPayHomePageViewController : CJPayHalfPageBaseViewController <CJPayHomeContentViewDelegate, CJPayMethodTableViewDelegate, CJChangePayMethodDelegate>

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         response:(CJPayCreateOrderResponse *)response
                  completionBlock:(void(^)(CJPayOrderResultResponse *_Nullable resResponse, CJPayOrderStatus orderStatus)) completionBlock;

@property (nonatomic, strong, readonly) NSMutableArray *notSufficientFundIds;
@property (nonatomic, strong, readonly) CJPayCreateOrderResponse *response;
@property (nonatomic, strong, readonly) CJPayCountDownTimerView *countDownView;
@property (nonatomic, strong, readonly) CJPayHomeBaseContentView *homeContentView;
@property (nonatomic, strong, readonly) CJPayDefaultChannelShowConfig *curSelectConfig;
@property (nonatomic, strong, readonly) CJPayIntegratedCashierProcessManager *processManager;  // 流程控制
@property (nonatomic, copy, readonly) NSArray *channels;
@property (nonatomic, copy, readonly) NSDictionary *commonTrackerParams; // 埋点通参
@property (nonatomic, assign) BOOL isSignAndPay; //是否是签约并支付流程
@property (nonatomic, assign) BOOL isPaymentForOuterApp; // 是否为外部 App 拉起收银台支付
@property (nonatomic, copy) NSString *outerAppName; // 拉起收银台支付的 App name
@property (nonatomic, copy) NSString *outerAppID; // 拉起收银台支付的 App id
@property (nonatomic, assign) CJPayLoadingType loadingType; //记录正在Loading的类型
@property (nonatomic, assign, readonly) BOOL isCloseFromRetain; //是否是点击挽留弹框上的放弃关闭收银台的
@property (nonatomic, copy) void(^combinePayLimitBlock)(NSDictionary *params); //组合支付触发余额受限的回调
@property (nonatomic, assign) BOOL isStandardDouPayProcess; // 是否是抖音支付标准化流程

- (CJPayHomeBaseContentView *)getCurrentContentView;
- (CJPayBizChoosePayMethodViewController *)choosePayMethodVCWithshowNotSufficentFund:(BOOL)showNotSufficentFund;
- (void)setupNavigatinBar;
- (BOOL)isSecondaryCellView:(CJPayChannelType)channelType;

- (void)gotoChooseMethodVC:(BOOL)showNotSufficentFund;
- (void)payLimitWithTipsMsg:(NSString *)tipsMsg iconTips:(CJPaySubPayTypeIconTipModel *)iconTips;
- (void)creditPayFailWithTipsMsg:(NSString *)tipsMsg disableMsg:(NSString *)disableMsg;

- (void)onConfirmPayAction;
- (void)updateSelectConfig:(nullable CJPayDefaultChannelShowConfig *)selectConfig;
- (void)changeCreditPayInstallment:(NSString *)installment;

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

@interface CJPayHomePageViewController(HomeVCProtocol)<CJPayIntegratedCashierHomeVCProtocol>

@end

NS_ASSUME_NONNULL_END
