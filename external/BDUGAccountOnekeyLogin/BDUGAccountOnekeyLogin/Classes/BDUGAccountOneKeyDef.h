//
//  BDUGAccountOneKeyDef.h
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/7/31.
//

#ifndef BDUGAccountOneKeyDef_h
#define BDUGAccountOneKeyDef_h

FOUNDATION_EXPORT NSString *_Nonnull const BDUGAccountErrorDomain;

FOUNDATION_EXPORT NSString *_Nonnull const BDUGAccountOnekeyMobile;
FOUNDATION_EXPORT NSString *_Nonnull const BDUGAccountOnekeyTelecom;
FOUNDATION_EXPORT NSString *_Nonnull const BDUGAccountOnekeyTelecomV2;
FOUNDATION_EXPORT NSString *_Nonnull const BDUGAccountOnekeyUnion;

typedef NS_OPTIONS(NSInteger, BDUGAccountIfAddrsStatus) {
    BDUGAccountIfAddrsStatusNone = 1,
    BDUGAccountIfAddrsStatusWithWWAN = BDUGAccountIfAddrsStatusNone << 1,
    BDUGAccountIfAddrsStatusWithWIFI = BDUGAccountIfAddrsStatusNone << 2
};

typedef NS_ENUM(NSUInteger, BDUGAccountNetworkType) {
    BDUGAccountNetworkTypeNoNet,           // 无网络
    BDUGAccountNetworkTypeDataFlow,        // 数据流量
    BDUGAccountNetworkTypeWifi,            // wifi
    BDUGAccountNetworkTypeDataFlowAndWifi, // 数据流量+wifi
    BDUGAccountNetworkTypeUnknown          // 未知
};

typedef NS_ENUM(NSUInteger, BDUGAccountCarrierType) {
    BDUGAccountCarrierTypeUnknown,
    BDUGAccountCarrierTypeMobile,
    BDUGAccountCarrierTypeUnicom,
    BDUGAccountCarrierTypeTelecom,
};

typedef NS_ENUM(NSUInteger, BDUGAccountErrorType) {
    BDUGOnekeyLoginErrorUnknown = -1,           /// 未知错误
    BDUGOnekeyLoginErrorNotSuport = -2,         /// 当前运营商不支持
    BDUGOnekeyLoginErrorSettingClose = -5,      /// 当前运营商开关关闭
    BDUGOnekeyLoginErrorNeedData = -6,          /// 取号时需要数据网络，数据网络没有打开
    BDUGOnekeyLoginErrorRequestTimeOut = -8,    /// 请求超时
    BDUGOnekeyLoginErrorThirdSDKException = -9, /// 三方运营商SDK 返回数据异常
};

#endif /* BDUGAccountOneKeyDef_h */
