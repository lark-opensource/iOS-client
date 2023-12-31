//
//  CJPaySignOnlyResultPageViewController.h
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPaySignOnlyBindBytePayAccountResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignOnlyResultPageViewController : CJPayHalfPageBaseViewController

@property (nonatomic, assign) BOOL isFromOuterApp;
@property (nonatomic, strong) CJPaySignOnlyBindBytePayResultDesc *result;

@end

NS_ASSUME_NONNULL_END
