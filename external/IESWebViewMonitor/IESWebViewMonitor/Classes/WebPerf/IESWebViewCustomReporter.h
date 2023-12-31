//
//  IESWebViewCustomReporter.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/9/24.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESWebViewCustomReportType) {
    IESWebViewCustomReportDirectly,
    IESWebViewCustomReportCover
};

@interface WKWebView (IESWebViewCustomReport)

- (void)reportWithEventName:(NSString *)eventName
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(IESWebViewCustomReportType)reportType;

@end

@interface WKWebView (BDWebViewMonitorReporter)

- (void)setBdwmCustomProps:(NSDictionary *)customProps;

- (void)setBdwmDoubleReportBlock:(void(^)(NSDictionary*))doubleReportBlock;

- (void)setBdwmDoubleReportKeys:(NSArray *)doubleReportKeys;

@end

NS_ASSUME_NONNULL_END
