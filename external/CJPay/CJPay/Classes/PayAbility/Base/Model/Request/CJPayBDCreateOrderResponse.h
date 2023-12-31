//
//  CJPayBDCreateOrderResponse.h
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//
#import <JSONModel/JSONModel.h>
#import "CJPayBDDeskConfig.h"
#import "CJPayMerchantInfo.h"
#import "CJPayBDTradeInfo.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayInfo.h"
#import "CJPayUserInfo.h"
#import "CJPayProcessInfo.h"
#import "CJPayBaseResponse.h"
#import "CJPayResultShowConfig.h"
#import "CJPaySkipPwdGuideInfoModel.h"
#import "CJPayBioGuideInfoModel.h"
#import "CJPayPreTradeInfo.h"
#import "CJPaySecondaryConfirmInfoModel.h"
#import "CJPaySwitchAreaInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayResultShowConfig;
@protocol CJPayMerchantInfo;
@protocol CJPayBDTradeInfo;
@protocol CJPayBDTypeInfo;
@protocol CJPayInfo;
@protocol CJPayUserInfo;
@protocol CJPayProcessInfo;
@protocol CJPayBioPaymentInfo;
@class CJPayErrorButtonInfo;
@class CJPayCustomSettings;
@class CJPayOrderConfirmResponse;
@class CJPayBDRetainInfoModel;
@class CJPayPreTradeInfo;
@class CJPayLoadingStyleInfo;
@class CJPayBalancePromotionModel;
@class CJPayLynxShowInfo;
@class CJPaySignPageInfoModel;

@interface CJPayBDCreateOrderResponse : CJPayBaseResponse

//收银台配置信息
@property (nonatomic, strong) CJPayBDDeskConfig *deskConfig;
//营销图片配置
@property (nonatomic, strong) CJPayResultShowConfig *resultConfig;
//商户信息
@property (nonatomic, strong) CJPayMerchantInfo *merchant;
//交易相关数据
@property (nonatomic, strong) CJPayBDTradeInfo *tradeInfo;
//支付渠道信息
@property (nonatomic, strong) CJPayBDTypeInfo *payTypeInfo; // 该字段在前置收银台场景下，后端不再下发，而是通过preTradeInfo进行下发。非前置场景已经会使用该字段
@property (nonatomic, strong) CJPayPreTradeInfo *preTradeInfo;
//支付打折营销信息
@property (nonatomic, strong) CJPayInfo *payInfo;
//忘记密码优化
@property (nonatomic, copy) NSDictionary *forgetPwdInfo;
//免密引导
@property (nonatomic, strong) CJPaySkipPwdGuideInfoModel *skipPwdGuideInfoModel;
//用户信息
@property (nonatomic, strong) CJPayUserInfo *userInfo;

@property (nonatomic, strong) CJPayProcessInfo *processInfo;

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@property (nonatomic, strong) CJPayUserInfoPassModel *passModel;

@property (nonatomic, copy) NSString *customSettingStr;

@property (nonatomic, assign) BOOL needResignCard;

@property (nonatomic, assign) BOOL skipNoPwdConfirm; //是否强制跳过免密确认框提示，只有在电商场景免密支付触发余额不足时返回YES

//控制免密确认弹窗样式及新样式弹窗是否展示（后端频控），
//0 老样式，1 不展示，2 展示新样式
@property (nonatomic, assign) NSInteger showNoPwdConfirm;

@property (nonatomic, assign) NSInteger showNoPwdConfirmPage; //免密频控三期改为使用此字段替换showNoPwdConfirm 0弹窗 1不展示 2半屏

@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *secondaryConfirmInfo; //半屏免密确认页

@property (nonatomic, strong) CJPayBioGuideInfoModel *preBioGuideInfo; //支付中引导生物识别

@property (nonatomic, strong) CJPaySwitchAreaInfoModel *topRightBtnInfo; //密码验证页右上角切换区信息

// 极速支付需要在下单响应中返回confirm的response
@property (nonatomic, copy) NSDictionary *tradeConfirmInfo;

// 免密支付接口合并，在下单时直接返回tradeConfirmResponse
@property (nonatomic, copy) NSDictionary *skippwdConfirmResponseDict;

@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;

@property (nonatomic, copy) NSString *nopwdPreShow; //是否免密前置，"1"免密前置、"0"不前置

//必选，发送请求的时间，发送请求的时间，长整型的时间戳，精确到秒
@property (nonatomic, copy) NSDictionary *bizParams;

@property (nonatomic, copy) NSString *intergratedTradeIdentify;
@property (nonatomic, copy) NSString *cj_merchantID;//聚合商户号

/// 是否跳过生物验证的确认支付页(电商场景下使用)
@property (nonatomic, assign) BOOL skipBioConfirmPage;

// 挽留信息（目前唤端追光使用该字段，而不是payInfo.retainInfo）
@property (nonatomic, strong) CJPayBDRetainInfoModel *retainInfo;
@property (nonatomic, copy) NSDictionary *retainInfoV2; // retainInfoV2 整个传给前端
@property (nonatomic, strong) CJPayLoadingStyleInfo *loadingStyleInfo;
@property (nonatomic, strong) CJPayLoadingStyleInfo *bindCardLoadingStyleInfo;

// 支付中签约页面信息
@property (nonatomic, strong) CJPaySignPageInfoModel *signPageInfo;

//原始传递过来的数据
@property (nonatomic, copy) NSDictionary *originGetResponse;

@property (nonatomic, strong) CJPayBalancePromotionModel *balancePromotionModel;

// 支付前lynx弹窗
@property (nonatomic, strong) CJPayLynxShowInfo *lynxShowInfo;

- (int)closeAfterTime;

- (CJPayCustomSettings *)customSetting;

// 标识免密下单接口和确认支付接口是否合并
- (BOOL)isSkippwdMerged;

@end

@interface CJPayBDCreateOrderResponse(preTradeWrapper)

@property (nonatomic, strong, readonly) CJPayPreTradeInfo *preTradeInfoWrapper;

- (CJPayDefaultChannelShowConfig *)getCardModelBy:(NSString *)bankCardId;

- (CJPayDefaultChannelShowConfig *)getPreTradeBalanceChannelShowConfig;

@end

NS_ASSUME_NONNULL_END
