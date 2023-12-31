//
//  CJPayUnionBindCardAuthorizationResponse.h
//  Pods
//
//  Created by chenbocheng on 2021/9/28.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMemAgreementModel;
@interface CJPayUnionBindCardAuthorizationResponse : CJPayBaseResponse

@property (nonatomic, strong) NSString *authorizationIconUrl;
@property (nonatomic, strong) NSString *nameMask;
@property (nonatomic, strong) NSString *idCodeMask;
@property (nonatomic, strong) NSString *mobileMask;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, strong) NSString *guideMessage;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;

@end

NS_ASSUME_NONNULL_END
