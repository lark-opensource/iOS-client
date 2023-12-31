//
//  BDWebView+BDWebViewMonitor.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/10/28.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
@class IESLiveWebViewPerformanceDictionary;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kWebviewInstanceConfigDisableMonitor;
extern NSString * const kWebviewInstanceConfigDisableInjectBrowser;

@protocol IESWebViewMonitorDelegate <NSObject>

@optional
- (void) reportDataBeforeLeave:(WKWebView *)webView;

@end

@interface WKWebView (BDWebViewMonitor)

@property (nonatomic, copy)  NSString *bdwm_Bid;
@property (nonatomic, copy)  NSString *bdwm_Pid;
/// 该webview是否禁用监控，通过wkconfig设置
@property (nonatomic, assign, readonly) BOOL bdwm_disableMonitor;
/// 该webview的实例配置，通过wkconfig设置
@property (nonatomic, strong, readonly, nullable) NSDictionary *settings;
@property (nonatomic, assign) BOOL hasInjectedMonitor;
@property (nonatomic, assign) BOOL isLiveWebView;
@property (nonatomic, assign) NSTimeInterval requestStartTime;
@property (nonatomic, strong, readonly) IESLiveWebViewPerformanceDictionary *performanceDic;
@property(nonatomic, strong, class, readonly) NSHashTable *bdwm_MonitorDelegates;

+ (void)addDelegate:(id<IESWebViewMonitorDelegate>)delegate;

- (instancetype)bdwm_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration;
- (WKNavigation*)bdwm_LoadRequest:(NSURLRequest *)request;
- (void)bdwm_willMoveToSuperview:(nullable UIView *)newSuperview;
- (void)bdwm_willMoveToWindow:(nullable UIWindow *)newWindow;
- (void)bdwm_removeFromSuperview;
- (void)bdwm_goBack;

- (void)resetPerfExts;

+ (void)hookProgressMethod;
- (void)addRenderEventListener;

@end

NS_ASSUME_NONNULL_END
