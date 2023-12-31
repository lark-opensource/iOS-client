//
//  CJPayBizDYPayModel.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/7.
//

#import <Foundation/Foundation.h>
#import "CJPayHomePageViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;
@class CJPayBaseViewController;
@class CJPayIntegratedCashierProcessManager;
@interface CJPayBizDYPayModel : NSObject

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showConfig;
@property (nonatomic, weak) CJPayHomePageViewController *homeVC;
@property (nonatomic, copy) NSString *createResponseStr;
@property (nonatomic, copy) NSDictionary *trackParams;
@property (nonatomic, strong) CJPayCreateOrderResponse *bizCreateOrderResponse;

@property (nonatomic, assign) BOOL isPaymentForOuterApp;

@property (nonatomic, copy) NSString *cj_merchantID;
@property (nonatomic, copy) NSString *intergratedTradeIdentify;

//聚合查单接口使用
@property (nonatomic, copy) NSString *processStr;
@property (nonatomic, copy) NSString *jhResultPageStyle;

@property (nonatomic, weak) CJPayIntegratedCashierProcessManager *processManager;  // 流程控制

- (BOOL)isNeedQueryBizOrder;

@end

NS_ASSUME_NONNULL_END
