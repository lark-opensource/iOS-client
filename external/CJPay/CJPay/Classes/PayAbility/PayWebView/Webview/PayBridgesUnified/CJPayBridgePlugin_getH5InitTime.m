//
//  CJPayBridgePlugin_getH5InitTime.m
//  Pods
//
//  Created by wangxinhua on 2022/10/17.
//

#import "CJPayBridgePlugin_getH5InitTime.h"
#import "CJPayBizWebViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayHybridPerformanceMonitor.h"

@implementation CJPayBridgePlugin_getH5InitTime

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_getH5InitTime, getH5InitTime), @"ttcjpay.getH5InitTime");
}

- (void)getH5InitTimeWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    if ([controller isKindOfClass:CJPayBizWebViewController.class]) {
        CJPayBizWebViewController *webController = (CJPayBizWebViewController *)controller;
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:webController.webPerformanceMonitor.performanceModel.callAPITime];
        long timeMillsecond = @([date timeIntervalSince1970] * 1000).longValue;
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"timestamp": @(timeMillsecond), @"time": @(webController.webPerformanceMonitor.performanceModel.hybridContainerPrepareTime)}, nil);
    } else {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"不是财经容器，无法上报具体启动时间");
    }
}

@end
