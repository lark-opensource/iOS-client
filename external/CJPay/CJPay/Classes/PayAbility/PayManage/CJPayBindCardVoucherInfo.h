//
//  CJPayBindCardVoucherInfo.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/6.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardVoucherInfo : JSONModel

@property (nonatomic, copy) NSString *voucherMsg;
@property (nonatomic, copy) NSArray *vouchers;
@property (nonatomic, copy) NSString *binVoucherMsg;
@property (nonatomic, copy) NSString *aggregateVoucherMsg;
@property (nonatomic, assign) NSInteger isNotShowPromotion;

@end

NS_ASSUME_NONNULL_END
