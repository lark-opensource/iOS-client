//
//  CJPayQueryBindAuthorizeInfoResponse.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemAgreementModel;
@protocol CJPayMemAgreementModel;
@interface CJPayQueryBindAuthorizeBriefInfoModel : JSONModel

@property (nonatomic, copy) NSString *displayDesc;

@end

@interface CJPayQueryBindAuthorizeProtocolModel : JSONModel

@property (nonatomic, copy) NSArray <CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSString *protocolCheckBox;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSString *tailGuideMessage;

@end

@interface CJPayQueryBindAuthorizeInfoResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayQueryBindAuthorizeBriefInfoModel *authBriefModel;
@property (nonatomic, strong) CJPayQueryBindAuthorizeProtocolModel *protocolModel;

@end

NS_ASSUME_NONNULL_END
