//
//  CJPayRealNameAuthToBizViewController.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/22.
//
// 曾用名：CJPayAuthVerifiedViewController

#import "CJAuthVerifyManager.h"
#import "CJPayFullPageBaseViewController.h"
NS_ASSUME_NONNULL_BEGIN
@class CJPayAuthQueryResponse;
typedef void (^CJPayAuthVerifiedCallBack)(CJPayAuthDeskCallBackType);

@interface CJPayRealNameAuthToBizViewController : CJPayFullPageBaseViewController

- (instancetype)initWithParams:(NSDictionary *)params
             authQueryResponse:(CJPayAuthQueryResponse *)response
                  authCallback:(CJPayAuthVerifiedCallBack)callBack;

@end

NS_ASSUME_NONNULL_END
