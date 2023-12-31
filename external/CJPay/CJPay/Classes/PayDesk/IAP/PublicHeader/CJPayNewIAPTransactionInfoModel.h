//
//  CJPayNewIAPTransactionInfoModel.h
//  CJPay-IAP
//
//  Created by 尚怀军 on 2022/3/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// 苹果交易相关信息
@interface CJPayNewIAPTransactionInfoModel : NSObject

@property (nonatomic, copy) NSString *receipt;
@property (nonatomic, copy, nullable) NSString *productID;
@property (nonatomic, copy, nullable) NSString *transactionID;
@property (nonatomic, copy, nullable) NSString *originalTransactionID;
@property (nonatomic, copy) NSString *transactionDate;
@property (nonatomic, copy) NSString *originalTransactionDate;

@end

NS_ASSUME_NONNULL_END
