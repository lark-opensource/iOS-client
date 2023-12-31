//
//  CJPayBioManager.h
//  BDPay
//
//  Created by 王新华 on 2019/1/21.
//  Modified by 易培淮 on 2020/7/20

#import <Foundation/Foundation.h>
#import "CJPayMemberEnableBioPayRequest.h"
#import "CJPayBioPaymentCheckRequest.h"
#import "CJPayBioPaymentCloseRequest.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayCashdeskEnableBioPayRequest.h"

typedef NS_ENUM(NSInteger, CJPayBioOpenState) {
    CJPayBioStateBioCheckSuccess = 0,
    CJPayBioStateBioCheckFailure = 1,
};

typedef NS_ENUM(NSInteger, CJPayBioCheckState) {
    CJPayBioCheckStateOpen = 0,
    CJPayBioCheckStateClose = 1,
    CJPayBioCheckStateWithoutToken = 2, // 客户端内没有Token文件  所以关闭状态
    CJPayBioCheckStateUnknown = 3, // 可能原因请求失败  端上没法判断服务端指纹支付的状态
};

typedef NS_ENUM(NSInteger, CJPayBioCloseState) {
    CJPayBioCloseStateSuccess = 0,
    CJPayBioCloseStateFailure = 1,
};

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseViewController;

@interface CJPayBioManager : NSObject

+ (BOOL)isValidWithUid:(NSString *)uid;

/**
 读取保存的token 文件

 @return bizRequestModel
 */
+ (nullable CJPayBioSafeModel *)getSafeModelBy:(CJPayBioPaymentBaseRequestModel *)Model;

/**
 保存Token文件

 @param tokenStr 服务端返回的token字符串
 */
+ (void)saveTokenStrInKey:(NSString *)tokenStr uid:(NSString *)uid;
/**
 创建动态口令

 @param tokenData data
 @param dateCorrect 时间戳校准
 @param digits 几位，目前支持6位和8位
 @param period 步长
 @return 指定位数的动态口令
 */
+ (NSString *)generatorTOTPToken:(NSData *)tokenData dateCorrect:(NSTimeInterval) dateCorrect digits:(NSUInteger) digits period: (NSInteger) period;

// 检查是否开通指纹支付了
+ (void)checkBioPayment:(CJPayBioPaymentBaseRequestModel *)requestModel completion:(void(^)(CJPayBioCheckState state))completion;

/**
 开通指纹支付的请求

 @param requestModel 使用指定的model参数开通指纹支付
 @param findUrl 需要添加到请求中的参数
 @param completion 完成的回调
 */
+ (void)openBioPayment:(CJPayBioPaymentBaseRequestModel *)requestModel
               findUrl:(NSString *)findUrl
            completion:(void(^)(CJPayBioOpenState state))completion;

/**
 关闭指纹支付

 @param model 使用指定的model参数关闭指纹支付
 @param completion 完成的回调
 */
+ (void)closeBioPayment:(CJPayBioPaymentBaseRequestModel *)model completion:(void(^)(CJPayBioCloseState state))completion;

+ (NSString *)getSupportPwdType;

+ (NSDictionary *)buildPwdDicWithModel:(NSDictionary *)requestModel
                               lastPWD:(NSString *)lastPWD;

+ (void)openBioPaymentOnVC:(UIViewController *)vc
         withBioRequestDic:(NSDictionary *)requestDic
           completionBlock:(void (^)(BOOL result, BOOL needBack))completionBlock;

@end

NS_ASSUME_NONNULL_END

