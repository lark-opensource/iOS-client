//
//  CJPaySignOnlyViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayOuterPayUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignOnlyQuerySignTemplateResponse;
@interface CJPaySignOnlyViewController : CJPayFullPageBaseViewController

@property (nonatomic, strong) CJPaySignOnlyQuerySignTemplateResponse *querySignInfo;
@property (nonatomic, copy) NSString *returnURLStr;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *zg_app_id;
@property (nonatomic, copy) NSString *zg_merchant_id;
@property (nonatomic, assign) CJPayOuterType signType;
@property (nonatomic, assign) BOOL immediatelyClose; // 是否需要先回调，在延迟关闭页面，默认为NO

@property (nonatomic, copy, nullable) void (^completion)(CJPayDypayResultType type, NSString *msg);


@end

NS_ASSUME_NONNULL_END
