//
//  CJIAPProduct.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/7.
//

#import <JSONModel/JSONModel.h>
#import "CJPayIAPResultEnumHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJIAPProduct : JSONModel

@property (nonatomic, assign) NSInteger createTime;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *receipt;
@property (nonatomic, copy, nullable) NSString *productID; // 商品的iapID
@property (nonatomic, copy, nullable) NSString *transactionID;
@property (nonatomic, copy, nullable) NSString *originalTransactionID;
@property (nonatomic, copy) NSDictionary *otherVerifyParams;
@property (nonatomic, assign) BOOL verifyInForeground; // 内存变量 不缓存
@property (nonatomic, copy) NSString *transactionDate;
@property (nonatomic, copy) NSString *originalTransactionDate;
@property (nonatomic, copy) NSString *outOrderNo; // 外部订单号，一般为商户侧订单号
@property (nonatomic, copy, nullable) NSString *originalOrderID;
@property (nonatomic, assign) BOOL isFromRefreshReceipt;
@property (nonatomic, copy) NSString *currentTransactionState;
@property (nonatomic, assign) NSInteger iapType;
@property (nonatomic, copy) NSString *merchantId;
//埋点用
@property (nonatomic, assign) BOOL isRetainShown;

- (BOOL)isValid;

- (BOOL)receiptIsValid;

- (BOOL)isRestoreProduct;

@end

NS_ASSUME_NONNULL_END
