//
//  CJPaySignPayQuerySignInfoResponse.h
//  Pods
//
//  Created by chenbocheng on 2022/7/12.
//

#import "CJPayIntergratedBaseResponse.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPaySignPayTemplateInfo.h"
#import <JSONModel/JSONModel.h>
#import "CJPaySignModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMemAgreementModel;
@class CJPaySignPayTemplateInfo;
@interface CJPaySignPayQuerySignInfoResponse : CJPayIntergratedBaseResponse

@property (nonatomic, assign) NSInteger tradeAmount;
@property (nonatomic, assign) NSInteger promotionAmount;
@property (nonatomic, assign) NSInteger realTradeAmount;
@property (nonatomic, copy) NSString *promotionDesc;
@property (nonatomic, strong) CJPaySignPayTemplateInfo *signTemplateInfo;
@property (nonatomic, copy) NSString *nextDeductDate;
@property (nonatomic, copy) NSString *userAccount;
@property (nonatomic, assign) BOOL hasBankCard;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *protocolInfo;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSString *deductOrderUrl;
@property (nonatomic, copy) NSString *dypayReturnUrl;//跳回端外
@property (nonatomic, copy) NSString *deductMethodDesc;

- (CJPaySignModel *)toSignModel;

@end

NS_ASSUME_NONNULL_END
