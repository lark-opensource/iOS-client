//
//  CJPayHomeVCProtocol.h
//  CJPay
//
//  Created by 王新华 on 7/18/19.
//

#import "CJPayStateView.h"
#import "CJPayLoadingManager.h"
#import "CJPayVerifyManagerHeader.h"

#ifndef CJPayHomeVCProtocol_h
#define CJPayHomeVCProtocol_h

typedef NS_ENUM(NSUInteger, CJPayHomeVCEvent) {
    CJPayHomeVCEventAddToContentView = 100,
    CJPayHomeVCEventShowState,
    CJPayHomeVCEventInvalidateCountDownView,
    CJPayHomeVCEventUpdateConfirmBtnTitle,
    CJPayHomeVCEventUpdateStateStyle,
    CJPayHomeVCEventDismissAllAboveVCs,
    CJPayHomeVCEventEnableConfirmBtn,
    CJPayHomeVCEventFreezeConfirmBtn,
    CJPayHomeVCEventNotifySufficient,
    CJPayHomeVCEventCombinePayLimit, //组合支付余额受限
    CJPayHomeVCEventPayLimit, //普通支付余额受限
    CJPayHomeVCEventQueryOrderSuccess,
    CJPayHomeVCEventHandleButtonInfo,
    CJPayHomeVCEventSignAndPayFailed,
    CJPayHomeVCEventGotoCardList,
    CJPayHomeVCEventClosePayDesk, // 关闭收银台，通知电商收银台关闭使用
    CJPayHomeVCEventConfirmRequestError, //确认支付失败
    CJPayHomeVCEventUserCancelRiskVerify, //用户取消风控验证
    CJPayHomeVCEventOccurUnHandleConfirmError, // 触发了风控流程无法处理的未知错误
    CJPayHomeVCEventRefreshTradeCreate, // 收银台刷新新建订单
    CJPayHomeVCEventPayMethodDisabled, //支付方式不可用
    CJPayHomeVCEventSignCardFailed, //补签约失败
    CJPayHomeVCEventRecommendPayAgain, //推荐二次支付，目前只用于追光收银台
    CJPayHomeVCEventBindCardSuccessPayFail, //绑卡成功支付失败
    CJPayHomeVCEventDiscountNotAvailable,//优惠不可用
    CJPayHomeVCEventSuperBindCardFinish,//极速付二次支付绑卡完成
    CJPayHomeVCEventBindCardPay, //绑卡支付
    CJPayHomeVCEventBindCardNoPwdCancel, //已绑卡未设密取消
    CJPayHomeVCEventCancelVerify, // 用户取消验证【抖音支付标准化】
    CJPayHomeVCEventWakeItemFail, // 拉起验证item失败【抖音支付标准化】
    CJPayHomeVCEventBindCardFailed, //绑卡失败，包含取消
};

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;

typedef NS_ENUM(NSUInteger, CJPayHomeVCCloseActionSource) {
    CJPayHomeVCCloseActionSourceFromQuery,
    CJPayHomeVCCloseActionSourceFromBack,
    CJPayHomeVCCloseActionSourceFromUnLogin,
    CJPayHomeVCCloseActionSourceFromCloseAction,
    CJPayHomeVCCloseActionSourceFromUploadIDCard,
    CJPayHomeVCCloseActionSourceFromInsufficientBalance,
    CJPayHomeVCCloseActionSourceFromRequestError, //接口报错回调
    CJPayHomeVCCloseActionSourceFromBindAndPayFail,
    CJPayHomeVCCloseActionSourceFromOrderTimeOut,
    CJPayHomeVCCloseActionSourceFromClosePayDeskShowBizError
};

@protocol CJVerifyModulePageFlowProtocol <NSObject>

// 多少秒后关闭收银台，time小于等于0 立即关闭
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource) source;

@end

@protocol CJPayHomeVCProtocol<CJVerifyModulePageFlowProtocol,CJPayBaseLoadingProtocol>

- (nullable CJPayBDCreateOrderResponse *)createOrderResponse;
- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig;

- (CJPayVerifyType)firstVerifyType;

// 数据总线，verifyManager 像 HomePageVC通信
- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object;

- (void)push:(UIViewController *)vc animated:(BOOL) animated;

// 依赖收银台统一管理topVC
- (UIViewController *)topVC;

- (void)endVerifyWithResultResponse:(nullable CJPayBDOrderResultResponse *)resultResponse;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayHomeVCProtocol_h */
