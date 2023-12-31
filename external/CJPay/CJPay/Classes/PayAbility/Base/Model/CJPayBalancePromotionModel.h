//
//  CJPayBalancePromotionModel.h
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/16.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBalancePromotionModel : JSONModel

@property (nonatomic, copy) NSString *promotionDescription;
@property (nonatomic, copy) NSString *resourceNo;
@property (nonatomic, copy) NSString *planNo;
@property (nonatomic, copy) NSString *materialNo;
@property (nonatomic, copy) NSString *bizType;
@property (nonatomic, assign) BOOL hasBindCardLottery;
@property (nonatomic, copy) NSString *bindCardInfo;

@end

NS_ASSUME_NONNULL_END
