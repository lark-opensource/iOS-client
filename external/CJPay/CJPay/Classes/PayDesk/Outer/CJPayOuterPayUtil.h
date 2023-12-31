//
//  CJPayOuterPayUtil.h
//  Pods
//
//  Created by wangxiaohong on 2022/7/11.
//

#import <Foundation/Foundation.h>

#import "CJPaySDKDefine.h"
#import "CJPayDeskServiceHeader.h"

NS_ASSUME_NONNULL_BEGIN

//-1   未知
//0    订单支付成功
//10   用户中途取消
//20   正在处理中
//30   版本过低
//40   失败
//50   超时
typedef enum : NSUInteger {
    CJPayDypayResultTypeUnknow,
    CJPayDypayResultTypeSuccess,
    CJPayDypayResultTypeCancel,
    CJPayDypayResultTypeProcessing,
    CJPayDypayResultTypeLowVersion,
    CJPayDypayResultTypeFailed,
    CJPayDypayResultTypeTimeout
} CJPayDypayResultType;

typedef NS_ENUM(NSInteger, CJPayOuterType) {
    CJPayOuterTypeInnerPay,       // 端内签约支付 | 端内独立签约
    CJPayOuterTypeAppPay,    // 端外app签约支付 | 端外app独立签约
    CJPayOuterTypeWebPay,    // 端外浏览器签约支付 | 端外浏览器独立签约
};

@class CJPayOrderResultResponse;
@class CJPayCreateOrderResponse;
@interface CJPayOuterPayUtil : NSObject

+ (void)closeCashierDeskVC:(UIViewController *)vc signType:(CJPayOuterType)signType jumpBackURL:(NSString *)jumpBackURL jumpBackResult:(CJPayDypayResultType)resultType complettion:(void (^ __nullable)(BOOL isSuccess))completion;

+ (CJPayDypayResultType)dypayResultTypeWithOrderStatus:(CJPayOrderStatus)orderStatus;
+ (CJPayDypayResultType)dypayResultTypeWithErrorCode:(CJPayErrorCode)errorCode;

+ (void)checkAuthParamsValid:(NSDictionary *)schemaParams completion:(void (^)(CJPayDypayResultType resultType, NSString *errorMsg))completion;

+ (void)checkPaymentParamsValid:(NSDictionary *)schemaParams
                     completion:(void (^)(CJPayDypayResultType resultType, NSString *errorMsg))completion;

@end

NS_ASSUME_NONNULL_END
