//
//  CJPayNewIAPOrderCreateModel.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/22.
//

#import "CJPayNewIAPBaseResponseModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, CJPayIAPType);
@class CJIAPProduct;
@class CJPayNewIAPTransactionInfoModel;
@interface CJPayNewIAPOrderCreateModel : CJPayNewIAPBaseResponseModel

// 下单信息基本参数
@property (nullable, nonatomic, copy) NSString *appId;
@property (nullable, nonatomic, copy) NSString *merchantId;
@property (nullable, nonatomic, copy) NSString *uid;
@property (nullable, nonatomic, copy) NSString *tradeNo;
@property (nullable, nonatomic, copy) NSString *outTradeNo;
@property (nullable, nonatomic, copy) NSString *uuid;

@property (nullable, nonatomic, copy) NSString *tradeAmount;
@property (nullable, nonatomic, copy) NSString *uidEncrypt;

// 传递参数
@property (nonatomic, assign) BOOL isBackground;
@property (nonatomic, assign) CJPayIAPType iapType;
@property (nullable, nonatomic, strong) CJPayNewIAPTransactionInfoModel *transactionModel;

- (instancetype)initWith:(NSString *)fullOrderID;

- (BOOL)applicationUsernameUseEncryptUid;
- (NSString *)customApplicationUsername;
- (CJIAPProduct *)toCJIAPProductModel;

@end

NS_ASSUME_NONNULL_END
