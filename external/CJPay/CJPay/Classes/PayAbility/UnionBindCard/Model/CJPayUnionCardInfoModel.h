//
//  CJPayUnionCardInfoModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import <JSONModel/JSONModel.h>

#import "CJPayMemAgreementModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMemAgreementModel;
@interface CJPayUnionCardInfoModel : JSONModel

@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, copy) NSString *cardNoMask;
//@property (nonatomic, strong) NSString *mobileMask;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSString *bankCardId;

@end

NS_ASSUME_NONNULL_END
