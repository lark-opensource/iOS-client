//
//  CJIAPStoreManager+Delegate.m
//  CJPay
//
//  Created by 王新华 on 2019/6/18.
//

#import "CJIAPStoreManager+Delegate.h"
#import "CJPaySDKMacro.h"
#import "CJPayTracker.h"
#import "CJPaySDKMacro.h"
#import <objc/runtime.h>

@implementation  CJIAPStoreManager(MultiDelegateSupport)
@dynamic iapDelegates;


- (NSHashTable<id<CJIAPStoreDelegate>> *)iapDelegates {
    NSHashTable *temDelegates = objc_getAssociatedObject(self, @selector(iapDelegates));
    if (!temDelegates) {
        temDelegates = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(self, @selector(iapDelegates), temDelegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return temDelegates;
}

- (id<CJIAPStoreDelegate>)delegate {
    return (id<CJIAPStoreDelegate>)objc_getAssociatedObject(self, @selector(delegate));
}

- (void)setDelegate:(id<CJIAPStoreDelegate>)delegate {
    [self removeCJIAPStoreDelegate:delegate];
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
    [self addCJIAPStoreDelegate:delegate];
}

- (void)addCJIAPStoreDelegate:(id<CJIAPStoreDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.iapDelegates addObject:delegate];
    });
}

- (void)removeCJIAPStoreDelegate:(id<CJIAPStoreDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.iapDelegates removeObject:delegate];
    });
}

- (nullable NSArray<id<CJIAPStoreDelegate>> *)getCopyIAPDelegates {
    NSArray<id<CJIAPStoreDelegate>> *delegates;
    delegates = [[self.iapDelegates allObjects] copy];
    return delegates;
}

@end

@implementation CJIAPStoreManager(Delegate)

#pragma mark - api
- (void)eventV:(NSString *)event params:(NSDictionary *)params productID:(NSString *)productID {
    NSDictionary *baseParam = @{@"platform": @"iap"};
    
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:baseParam];
    [trackParams addEntriesFromDictionary:params];
    trackParams[@"business_id"] = [self businessIdentify:productID];
    trackParams[@"product_id"] = CJString(productID);
    trackParams[@"iap_type"] = @"oc_sk1";
    [CJTracker event:event params:trackParams];
}

- (NSString *)businessIdentify:(NSString *)productID {
    NSArray<id<CJIAPStoreDelegate>> *allDelegates = [self _getFitDelegateShouldHandleProduct:productID];
//    CJPayLogAssert(allDelegates.count >= 1, @"Please set businessIdentify fo product ID: %@", productID);
    id<CJIAPStoreDelegate> singleDelegate = allDelegates.firstObject;
    if (singleDelegate && [singleDelegate respondsToSelector:@selector(businessIdentify:)]) {
        return [singleDelegate businessIdentify:productID];
    } else {
        return @"";
    }
}

#pragma mark - private API

// 空实现
- (void)event:(NSString *)event params:(NSDictionary *)params {
    
}
// 空实现
- (BOOL)shouldHandleProduct:(nonnull NSString *)productID {
    return NO;
}

- (nullable NSArray<id<CJIAPStoreDelegate>> *)_getFitDelegateShouldHandleProduct:(NSString *)productID {
    NSMutableArray<id<CJIAPStoreDelegate>> *fitDelegates = [NSMutableArray<id<CJIAPStoreDelegate>> new];
    NSArray <id<CJIAPStoreDelegate>> *allDelelgate = [self getCopyIAPDelegates];
    [allDelelgate enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && [obj respondsToSelector:@selector(shouldHandleProduct:)]) {
            if ([obj shouldHandleProduct:productID]) {
                [fitDelegates addObject:obj];
            }
        }
    }];
    return [fitDelegates copy];
}

- (BOOL)allowNewBuyingWithUnconfirmedProduct:(nullable NSArray<CJIAPProduct *> *)UnconfirmedProduct newBuyingProductID:(NSString *)productID newOrderParams:(NSDictionary *)params {
    __block BOOL allow = YES;
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:productID];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(allowNewBuyingWithUnconfirmedProduct:newBuyingProductID:newOrderParams:)]) {
            allow = [one allowNewBuyingWithUnconfirmedProduct:UnconfirmedProduct newBuyingProductID:productID newOrderParams:params];
            // 只要有不允许，就break循环
            if (!allow) {
                *stop = YES;
            }
        }
    }];
    return allow;
}

- (BOOL)shouldInterceptAppStorePaymentQueue:(SKPaymentQueue *)queue payment:(SKPayment *)payment forProduct:(SKProduct *)product {
    __block BOOL shouldIntercept = NO;
    [self.getCopyIAPDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(shouldInterceptAppStorePaymentQueue:payment:forProduct:)]) {
            shouldIntercept = [one shouldInterceptAppStorePaymentQueue:queue payment:payment forProduct:product];
            // 只要有拦截，就中断循环
            if (shouldIntercept) {
                *stop = YES;
            }
        }
    }];
    return shouldIntercept;
}

#pragma mark CJIAPStoreDelegate
- (void)showLoadingWithStage:(CJPayIAPLoadingStage)stage productId:(NSString *)productId text:(NSString *)text {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:productId];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(showLoadingWithStage:productId:text:)]) {
            [one showLoadingWithStage:stage productId:productId text:text];
        }
    }];
}

- (void)didFinishProductOrder:(CJIAPProduct *)product resultType:(CJPayIAPResultType)resultType error:(NSError *)error {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:product.productID];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(didFinishProductOrder:resultType:error:)]) {
            [one didFinishProductOrder:product resultType:resultType error:error];
            [CJTracker event:@"wallet_rd_iap_real_callback"
                      params:@{@"is_background" : @"0",
                               @"product_id" : CJString(product.productID),
                               @"result_type" : [[NSNumber numberWithInteger:resultType] stringValue],
                               @"biz_delegate" : CJString(NSStringFromClass(one.class)),
                               @"merchant_id" : CJString(product.merchantId),
                               @"trade_no" : CJString(product.tradeNo),
                               @"is_retain_shown" : product.isRetainShown ? @"1" : @"0"
                             }];
        }
    }];
}

- (void)didFinishProductOrderInBack:(CJIAPProduct *)product resultType:(CJPayIAPResultType)resultType error:(NSError *)error {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:product.productID];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(didFinishProductOrderInBack:resultType:error:)]) {
            [one didFinishProductOrderInBack:product resultType:resultType error:error];
            [CJTracker event:@"wallet_rd_iap_real_callback"
                      params:@{@"is_background" : @"1",
                               @"product_id" : CJString(product.productID),
                               @"result_type" : [[NSNumber numberWithInteger:resultType] stringValue],
                               @"biz_delegate" : CJString(NSStringFromClass(one.class)),
                               @"merchant_id" : CJString(product.merchantId),
                               @"trade_no" : CJString(product.tradeNo),
                               @"is_retain_shown" : product.isRetainShown ? @"1" : @"0"
                             }];
        }
    }];
}

- (void)iesBuyProduct:(NSString *)iapID productID:(NSString *)productID orderID:(NSString *)orderID error:(NSError *)error {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:iapID];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(iesBuyProduct:productID:orderID:error:)]) {
            [one iesBuyProduct:iapID productID:productID orderID:orderID error:error];
        }
    }];
}

- (void)iesFetchOrderInfoWithProductID:(NSString *)productID product:(SKProduct *)product {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:product.productIdentifier];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(iesFetchOrderInfoWithProductID:product:)]) {
            [one iesFetchOrderInfoWithProductID:productID product:product];
        }
    }];
}

- (void)iesSendTransactionWithOrderID:(NSString *)orderID receipt:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:transaction.payment.productIdentifier];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(iesSendTransactionWithOrderID:receipt:transaction:)]) {
            [one iesSendTransactionWithOrderID:orderID receipt:receipt transaction:transaction];
        }
    }];
}

- (void)iesCheckFinalResultWithOrderID:(NSString *)orderID receipt:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:transaction.payment.productIdentifier];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(iesCheckFinalResultWithOrderID:receipt:transaction:)]) {
            [one iesCheckFinalResultWithOrderID:orderID receipt:receipt transaction:transaction];
        }
    }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment for:(SKProduct *)product {
    NSArray<id<CJIAPStoreDelegate>> *fitDelegates = [self _getFitDelegateShouldHandleProduct:product.productIdentifier];
    [fitDelegates enumerateObjectsUsingBlock:^(id<CJIAPStoreDelegate>  _Nonnull one, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([one respondsToSelector:@selector(paymentQueue:shouldAddStorePayment:for:)]) {
            [one paymentQueue:queue shouldAddStorePayment:payment for:product];
        }
    }];
}

@end
