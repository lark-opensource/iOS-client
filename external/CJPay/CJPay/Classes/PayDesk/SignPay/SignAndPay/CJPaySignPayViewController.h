//
//  CJPaySignPayViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/7/8.
//

#import "CJPayFullPageBaseViewController.h"

#import "CJPayOuterPayUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayQuerySignInfoResponse;
@interface CJPaySignPayViewController : CJPayFullPageBaseViewController

@property (nonatomic, strong) CJPaySignPayQuerySignInfoResponse *querySignInfo;
@property (nonatomic, copy) NSString *returnURLStr;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, assign) CJPayOuterType signType;
@property (nonatomic, assign) BOOL immediatelyClose; // 是否需要先回调，在延迟关闭页面，默认为NO

@property (nonatomic, copy, nullable) void (^completion)(CJPayDypayResultType type, NSString *msg);

@end

NS_ASSUME_NONNULL_END
