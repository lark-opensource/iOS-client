//
//  LarkWebViewMonitorService.h
//  LarkWebViewContainer
//
//  Created by dengbo on 2021/12/30.
//

#import <Foundation/Foundation.h>

@class LarkWebView, WKWebViewConfiguration, LarkWebViewMonitorConfig;
@protocol LarkWebViewMonitorReceiver;

NS_ASSUME_NONNULL_BEGIN

@interface LarkWebViewMonitorService : NSObject

+ (void)startMonitor;

+ (void)configWebView:(LarkWebView *)webView;

+ (void)updateWKWebViewConfiguration:(WKWebViewConfiguration *)configuration
                       monitorConfig:(LarkWebViewMonitorConfig *)monitorConfig;

+ (nullable NSString *)fetchNavigationId:(LarkWebView *)webView;

+ (void)registerReportReceiver:(id<LarkWebViewMonitorReceiver>)receiver;

@end

NS_ASSUME_NONNULL_END

