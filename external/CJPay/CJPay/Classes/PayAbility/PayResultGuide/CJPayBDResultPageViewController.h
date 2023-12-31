//
//  CJPayBDResultPageViewController.h
//  CJPay-BDPay
//
//  Created by wangxinhua on 2020/9/18.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDOrderResultResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@interface CJPayBDResultPageViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayBDOrderResultResponse *resultResponse;
@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, assign) BOOL isShowNewStyle; //电商收银台安全感loading需要展示新样式的结果页
@property (nonatomic, assign) BOOL isForceCloseBuyAgain;  //是否强制关闭复购轮询逻辑，只有标准前置收银台为YES
@property (nonatomic, assign) BOOL isPaymentForOuterApp; // 标识是否为外部App拉起抖音支付

@end

NS_ASSUME_NONNULL_END
