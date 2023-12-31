//
//  CJPayNewIAPManager.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/21.
//

#import <Foundation/Foundation.h>
#import "CJPayNewIAPServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface CJPayNewIAPManager : NSObject<CJPayNewIAPServiceProtocol>

+ (CJPayNewIAPManager *)shareInstance;

- (void)startupService;

// 是否走新的购买流程
- (BOOL)shouldUseNewIAP;

// 新的应用内购买流程
- (void)startIAPWithParams:(NSDictionary *)bizParams
                   product:(nullable id)product;

- (void)restoreWithUid:(NSString *)uid
              callBack:(void(^)(BOOL success, NSError * _Nullable error))callBack;

- (void)prefetchProductsWithIdentifiers:(NSSet *)identifiers
                             completion:(void (^)(NSArray<id<CJPayIAPProductProtocol>> * _Nullable, NSError * _Nullable))completion;

- (void)requestSK1ProductsWithIdentifiers:(NSSet *)identifiers
                               completion:(void (^)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable))completion;



// 恢复购买

@end

NS_ASSUME_NONNULL_END
