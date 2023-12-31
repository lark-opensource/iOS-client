//
//  CJPayNewIAPServiceProtocol.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/21.
//

#ifndef CJPayNewIAPServiceProtocol_h
#define CJPayNewIAPServiceProtocol_h

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, CJPayIAPResultType);
typedef NS_ENUM(NSUInteger, CJPayIAPStage);
@class CJPayNewIAPOrderCreateModel;
@class CJPayNewIAPConfirmModel;
@protocol CJPayNewIAPServiceProtocol <NSObject>

// 回调业务方结果
- (void)didFinishProductOrder:(nullable CJPayNewIAPOrderCreateModel *)orderCreateModel
                 isBackground:(BOOL)isBackground
                   resultType:(CJPayIAPResultType)resultType
                        error:(nullable NSError *)error;

// 下单
- (void)createTradeOrderWithAppID:(nullable NSString *)appid
                           params:(nullable NSDictionary *)params
                             exts:(nullable NSDictionary *)extParams
                       completion:(void(^)(NSError *_Nullable, CJPayNewIAPOrderCreateModel *_Nullable))completionBlock;

// sk1验证交易
- (void)sk1ConfirmWithCommonParams:(NSDictionary *)bizParams
                  bizContentParams:(NSDictionary *)params
                        completion:(void(^)(NSError *_Nullable, CJPayNewIAPConfirmModel *_Nullable))completionBlock;


// sk2验证交易
- (void)sk2ConfirmWithCommonParams:(NSDictionary *)bizParams
                  bizContentParams:(NSDictionary *)params
                        completion:(void(^)(NSError *_Nullable, CJPayNewIAPConfirmModel *_Nullable))completionBlock;

// 埋点
- (void)event:(NSString *)event
       params:(NSDictionary *)params;

// 阶段耗时监控
- (void)monitorWithStage:(CJPayIAPStage)stage
             categoryDic:(NSDictionary *)categoryDic
               extralDic:(NSDictionary *)extralDic;

// keychain安全存储
- (void)keyChainSafeSave:(NSString *)value
                  forkey:(NSString *)key;

// keychain安全存储
- (NSString *)keyChainStringValueForkey:(NSString *)key;

// 是否启用sk2
- (BOOL)isEnableSK2;

// 是否在sk2的流程中启用sk1的监听
- (BOOL)isEnableSK1Observer;

// pending是否要返回fail
- (BOOL)isNeedPendingReturnFail;

//appstore推广
- (void)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment for:(SKProduct *)product;

@end
 
@protocol CJPayIAPProductProtocol <NSObject>
 
- (nullable NSString *)productIdentifier;    // product id
- (nullable NSString *)price;                // 价格
- (nullable NSString *)currencyCode;         // 货币
- (nullable NSString *)countryCode;          // 地区
- (nullable NSString *)localeIdentifier;     // locale标识
- (nullable id)originalProductModel;         // 存储原始的商品套餐model
 
@end
 

NS_ASSUME_NONNULL_END


#endif /* CJPayNewIAPServiceProtocol_h */
