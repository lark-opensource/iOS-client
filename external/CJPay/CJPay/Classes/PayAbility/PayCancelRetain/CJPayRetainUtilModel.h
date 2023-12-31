//
//  CJPayRetainUtilModel.h
//  Pods
//
//  Created by youerwei on 2022/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayRetainPositionType){
    CJPayRetainHomePage = 1,
    CJPayRetainVerifyPage,
    CJPayRetainBiopaymentPage,
    CJPayRetainSkipPwdPage
};

typedef NS_ENUM(NSUInteger, CJPayRetainType) {
    CJPayRetainTypeBonus = 1,
    CJPayRetainTypeText,
    CJPayRetainTypeDefault
};

typedef NS_ENUM(NSUInteger, CJPayLynxRetainEventType) { //lynx挽留弹窗 与 ntv的交互事件
    CJPayLynxRetainEventTypeOnConfirm = 1, // 点击确认 或 继续
    CJPayLynxRetainEventTypeOnCancel, // 点击取消
    CJPayLynxRetainEventTypeOnCancelAndLeave, // 点击「X」
    //验证流程挽留弹窗
    CJPayLynxRetainEventTypeOnChangePayType, // 切换支付方式的时候会用到
    CJPayLynxRetainEventTypeOnOtherVerify, // 切换其他的验证方式
    CJPayLynxRetainEventTypeOnReinputPwd, // 重新输入密码
    //标准收银台挽留弹窗
    CJPayLynxRetainEventTypeOnPay, // 相当于点击确认支付
    CJPayLynxRetainEventTypeOnSelectPay, // 相当于切换想要切换的支付方式 （可配置是否支付）
};

typedef NS_ENUM(NSUInteger, CJPayChannelType);

@class CJPayBDRetainInfoModel;
@class CJPayRetainInfoV2Config;
@protocol CJPayTrackerProtocol;
@interface CJPayRetainUtilModel : NSObject

@property (nonatomic, strong) CJPayBDRetainInfoModel *retainInfo;
@property (nonatomic, strong) CJPayRetainInfoV2Config *retainInfoV2Config;
@property (nonatomic, copy) NSString *intergratedTradeNo;
@property (nonatomic, copy) NSDictionary *processInfoDic;
@property (nonatomic, copy) NSString *intergratedMerchantID;
@property (nonatomic, assign) BOOL isHasVoucher;
@property (nonatomic, assign) CJPayRetainPositionType positionType;
@property (nonatomic, assign) BOOL isBonusPath;
@property (nonatomic, assign) BOOL isTransform;
@property (nonatomic, assign) BOOL isUseClearBGColor; //是否无蒙层退出挽留弹框
@property (nonatomic, assign) BOOL notSumbitServerEvent; //是否不上报收银台挽留计数
@property (nonatomic, assign) BOOL hasInputHistory; //是否输入过密码
@property (nonatomic, assign) BOOL isOnlyShowNormalRetainStyle; // 是否仅展示无营销挽留弹窗

@property (nonatomic, copy) void(^confirmActionBlock)(void);
@property (nonatomic, copy) void(^otherVerifyActionBlock)(void);
@property (nonatomic, copy) void(^closeActionBlock)(void);

@property (nonatomic, copy) void(^lynxRetainActionBlock)(CJPayLynxRetainEventType eventType, NSDictionary *data);

@property (nonatomic, assign, readonly) CJPayRetainType retainType;
// 埋点
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;
// button点击事件名
@property (nonatomic, copy) NSString *eventNameForPopUpClick;
// 弹窗展现事件名
@property (nonatomic, copy) NSString *eventNameForPopUpShow;
// 各点击事件额外埋点参数
@property (nonatomic, copy) NSDictionary *extraParamForConfirm;
@property (nonatomic, copy) NSDictionary *extraParamForOtherVerify;
@property (nonatomic, copy) NSDictionary *extraParamForClose;
@property (nonatomic, copy) NSDictionary *extraParamForPopUpShow;

- (void)buildTrackEventNormalSetting;
- (CJPayLynxRetainEventType)obtainEventType:(NSString *)eventName;
- (CJPayChannelType)recommendChannelType:(NSString *)payTypeStr;
@end

NS_ASSUME_NONNULL_END
