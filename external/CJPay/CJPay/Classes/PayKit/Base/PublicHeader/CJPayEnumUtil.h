//
//  CJPayEnumUtil.h
//  Pods
//
//  Created by 易培淮 on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayLoadingType) {
    CJPayLoadingTypeConfirmBtnLoading = 0,
    CJPayLoadingTypeMethodCellLoading = 1,
    CJPayLoadingTypeNullLoading       = 2,
    CJPayLoadingTypeTopLoading        = 3,   //全屏Loading
    CJPayLoadingTypeDouyinLoading     = 4,   //抖音支付全屏Loading
    CJPayLoadingTypeHalfLoading       = 5,   //半屏Loading
    CJPayLoadingTypeDouyinHalfLoading = 6,   //半屏抖音Loading
    CJPayLoadingTypeSuperPayLoading   = 7,   //极速付Loading
    CJPayLoadingTypeDouyinOpenDeskLoading = 8,  //唤端支付开屏Loading
    CJPayLoadingTypeDouyinStyleLoading = 9,  //抖音全屏安全感Loading
    CJPayLoadingTypeDouyinStyleHalfLoading = 10, //抖音半屏安全感Loading
    CJPayLoadingTypeDouyinFailLoading = 11, //抖音月付失败Loading
    CJPayLoadingTypeDouyinStyleBindCardLoading = 12 //绑卡loading
};

typedef NS_ENUM(NSInteger, CJPayClickButtonType) {
    CJPayClickButtonConfirm = 1,
    CJPayClickButtonUsePWD = 2,
    CJPayClickButtonCancel = 3,
};

typedef NS_ENUM(NSInteger, CJPayVoucherType) {
    CJPayVoucherTypeNone = 0, // 无营销
    CJPayVoucherTypeImmediatelyDiscount = 1, //立减营销
    CJPayVoucherTypeRandomDiscount = 2, //随机立减
    CJPayVoucherTypeFreeCharge = 3, //免手续费
    CJPayVoucherTypeChargeDiscount = 4, //手续费打折
    CJPayVoucherTypeChargeNoDiscount = 5, //手续费不打折
    CJPayVoucherTypeBankCardImmediatelyDiscount = 6, //银行卡立减
    CJPayVoucherTypeBankCardOtherDiscount = 7, //银行卡无立减有营销
    CJPayVoucherTypeStagingWithDiscount = 8,//手续费不打折+立减
    CJPayVoucherTypeStagingWithRandomDiscount = 9,//手续费不打折+随机立减
    CJPayVoucherTypeNonePayAfterUse = 10, //先用后付文案展示
};

typedef NS_ENUM(NSInteger, CJPayDeskType) {
    CJPayDeskTypeBytePay = 6,  //品牌升级的收银台，支持组合支付
    CJPayDeskTypeBytePayHybrid = 7,  //品牌升级的收银台，首页为native+lynx形式
};

typedef NS_ENUM(NSInteger, CJPayRiskMsgType) {
    CJPayRiskMsgTypeInit = 0, //SDK初始化
    CJPayRiskMsgTypeOpenCashdesk = 1,    //拉起收银台
    CJPayRiskMsgTypeConfirmPay = 2, //确认支付
    CJPayRiskMsgTypeConfirmWithDraw = 3, //点击确认提现按钮
    CJPayRiskMsgTypeTwoElementsValidation = 4,  //二要素验证
    CJPayRiskMsgTypeTwoElementsFastSign = 5, //新二要素验证
    CJPayRiskMsgTypeRiskSignSMSCheckRequest = 6, //下发签约短信验证
    CJPayRiskMsgTypeRiskFastSignRequest = 7, //一键绑卡同意协议并继续
    CJPayRiskMsgTypeRiskSetPayPWDRequest = 8, //第二遍设置支付密码请求
    CJPayRiskMsgTypeForgetPayPWDRequest = 9, //忘记密码
    CJPayRiskMsgTypeRiskUserVerifyResult = 10, //风控加验
    CJPayRiskMsgTypeUnionPayAuthRequest = 11, //云闪付授权页面点击同意协议并继续
    CJPayRiskMsgTypeUnionPayCardListRequest = 12, //进入云闪付选择卡列表
    CJPayRiskMsgTypeInitAgain = 13, // 30s后初始化操作
};

typedef NS_ENUM(NSUInteger, CJPayVCLifeType) {
    CJPayVCLifeTypeWillAppear,
    CJPayVCLifeTypeDidAppear,
    CJPayVCLifeTypeDidDisappear,
};

typedef NS_ENUM(NSInteger, CJPayViewType) {
    CJPayViewTypeNormal = 0, //普通样式
    CJPayViewTypeDenoise = 1, // 降噪样式
    CJPayViewTypeDenoiseV2 = 2 // 验密页降噪二期
};

typedef NS_ENUM(NSUInteger, CJPaySuperPayResultType) {
    CJPaySuperPayResultTypeSuccess,
    CJPaySuperPayResultTypeFail,
    CJPaySuperPayResultTypeProcessing,
    CJPaySuperPayResultTypeTimeOut
};

typedef NS_ENUM(NSInteger, CJPayLoadingQueryState) {
    CJPayLoadingQueryStateSuccess = 0,
    CJPayLoadingQueryStateFail,
    CJPayLoadingQueryStateTimeout,
    CJPayLoadingQueryStateProcessing,
};

// 支付方式类型
typedef NS_ENUM(NSInteger, CJPayPayMethodType) {
    CJPayPayMethodTypeUnknown = 0, //未知类型，兜底
    CJPayPayMethodTypePaymentTool = 1, //支付工具（老卡、新卡、零钱等）
    CJPayPayMethodTypeFinanceChannel = 2,//资金渠道（抖音月付）
};

@protocol CJPayBaseLoadingProtocol <NSObject>

- (void)startLoading;
- (void)stopLoading;

@optional
- (void)stopLoadingWithState:(CJPayLoadingQueryState)state;

@end

NS_ASSUME_NONNULL_END
