//
//  CJPayResultPromotionModel.h
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBalanceResultPromotionModel : JSONModel

@property (nonatomic, copy) NSString *leftDiscountAmount;
@property (nonatomic, copy) NSString *leftDiscountDesc;
@property (nonatomic, copy) NSString *rightTopDesc;
@property (nonatomic, copy) NSString *rightBottomDesc;
@property (nonatomic, copy) NSString *voucherEndTime;
@property (nonatomic, copy) NSString *jumpUrl;

@end

NS_ASSUME_NONNULL_END
