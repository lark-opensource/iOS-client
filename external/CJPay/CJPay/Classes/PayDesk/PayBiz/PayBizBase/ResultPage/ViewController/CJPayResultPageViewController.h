//
//  CJPayResultPageViewController.h
//  CJPay-Pay
//
//  Created by wangxinhua on 2020/9/18.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayOrderResultResponse.h"
#import "CJPayCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayResultPageViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPayOrderResultResponse *resultResponse;
@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse;
@property (nonatomic, copy) NSDictionary *commonTrackerParams; // 埋点通参
@property (nonatomic, copy) NSString *customTitle;
@property (nonatomic, assign) BOOL isOneKeyQuickPay; // 标识是否是极速支付
@property (nonatomic, assign) BOOL isPaymentForOuterApp; // 标识是否为外部App拉起抖音支付

@end

NS_ASSUME_NONNULL_END
