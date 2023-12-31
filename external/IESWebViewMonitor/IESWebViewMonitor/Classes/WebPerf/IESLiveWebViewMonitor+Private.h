//
//  IESLiveWebViewMonitor+Private.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "IESLiveWebViewMonitor.h"
#import "IESLiveWebViewPerformanceDictionary.h"
#import "BDWebView+BDWebViewMonitor.h"

NS_ASSUME_NONNULL_BEGIN

// 直播专用
@interface IESLiveWebViewMonitor(IESLive)

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(nullable NSDictionary *)setting;

+ (void)stopLiveMonitor;

+ (NSDictionary *)hook_ORIGDic;

+ (void)setClass:(Class)cls sel:(NSString*)sel imp:(IMP)impPointer;

+ (void)installMonitorOnWKWebView:(WKWebView *)wkWebView;

@end

NS_ASSUME_NONNULL_END
