//
//  CJPayRequestParam.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import <Foundation/Foundation.h>
#import "CJPayAppInfoConfig.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayRequestParamInjectDataProtocol <NSObject>

+ (NSDictionary *)injectReskInfoData;
+ (NSDictionary *)injectDevInfoData;

@end

//请求相关参数
@interface CJPayRequestParam : NSObject

+ (void)injectDataProtocol:(Class<CJPayRequestParamInjectDataProtocol>)protocol;

+ (NSDictionary *)commonDeviceInfoDic;

+ (NSString *)uaInfoString:(NSString *)appName;

+ (NSString *)ipString;

+ (NSString *)appVersion;

+ (NSDictionary *)riskInfoDict;

+ (NSDictionary *)riskInfoDictWithFinanceRiskWithPath:(NSString *)path;

+ (NSDictionary *)getFinanceRisk:(NSString *)path;

+ (NSString *)deviceID;

// 非抖音端获取抖音支付账号标识，取不到accessToken则返回nil
+ (NSString *)accessToken;

+ (void)setAppInfoConfig:(CJPayAppInfoConfig *)appInfoConfig;

+ (CJPayAppInfoConfig *)gAppInfoConfig;

// 计算IAP的接口签名
+ (NSString *)calcuIAPSign:(NSDictionary *)dataDic appSecret:(NSString *)appSecret;

//计算 三方支付下单接口 签名
+ (NSString *)calcuBDCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret;

//计算 下单接口 签名
+ (NSString *)calcuCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret;

//计算 预下单接口 签名
+ (NSString *)calcuPreCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret;

+ (NSString *)calcuSign:(NSDictionary *)dataDict
               signKeys:(NSArray *)signKeys
              appSecret:(NSString *)appSecret;

+ (NSDictionary *)getRiskInfoParams;

+ (nonnull NSDictionary *)getRiskInfoParamsWith:(NSDictionary *)extParams;

+ (NSDictionary *)getMergeRiskInfoWithBizParams:(NSDictionary *)bizParams;

+ (BOOL)isSaasEnv; // 标识是否是SaaS链路
@end
NS_ASSUME_NONNULL_END
