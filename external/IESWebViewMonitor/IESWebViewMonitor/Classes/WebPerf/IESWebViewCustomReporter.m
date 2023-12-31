//
//  IESWebViewCustomReporter.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/9/24.
//

#import "IESWebViewCustomReporter.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveWebViewPerformanceDictionary.h"

#define reportByType \
- (void)reportWithEventName:(NSString *)eventName \
  metric:(nullable NSDictionary *)metric \
category:(nullable NSDictionary *)category \
   extra:(nullable NSDictionary *)extra \
    type:(IESWebViewCustomReportType)reportType { \
    switch (reportType) { \
        case IESWebViewCustomReportCover: \
            [self.performanceDic coverWithEventName:(NSString *)eventName \
                                      clientMetric:metric \
                                    clientCategory:category \
                                             extra:extra]; \
            break; \
            \
        case IESWebViewCustomReportDirectly: \
            [self.performanceDic reportDirectlyWithEventName:(NSString *)eventName \
                                               clientMetric:metric \
                                             clientCategory:category \
                                                      extra:extra]; \
            break; \
             \
        default: \
            break; \
    } \
}

@implementation WKWebView (IESWebViewCustomReport)

reportByType

@end

@implementation WKWebView (BDWebViewMonitorReporter)

// 业务传入的指标
- (void)setBdwmCustomProps:(NSDictionary *)customProps {
    [self.performanceDic setCustomDic:customProps];
}

// 双发的上报回调
- (void)setBdwmDoubleReportBlock:(void(^)(NSDictionary*))doubleReportBlock {
    [self.performanceDic setDoubleReportBlock:doubleReportBlock];
}

// 从自定义埋点中摘取的key
- (void)setBdwmDoubleReportKeys:(NSArray *)doubleReportKeys {
    [self.performanceDic setDoubleReportKeys:doubleReportKeys];
}

@end
