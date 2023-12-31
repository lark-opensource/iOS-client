//
//  CJPaySignOnlyQuerySignTemplateResponse.h
//  CJPay-a399f1d1
//
//  Created by wangxiaohong on 2022/9/15.
//

#import "CJPayBaseResponse.h"
#import "CJPaySignPayTemplateInfo.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPaySignModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayMemAgreementModel;
@interface CJPaySignOnlyQuerySignTemplateResponse : CJPayBaseResponse

@property (nonatomic, assign) NSInteger tradeAmount;
@property (nonatomic, assign) NSInteger promotionAmount;
@property (nonatomic, assign) NSInteger realTradeAmount;
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
@property (nonatomic, copy) NSString *verifyType;
@property (nonatomic, copy) NSString *bindCardUrl;
@property (nonatomic, copy) NSString *jumpType;

- (CJPaySignModel *)toSignModel;

@end

NS_ASSUME_NONNULL_END
