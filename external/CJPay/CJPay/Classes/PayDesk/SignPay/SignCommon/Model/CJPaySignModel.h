//
//  CJPaySignModel.h
//  CJPay-a399f1d1
//
//  Created by wangxiaohong on 2022/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayTemplateInfo;
@class CJPayMemAgreementModel;
@interface CJPaySignModel : NSObject

@property (nonatomic, assign) NSInteger tradeAmount;
@property (nonatomic, assign) NSInteger promotionAmount;
@property (nonatomic, assign) NSInteger realTradeAmount;
@property (nonatomic, strong) CJPaySignPayTemplateInfo *signTemplateInfo;
@property (nonatomic, copy) NSString *nextDeductDate;
@property (nonatomic, copy) NSString *userAccount;
@property (nonatomic, assign) BOOL hasBankCard;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel *> *protocolInfo;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSString *deductMethodDesc;
@property (nonatomic, copy) NSString *promotionDesc;

@end

NS_ASSUME_NONNULL_END
