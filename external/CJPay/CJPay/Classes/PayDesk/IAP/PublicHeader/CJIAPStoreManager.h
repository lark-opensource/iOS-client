//
//  CJIAPStoreManager.h
//  CJPay
//
//  Created by 王新华 on 2019/3/15.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "CJPayIAPHeader.h"
#import "CJPayIAPResultEnumHeader.h"
#import "CJIAPProduct.h"
#import "CJPayNewIAPServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJIAPStoreDelegate <NSObject>

- (void)didFinishProductOrder:(nullable CJIAPProduct *)product resultType:(CJPayIAPResultType)resultType error:(nullable NSError *)error;
- (void)didFinishProductOrderInBack:(nullable CJIAPProduct *)product resultType:(CJPayIAPResultType)resultType error:(nullable NSError *)error;
- (BOOL)shouldHandleProduct:(NSString *)productID;
- (NSString *)businessIdentify:(NSString *)productID; // 这个字段用来区分统一app内不同的业务，便于统计app内各业务的数据情况

@optional
//返回YES。事件不会再往后面的delegate传递。返回NO，会继续传递。无相关需求可不实现
//1. product不该自己处理时，返回NO。
//2.product需要自己处理时返回YES，不在向后传递事件。
//3. 如需要直接跳IAP购买，可将业务下单参数和该方法放回的product通过`- (void)startIAPWithParams:(NSDictionary *)bizParams product:(nullable SKProduct *)product`直接调起支付
- (BOOL)shouldInterceptAppStorePaymentQueue:(SKPaymentQueue *)queue payment:(SKPayment *)payment forProduct:(SKProduct *)product;
// 供业务方根据当前存在的未验证订单来判断是否允许新的下单
// 1. 主要用来支持，有未confirm订单时，不让用户重新发起新的下单和支付
// 注意：每个业务线应该只处理自己的商品ID，操作非自己业务的商品ID会有很大隐患
- (BOOL)allowNewBuyingWithUnconfirmedProduct:(nullable NSArray<CJIAPProduct *> *)UnconfirmedProduct newBuyingProductID:(NSString *)productID newOrderParams:(NSDictionary *)params;
- (void)event:(NSString *)event params:(NSDictionary *)params;

// IESStoreHandler 事件向外传递，业务方是否实现可选；
- (void)iesBuyProduct:(NSString *)iapID productID:(NSString *)productID orderID:(nullable NSString * )orderID error:(nullable NSError *)error;
- (void)iesFetchOrderInfoWithProductID:(NSString *)productID
                               product:(SKProduct *)product;
- (void)iesSendTransactionWithOrderID:(nullable NSString *)orderID
                              receipt:(NSString *)receipt
                          transaction:(nullable SKPaymentTransaction *)transaction;
- (void)iesCheckFinalResultWithOrderID:(nullable NSString *)orderID
                               receipt:(NSString *)receipt
                           transaction:(nullable SKPaymentTransaction *)transaction;
- (void)showLoadingWithStage:(CJPayIAPLoadingStage)stage productId:(NSString *)productId text:(NSString *)text;
- (void)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment for:(SKProduct *)product;

@end

@interface CJIAPStoreManager : NSObject

@property (nonatomic, copy, readonly) NSDictionary<NSString *, SKProduct *> *productsDict; // products缓存

+ (CJIAPStoreManager *)shareInstance;

//把CJIAPStoreManager作为订单的转发中心，同时会把IESStore的handler赋值给self的iesStoreHandler，把IESStore的delegate赋值给self 的iesStoreDelegate
- (void)becomeIESStoreDelegateCenter;

// 启动IAPManager，在app启动时进行，业务方需要调用，否则可能有订单回调不能正常处理
- (void)startupService;
// bizParams 发起IAP支付的参数。添加Key-Value支持生成product的策略，对应key为payment_type，value: 0使用系统API获取，1使用SKProduct通过KVC设置，2使用SKMutablePayment生成。
- (void)startIAPWithParams:(NSDictionary *)bizParams;
- (void)startIAPWithParams:(NSDictionary *)bizParams product:(nullable id)product;
- (void)checkUnverifiedTransaction;
- (BOOL)canMakePayments;
// 预拉取商品信息，会自动缓存
- (void)preFetchProducts:(NSSet *)identifiers
             completion:(void(^)(NSArray<SKProduct *> *products, NSError * _Nullable error))completion;
// 预拉取商品信息，不依赖IESStore
- (void)newPreFetchProducts:(NSSet *)identifiers
                 completion:(void (^)(NSArray<id<CJPayIAPProductProtocol>> * _Nonnull, NSError * _Nullable))completion;
// 恢复购买
- (void)restoreTransactionsWithUid:(NSString *)uid Completion:(void(^)(BOOL success, NSError * _Nullable error))completion;
- (void)restoreTransactionsWithUid:(NSString *)uid WithIapIDs:(NSArray<NSString *> *)iapIDs
                           completion:(void(^)(BOOL success, NSError * _Nullable error))completion;


@end

@interface CJIAPStoreManager(MultiDelegateSupport)

@property (nonatomic, copy, readonly) NSHashTable<id<CJIAPStoreDelegate>> *iapDelegates; // 多代理形式 和 单代理共存

@property (nonatomic, weak) id<CJIAPStoreDelegate> delegate DEPRECATED_ATTRIBUTE;

- (void)addCJIAPStoreDelegate:(id<CJIAPStoreDelegate>)delegate;
- (void)removeCJIAPStoreDelegate:(id<CJIAPStoreDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
