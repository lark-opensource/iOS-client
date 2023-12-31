//
//  CJPayCreditPayMethodModel.h
//  Pods
//
//  Created by bytedance on 2021/7/27.
//

#import "CJPayCreditPayMethodModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBytePayCreditPayMethodModel : CJPayCreditPayMethodModel

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL choose;
@property (nonatomic, copy) NSArray<NSString *> *voucherMsg;
@property (nonatomic, copy) NSString *payTypeDesc;
@property (nonatomic, copy) NSString *feeDesc;
@property (nonatomic, assign) NSInteger orderSubFixedVoucherAmount;

@end

NS_ASSUME_NONNULL_END
