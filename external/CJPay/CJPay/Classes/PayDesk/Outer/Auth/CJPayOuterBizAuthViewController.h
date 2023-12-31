//
//  CJPayOuterBizAuthViewController.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayOuterPayUtil.h"

@class CJPayCommonProtocolModel, CJPayQueryBindAuthorizeInfoResponse;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOuterBizAuthViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) NSString *bindContent;
@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^cancelBlock)(CJPayDypayResultType type);

- (instancetype)initWithResponse:(CJPayQueryBindAuthorizeInfoResponse *)response;

@end

NS_ASSUME_NONNULL_END
