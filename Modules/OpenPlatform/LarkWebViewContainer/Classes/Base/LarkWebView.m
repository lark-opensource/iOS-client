//
//  LarkWebView.m
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/10/12.
//

#import "LarkWebView.h"
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>

@interface LarkWebView ()
@property (nonatomic,assign)UInt64 customEventInfo;
@end

@implementation LarkWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    if (LarkWebView.enableHybridMonitor) {
        NSAssert(configuration.lwk_callByInternal, @"do not call init(frame:configuration:)");
        if (configuration.lwk_callByInternal) {
            self = [super initWithFrame:frame configuration:configuration];
                #if DEBUG || BETA || ALPHA
                if (@available(iOS 16.4, *)) {
                    self.inspectable = YES;
                }
                #endif
            return self;
        } else {
            LarkWebViewConfig *config = [[[[LarkWebViewConfigBuilder alloc] init]
                                          setWebViewConfig:configuration]
                                         buildWithBizType:LarkWebViewBizType.unknown
                                         isAutoSyncCookie:NO
                                         secLinkEnable:NO
                                         performanceTimingEnable:NO
                                         vConsoleEnable:NO
                                         advancedMonitorInfoEnable:NO
                                         promptFGSystemEnable:NO
                                        ];
            [config.webViewConfig lwk_updateWithWebViewConfig:config];
            if (self = [super initWithFrame:frame configuration:configuration]) {
                [self initByOCWithConfig:config parentTrace:nil webviewDelegate:nil];
            }
                #if DEBUG || BETA || ALPHA
                if (@available(iOS 16.4, *)) {
                    self.inspectable = YES;
                }
                #endif
            return self;
        }
    } else {
    NSAssert(NO, @"do not call init(frame:configuration:)");
    LarkWebViewConfig *config =  [[[[LarkWebViewConfigBuilder alloc] init]
                                   setWebViewConfig:configuration]
                                  buildWithBizType:LarkWebViewBizType.unknown
                                  isAutoSyncCookie:NO
                                  secLinkEnable:NO
                                  performanceTimingEnable:NO
                                  vConsoleEnable:NO
                                  advancedMonitorInfoEnable:NO
                                  promptFGSystemEnable:NO
                                  ];
    self = [self initWithFrame:frame config:config parentTrace:nil webviewDelegate:nil];
        #if DEBUG || BETA || ALPHA
        if (@available(iOS 16.4, *)) {
            self.inspectable = YES;
        }
        #endif
    return self;
    }
}

- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config {
    return [self initWithFrame:frame config:config parentTrace:nil webviewDelegate:nil];
}
- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config parentTrace:(OPTrace * _Nullable)parentTrace {
    return [self initWithFrame:frame config:config parentTrace:parentTrace webviewDelegate:nil];
}
- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config parentTrace:(OPTrace * _Nullable)parentTrace webviewDelegate:(id <LarkWebViewDelegate> _Nullable)webviewDelegate {
    if (LarkWebView.enableHybridMonitor) {
        [config.webViewConfig lwk_updateWithWebViewConfig:config];
        if (self = [self initWithFrame:frame configuration:config.webViewConfig]) {
            [self initByOCWithConfig:config parentTrace:parentTrace webviewDelegate:webviewDelegate];
        }
        return self;
    } else {
    if (self = [super initWithFrame:frame configuration:config.webViewConfig]) {
            #if DEBUG || BETA || ALPHA
            if (@available(iOS 16.4, *)) {
                self.inspectable = YES;
            }
            #endif
        [self initByOCWithConfig:config parentTrace:parentTrace webviewDelegate:webviewDelegate];
    }
    return self;
    }
}

- (void)dealloc
{
    [self deinitByOC];
}

#pragma mark - webview自定义事件
- (void)recordWebviewCustomEvent:(LarkWebViewCustomEvent)event {
    _customEventInfo = _customEventInfo | event;
}
- (BOOL)webviewCustomEventDidHappen:(LarkWebViewCustomEvent)event {
    return _customEventInfo & event;
}
- (UInt64)customEventInfo {
    return _customEventInfo;
}

@end
