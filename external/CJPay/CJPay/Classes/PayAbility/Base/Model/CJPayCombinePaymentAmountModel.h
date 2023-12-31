//
//  CJPayCombinePaymentAmountModel.h
//  Pods
//
//  Created by xiuyuanLee on 2021/4/19.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCombinePaymentAmountModel : JSONModel

@property (nonatomic, copy) NSString *totalAmount;
@property (nonatomic, copy) NSString *detailInfo;
@property (nonatomic, copy) NSString *cashAmount;
@property (nonatomic, copy) NSString *bankCardAmount;

@end

NS_ASSUME_NONNULL_END
