//
//  CJPayUnionBindCardHalfAccreditViewController.h
//  Pods
//
//  Created by chenbocheng on 2021/9/26.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayBindCardManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardAuthorizationResponse;

@interface CJPayUnionBindCardHalfAccreditViewModel : CJPayBindCardPageBaseModel

@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, strong) CJPayUnionBindCardAuthorizationResponse *authorizationResponse;

@end

@interface CJPayUnionBindCardHalfAccreditViewController : CJPayHalfPageBaseViewController <CJPayBindCardPageProtocol>

@property (nonatomic, copy) void(^agreeCompletion)(void);
@property (nonatomic, copy) void(^protocolListClick)(NSInteger);

@end

NS_ASSUME_NONNULL_END
