//
//  CJPayBindCardSharedDataModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/3.
//

#import <Foundation/Foundation.h>
#import "CJPayBindCardResultModel.h"
#import "CJPayCardManageModule.h"
#import "CJPayUnionBindCardCommonModel.h"
#import "CJPayBindCardCachedIdentityInfoModel.h"
#import <JSONModel/JSONModel.h>
#import "CJPayBDCreateOrderResponse+BindCardModel.h"

/**
 * model相关属性解释
 * appId:                    财经侧分配给业务方的应用id
 * merchantId:               财经侧分配给业务方的商户号
 * specialMerchantId         财经侧分配给业务方的特约商户号
 * cardBindSource:           绑卡来源
 * userInfo:                 用户信息
 * outerClose:               控制绑卡的页面是不是由外边关闭
 * useNavVC:                 设置绑卡过程的导航栈
 * firstStepMainTitle:       绑卡第一步页面的主标题 支持外部传入，不传入则走默认title
 * processInfo:              收银台下单接口返回，收银台s下单时需要带改参数
 * channelConfig:            带激活卡的信息
 * isActiveBankCard:         区分是不是激活存量卡过程
 * completion:               绑卡完成后的回调
 * dismissLoadingBlock:  给调用层的时机点，标志可以消掉loading态
 *
**/

/**
    字段分类：
    1. 定制 UI : 页面 title、营销
    2. 接口需要
    3. 埋点需求
    4. 绑卡流程内部传参
 */

NS_ASSUME_NONNULL_BEGIN
@class CJPayUserInfo;
@class CJPayDefaultChannelShowConfig;
@class CJPayProcessInfo;
@class CJPayQuickBindCardModel;
@class CJPayMemCreateBizOrderResponse;
@class CJPayBizAuthInfoModel;
@class CJPayVoucherInfoModel;
@class CJPayBindCardTitleInfoModel;
@class CJPayBindPageInfoResponse;
@class CJPayBindCardRetainInfo;

typedef void(^ CJPayBindCardCompletionType)(CJPayBindCardResultModel *resModel);
typedef void(^ CJPayBindCardDismissLoadingBlockType)(void);

// 独立绑卡流程
typedef NS_ENUM(NSUInteger, CJPayIndependentBindCardType) {
    // 默认无营销
    CJPayIndependentBindCardTypeDefault,
    // native绑卡带营销
    CJPayIndependentBindCardTypeNative,
    // lynx绑卡带营销
    CJPayIndependentBindCardTypeLynx
};

// 实名授权流程
typedef NS_ENUM(NSUInteger, CJPayBizAuthType) {
    // 默认
    CJPayBizAuthTypeDefault,
    // 静默实名授权
    CJPayBizAuthTypeSilent,
};

//云闪付流程类型
typedef NS_ENUM(NSInteger, CJPayBindUnionCardType) {
    CJPayBindUnionCardTypeDefault,     // 默认,无效，占位用
    CJPayBindUnionCardTypeBindAndSign, //绑卡并签约
    CJPayBindUnionCardTypeSyncBind,    //只绑卡不签约
    CJPayBindUnionCardTypeSignCard,        //只签约
};

//云闪付绑卡来源
typedef NS_ENUM(NSInteger, CJPayBindUnionCardSourceType) {
    CJPayBindUnionCardSourceTypeNative,                 // 默认native
    CJPayBindUnionCardSourceTypeLynxCardList,           // lynx卡列表
    CJPayBindUnionCardSourceTypeLynxBindCardFirstPage,  // lynx绑卡首页
};

// 一键绑卡优化实验
typedef NS_ENUM(NSInteger, CJPayOneKeyCardOptimizeExperiment) {
    CJPayOneKeyCardOptimizeWithoutExperiment,
    CJPayOneKeyCardOptimizeExperiment1,       // 实验1
    CJPayOneKeyCardOptimizeExperiment2        // 实验2
};

//Lynx绑卡
typedef NS_ENUM(NSUInteger, CJPayLynxBindCardBizScence) {
    CJPayLynxBindCardBizScenceDefault,
    CJPayLynxBindCardBizScenceBalanceRecharge,      //零钱充值
    CJPayLynxBindCardBizScenceBalanceWithdraw,      //零钱提现
    CJPayLynxBindCardBizScenceBdpayCashier,         //追光收银台：IM红包
    CJPayLynxBindCardBizScenceTTPayOnlyBind,        //TTPay独立绑卡
    CJPayLynxBindCardBizScenceIntegratedCashier,    //聚合收银台：话费充值、生活缴费
    CJPayLynxBindCardBizScencePreStandardPay,       //标准前置收银台：本地生活、抖音月付还款
    CJPayLynxBindCardBizScenceQuickPay,             //独立支付绑卡
    CJPayLynxBindCardBizScenceECCashier,            //电商收银台
    CJPayLynxBindCardBizScenceECLargePay,            //电商大额支付
    CJPayLynxBindCardBizScenceRechargeBindCardAndPay,  //绑卡并充值
    CJPayLynxBindCardBizScenceWithdrawBindCardAndPay, //绑卡并提现
    CJPayLynxBindCardBizScenceOuterDypay,             //换端追光O项目
    CJPayLynxBindCardBizScenceSignPay,                //签约代扣
    CJPayLynxBindCardBizScenceSignPayDetail           //签约代扣详情页
};

@interface CJPayBindCardSharedDataModel : JSONModel

// 外部传入参数控制绑卡流程
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *jhAppId;
@property (nonatomic, copy) NSString *jhMerchantId;

@property (nonatomic, weak, nullable) UIViewController *referVC; // 主要用于弹出 toast 和开启新的导航栏, iPad 分屏需要

@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, strong) CJPayProcessInfo *processInfo; // 设置密码页请求接口使用、埋点使用
@property (nonatomic, copy, nullable) CJPayBindCardCompletionType completion; // 绑卡完成结束回调
@property (nonatomic, copy, nullable) CJPayBindCardDismissLoadingBlockType dismissLoadingBlock; // 只使用了一次

// 定制 UI
@property (nonatomic, copy) NSString *firstStepBackgroundImageURL; // 普通绑卡背景图
@property (nonatomic, copy) NSString *firstStepMainTitle; // 普通绑卡首页使用字段
// 验证密码时使用, card add 接口传过来的
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
// UI:普通绑卡首页和二级页展示使用
@property (nonatomic, copy) NSString *voucherMsgStr;
@property (nonatomic, copy) NSString *voucherBankStr;
// UI:绑卡流程前传递过来的，跨页面传数据使用
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *orderInfo; //收银台跳转一键绑卡需要的订单提交成功标识
@property (nonatomic, copy) NSString *orderAmount; //收银台跳转一键绑卡需要的订单金额显示
@property (nonatomic, copy) NSString *iconURL; //收银台跳转一键绑卡需要的订单提交成功标识

// auth:
@property (nonatomic, assign) BOOL isCertification; //是否同意实名引导的授权
@property (nonatomic, assign) BOOL isBizAuthVCShown; // 支付客户端一个绑卡流程中，是否展示过业务方授权半屏页
// 新增绑卡 type: 一键绑卡、普通绑卡、云闪付绑卡
@property (nonatomic, assign) BOOL isQuickBindCard; //是否是一键绑卡, 在银行卡列表页和绑卡首页点击时，修改值
@property (nonatomic, assign) BOOL isQuickBindCardListHidden; // 从二要素实名页跳转到一级绑卡页，不展示一键绑卡列表, 不应该放在这里
@property (nonatomic, copy) NSString* jumpQuickBindCard; // 绑卡列表转化， 判断是否直接进入一键绑卡
@property (nonatomic, strong) CJPayQuickBindCardModel *quickBindCardModel; // 一键绑卡时 model
@property (nonatomic, strong) CJPayMemCreateBizOrderResponse *memCreatOrderResponse; // 实名授权弹框
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfoModel; //（绑卡并下单的card_add接口也会返回该字段，删除可能有影响）

// request API use
@property (nonatomic, copy) NSDictionary *bindCardInfo; // 绑卡流程外部传入参数, 请求接口使用

// 通过下单接口返回的ulURLParams解析出具体参数用于绑卡流程
@property (nonatomic, copy) NSString *specialMerchantId; // 请求接口使用
@property (nonatomic, strong) CJPayUserInfo *userInfo; // 用户信息，是否已实名, 是否需要引导，手机号, 设置密码等
@property (nonatomic, copy) NSString *bankMobileNoMask;
@property (nonatomic, copy) NSString *signOrderNo; // 埋点，请求接口使用
// 绑卡下单接口新增参数skip_pwd，skip_pwd = "1"，表示可以跳过密码验证
@property (nonatomic, copy) NSString *skipPwd;
// 绑卡结果页链接
@property (nonatomic, copy) NSString *endPageUrl;
@property (nonatomic, assign) CJPayBindUnionCardSourceType bindUnionCardSourceType ; //云闪付绑卡来源
@property (nonatomic, assign) BOOL isBindUnionCardNeedLoading; //云闪付下单是否需要loading
@property (nonatomic, assign) BOOL isSyncUnionCard; //云闪付同步绑卡，而非绑卡并签约，用于一键绑卡处确认云闪付绑卡类型
@property (nonatomic, assign) CJPayBindUnionCardType bindUnionCardType; //云闪付绑卡流程类型
@property (nonatomic, strong) CJPayUnionBindCardCommonModel *unionBindCardCommonModel;
@property (nonatomic, assign) BOOL isEcommerceAddBankCardAndPay; //是否是电商收银台绑卡并支付

// ABTest & libra
@property (nonatomic, assign) CJPayIndependentBindCardType independentBindCardType;
// 实名授权实验
@property (nonatomic, copy) NSString *bizAuthExperiment;
@property (nonatomic, assign) CJPayBizAuthType bizAuthType;
// 一键绑卡优化实验值
@property (nonatomic, copy) NSString *jumpOneKeySignOptimizeExp;

// tracker
@property (nonatomic, copy) NSDictionary *trackerParams; //绑卡全流程埋点
@property (nonatomic, copy) NSDictionary *trackInfo;
@property (nonatomic, copy) NSString *frontIndependentBindCardSource; //前置独立绑卡来源，埋点需要
@property (nonatomic, assign) NSTimeInterval startTimestamp; // 启动绑卡流程的时间戳，用于统计进入绑卡首页的耗时
@property (nonatomic, assign) NSTimeInterval firstStepVCTimestamp; // 普通绑卡流程，一级绑卡页面开始时间戳

@property (nonatomic, assign) BOOL dismissProcessAnimated; // 绑卡流程结束dismiss是否有动画
@property (nonatomic, strong) CJPayBindPageInfoResponse *bankListResponse;
@property (nonatomic ,strong) CJPayBindCardRetainInfo *retainInfo; //下单接口返回的挽留信息，card_add和create_biz_order
@property (nonatomic, assign) BOOL isHadShowRetain;
@property (nonatomic, strong) CJPayBindCardCachedIdentityInfoModel *cachedIdentityModel;
@property (nonatomic, assign) CJPayLynxBindCardBizScence lynxBindCardBizScence;

@property (nonatomic, assign) BOOL isSaasScene; // 标识是否处于SaaS环境
@end

@interface CJPayBindCardSharedDataModel ()
// 以下参数不对外暴露
@property (nonatomic, weak, nullable) UINavigationController *useNavVC;
@end

NS_ASSUME_NONNULL_END
