//
//  BDPayMercahntMappingModel.h
//  Pods
//
//  Created by wangxiaohong on 2020/8/19.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDegradeModel : JSONModel

@property (nonatomic, copy) NSString *bdpayAppId;
@property (nonatomic, copy) NSString *cjpayAppId;
@property (nonatomic, copy) NSString *bdpayMerchantId;
@property (nonatomic, copy) NSString *cjpayMerchantId;
@property (nonatomic, assign) BOOL isPayUseH5;
@property (nonatomic, assign) BOOL isBalanceWithdrawUseH5;
@property (nonatomic, assign) BOOL isBalanceRechargeUseH5;
@property (nonatomic, assign) BOOL isCardListUseH5;
@property (nonatomic, assign) BOOL isBDPayUseH5;

@end

NS_ASSUME_NONNULL_END
