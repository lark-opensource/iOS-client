//
//  CJPayCreditPayUtil.h
//  Pods
//
//  Created by 易培淮 on 2022/5/12.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayCreditPayServiceResultType) {
    CJPayCreditPayServiceResultTypeActivated = 0, //仅激活情况下使用
    CJPayCreditPayServiceResultTypeNoUrl = 1, //缺少Url
    CJPayCreditPayServiceResultTypeNoNetwork = 2, //无网
    CJPayCreditPayServiceResultTypeSuccess = 3, //成功
    CJPayCreditPayServiceResultTypeFail = 4, //失败
    CJPayCreditPayServiceResultTypeCancel = 5, //取消
    CJPayCreditPayServiceResultTypeTimeOut = 6, //超时
    CJPayCreditPayServiceResultTypeNotEnoughQuota = 7 //激活成功额度不足
};

typedef NS_ENUM(NSInteger, CJPayCreditPayActivationLoadingStyle) {
    CJPayCreditPayActivationLoadingStyleOld = 0,
    CJPayCreditPayActivationLoadingStyleNew = 1,
};

@class CJPayInfo;

@interface CJPayCreditPayUtil : NSObject

+ (void)activateCreditPayWithPayInfo:(CJPayInfo *)payInfo completion:(void(^)(CJPayCreditPayServiceResultType type, NSString *msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString *token))completion;

+ (void)activateCreditPayWithStatus:(BOOL)activateStatus
                        activateUrl:(NSString *)activateUrl
                         completion:(void(^)(CJPayCreditPayServiceResultType type, NSString *msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString *token))completion;

+ (void)doCreditTargetActionWithPayInfo:(CJPayInfo *)payInfo completion:(void(^)(CJPayCreditPayServiceResultType type, NSString *msg, NSString *payToken))completion;

// 封装月付激活与月付解锁流程
+ (void)creditPayActiveWithPayInfo:(CJPayInfo *)payInfo completion:(void(^)(CJPayCreditPayServiceResultType type, NSString *msg, NSString *payToken))completion;

@end

NS_ASSUME_NONNULL_END
