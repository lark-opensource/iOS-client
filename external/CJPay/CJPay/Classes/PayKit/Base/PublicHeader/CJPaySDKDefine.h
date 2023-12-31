//
//  CJPaySDKDefine.h
//  Pods
//
//  Created by jiangzhongping on 2018/8/21.
//

NS_ASSUME_NONNULL_BEGIN

#ifndef CJPaySDKDefine_h
#define CJPaySDKDefine_h

//订单状态
typedef NS_ENUM(NSUInteger, CJPayOrderStatus) {
    CJPayOrderStatusProcess = 0,  //处理进行中
    CJPayOrderStatusSuccess = 1,  //成功
    CJPayOrderStatusFail = 2,     //失败
    CJPayOrderStatusTimeout = 3,   //超时
    CJPayOrderStatusCancel = 4,    //用户取消
    CJPayOrderStatusNull = 5,      //状态为空
    CJPayOrderStatusOrderFail = 6 //下单失败
};

typedef NS_ENUM(NSUInteger, CJPayChannelType) {
    CJPayChannelTypeNone = 0,
    CJPayChannelTypeWX = 1, // 微信支付
    CJPayChannelTypeTbPay = 2, // 支付宝
    CJPayChannelTypeQRCodePay = 3,//二维码支付
    CJPayChannelTypeBytePay, //抖音支付
    CJPayChannelTypeDyPay, // 抖音以外 App 拉起抖音支付
    CJPayChannelTypeCustom = 7, // 自定义支付渠道类型，用来处理支付宝微信H5支付跳回的问题
    CJPayChannelTypeWXH5 = 8, // 微信H5支付
    CJPayChannelTypeQuickWithdraw = 9, // 快速提现
    CJPayChannelTypeUnBindBankCard = 10, // 未绑定卡[内部使用]
    CJPayChannelTypeFrontCardList = 11, // 前置卡列表cell
    CJPayChannelTypeBDPay = 12, // 字节支付
    CJPayChannelTypeSignTbPay = 13, // 签约支付宝免密支付
    CJPayChannelTypeBannerCombinePay = 14,  //首页banner，目前只有组合支付的样式
    CJPayChannelTypeBannerVoucher = 15,  //首页banner，强推区
    CJPayChannelTypeSuperPay = 16,
    CJPayChannelTypeUnBindBankCardZone = 17,  // 特定渠道新卡分割区域
    CJPayChannelTypeSeparateLine = 18,        // 不可用和可用支付方式分割线
    
    
    BDPayChannelTypeBankCard = 100,
    BDPayChannelTypeBalance = 101,
    BDPayChannelTypeAddBankCard = 102,
    BDPayChannelTypeFrontAddBankCard = 103,
    BDPayChannelTypeCardCategory = 104,
    BDPayChannelTypeCreditPay = 105, // 信用支付
    BDPayChannelTypeIncomePay = 106, //钱包收入支付
    BDPayChannelTypeAfterUsePay = 107, //先用后付
    BDPayChannelTypeCombinePay = 108, //组合支付
    BDPayChannelTypeAddBankCardNewCustomer = 109, // 无零钱未绑卡状态下卡片样式
    BDPayChannelTypeTransferPay = 110, //大额转账
    BDPayChannelTypeFundPay = 111 // 基金支付
};

//跳转场景
typedef NS_ENUM(NSUInteger, CJPayComeFromSceneType) {
    CJPayComeFromSceneTypeBalanceRecharge, //余额充值
    CJPayComeFromSceneTypeBalanceWithdraw, //余额提现
};

//支付结果状态
typedef NS_ENUM(NSUInteger, CJPayResultType) {
    CJPayResultTypeSuccess,
    CJPayResultTypeFail,
    CJPayResultTypeBackToForeground,
    CJPayResultTypeCancel,
    CJPayResultTypeUnAvailable,
    CJPayResultTypeInstallAndUnAvailable, //安装了 版本不对，不可用
    CJPayResultTypeProcessing,
    CJPayResultTypeUnInstall             //版本未安装
};

//常量
extern NSString * const CJPayDeskThemeKey;
extern NSString * const CJPayHandleCompletionNotification;

extern NSString * const CJPayBindCardSignSuccessNotification;
extern NSString * const CJPayBindCardSuccessNotification;
extern NSString * const CJPayH5BindCardSuccessNotification;
extern NSString * const CJPayBindCardSuccessPreCloseNotification;
extern NSString * const CJCloseWithdrawHomePageVCNotifiction;
extern NSString * const CJPayCancelBindCardNotification;

extern NSString * const CJPayShowPasswordKeyBoardNotification;
extern NSString * const CJPayPassCodeChangeNotification;

extern NSString * const CJPayVerifyPageDidChangedHeightNotification;

extern NSString * const CJPayManagerReloadWithdrawDataNotification;

extern NSString * const BDPaySignSuccessAndConfirmFailNotification;
extern NSString * const BDPayMircoQuickBindCardSuccessNotification;
extern NSString * const BDPayMircoQuickBindCardFailNotification;
extern NSString * const BDPayBindCardSuccessRefreshNotification;

extern NSString * const BDPayClosePayDeskNotification;

extern NSString * const BDPayUniversalLoginSuccessNotification;

extern NSString * const CJPayUnionBindCardUnavailableNotification;

extern NSString * const CJPayBindCardSetPwdShowNotification;
extern NSString *const CJPayCardsManageSMSSignSuccessNotification;

extern NSString * const CJPayClickRetainPerformNotification;

CJPayOrderStatus CJPayOrderStatusFromString (NSString *statusSting);

typedef NSString * CJPayPropertyKey;
extern CJPayPropertyKey const CJPayPropertyPayDeskTitleKey;// 字符串类型，收银台title
extern CJPayPropertyKey const CJPayPropertyReferVCKey;// VC类型
extern CJPayPropertyKey const CJPayPropertyIsHiddenLoadingKey;// 是否隐藏loading，默认不隐藏

typedef NS_ENUM(NSInteger, CJPayScene) {
    CJPayScenePay = 0,  // Native 支付收银台
    CJPaySceneH5Pay, // H5 支付收银台
    CJPaySceneWithdraw,  // 聚合提现收银台，包括支付宝和快捷提现
    CJPaySceneBalanceWithdraw,  // 余额提现收银台
    CJPaySceneBalanceRecharge, // 余额充值收银台
    CJPaySceneEcommercePay, // 电商支付
    CJPaySceneAuth,  // 实名授权
    CJPaySceneWeb,   // Web通用场景
    CJPaySceneLynxCard, // ntv嵌套lynx卡片场景
    CJPaySceneBDPay,  // Native 三方支付收银台
    CJPaySceneBindCard,  // 独立绑卡
    CJPayScenePreStandardPay, // 前置标准收银台
    CJPaySceneOuterDyPay, // 端外追光
    CJPaySceneSign = 20, // 签约，包括抖音签约，支付宝，微信签约
    CJPaySceneParamsService = 200,//lynx交互，存取缓存参数
    CJPaySceneGeneralAbilityService = 2000, //lynx获取端上通用参数或者普通参数
    CJPaySceneLynxBindCardCallMiniApp, //Lynx绑卡里调用小程序
};

extern NSErrorDomain CJPayErrorDomain;

typedef NS_ENUM(NSInteger, CJPayErrorCode) {
//    支付和提现
    CJPayErrorCodeSuccess = 0,   // 成功
    CJPayErrorCodeProcessing,   // 处理中
    CJPayErrorCodeCancel,   // 取消
    CJPayErrorCodeFail,     // 失败
    CJPayErrorCodeUnLogin,    // 未登录
    CJPayErrorCodeOrderTimeOut, // 订单超时
    CJPayErrorCodeInsufficientBalance, //余额不足
//    通过支付进行授权
    CJPayErrorCodeAuthrized = 20, // 已授权
    CJPayErrorCodeAuthQueryError,
    CJPayErrorCodeUnnamed,  // 未实名
//    其他通用错误码
    CJPayErrorCodeUnknown = 100, // 未知错误
    CJPayErrorCodeCallFailed,
    CJPayErrorCodeHasOpeningDesk, // 有支付中的收银台
    
    CJPayErrorCodeAntiFraudCanceled = 116,
    CJPayErrorCodeBackToForground, // 应用从后台手动返回前台
    CJPayErrorCodeOrderFail,       //下单失败
    CJPayErrorCodeBizParamsError,  //业务传参错误
};

@interface CJPayAPIBaseResponse : NSObject

@property (nonatomic, assign) CJPayScene scene;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy, nullable) NSDictionary *data;

@end

@protocol CJPayAPIDelegate <NSObject>

@optional
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene;
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene params:(NSDictionary *)params;
- (void)onResponse:(CJPayAPIBaseResponse *)response;

@end

@protocol CJPayInitDelegate <NSObject>

+ (void)initCJPay;

@end

@interface CJPayAPICallBack : NSObject<CJPayAPIDelegate>

- (instancetype)initWithCallBack:(void(^)(CJPayAPIBaseResponse *))callback;

@end

#endif /* CJPaySDKDefine_h */

NS_ASSUME_NONNULL_END

