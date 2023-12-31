//
//  CJPayAuthQueryResponse.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayBaseResponse.h"

#import "CJPayAuthDisplayContentModel.h"
#import "CJPayAuthAgreementContentModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayAuthAgreementContentModel;
@interface CJPayAuthQueryResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayAuthAgreementContentModel *agreementContentModel;

@property (nonatomic, assign) NSInteger isAuthorize;
@property (nonatomic, assign) NSInteger isAuth;
@property (nonatomic, copy) NSString *authUrl;


@end

NS_ASSUME_NONNULL_END
