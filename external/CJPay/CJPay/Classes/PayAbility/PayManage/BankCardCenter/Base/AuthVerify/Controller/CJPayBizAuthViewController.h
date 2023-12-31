//
//  CJPayBizAuthViewController.h
//  Pods
//
//  Created by xiuyuanLee on 2020/11/2.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayBindCardManager.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, CJPayBizAuthCompletionType) {
    CJPayBizAuthCompletionTypeCancel,
    CJPayBizAuthCompletionTypeSuccess,
    CJPayBizAuthCompletionTypeFail,
    CJPayBizAuthCompletionTypeLogout
};

typedef void (^CJPayBizAuthCompletionBlock)(CJPayBizAuthCompletionType);

@class CJPayMemCreateBizOrderResponse;
@class CJPayUserInfo;
@class CJPayBizAuthInfoModel;

@interface CJPayBizAuthVerifyModel : CJPayBindCardPageBaseModel

@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, strong) CJPayMemCreateBizOrderResponse *memCreatOrderResponse;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfo;
@property (nonatomic, assign) CJPayBizAuthType bizAuthType;

@end

@interface CJPayBizAuthViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, copy) void (^authVerifiedBlock)(void);
@property (nonatomic, copy) void (^noAuthCompletionBlock)(CJPayBizAuthCompletionType);

@end

NS_ASSUME_NONNULL_END
