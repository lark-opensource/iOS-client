//
//  CJPayRealNameAuthToBizHalfViewController.h
//  BDAlogProtocol
//
//  Created by qiangang on 2020/7/17.
//
// 曾用名：CJPayAuthVerifiedHalfViewController

#import "CJPayHalfPageBaseViewController.h"
#import "CJAuthVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayAuthQueryResponse;
typedef void (^CJPayAuthVerifiedCallBack)(CJPayAuthDeskCallBackType);

@interface CJPayRealNameAuthToBizHalfViewController : CJPayHalfPageBaseViewController

- (instancetype)initWithParams:(NSDictionary *)params
authQueryResponse:(CJPayAuthQueryResponse *)response
     authCallback:(CJPayAuthVerifiedCallBack)callBack;

@end

NS_ASSUME_NONNULL_END
