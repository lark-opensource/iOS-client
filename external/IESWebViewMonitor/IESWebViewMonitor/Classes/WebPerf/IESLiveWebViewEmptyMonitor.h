//
//  IESLiveWebViewEmptyMonitor.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveWebViewEmptyMonitor : NSObject

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting;

+ (void)stopMonitor;

+ (void)addObserverToWKWebView:(WKWebView *)wkWebView;

@end

NS_ASSUME_NONNULL_END
