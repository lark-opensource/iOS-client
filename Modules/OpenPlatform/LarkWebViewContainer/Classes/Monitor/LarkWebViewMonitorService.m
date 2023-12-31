//
//  LarkWebViewMonitorService.m
//  LarkWebViewContainer
//
//  Created by dengbo on 2021/12/30.
//

#import "LarkWebViewMonitorService.h"
#import "LarkWebView.h"
#import <IESWebViewMonitor/IESLiveWebViewMonitor.h>
#import <IESWebViewMonitor/IESLiveDefaultSettingModel.h>
#import <IESWebViewMonitor/WKWebView+PublicInterface.h>
#import <IESWebViewMonitor/WKWebViewConfiguration+PublicInterface.h>
#import <IESWebViewMonitor/BDWebView+BDWebViewMonitor.h>
#import <IESWebViewMonitor/IESLiveWebViewPerformanceDictionary.h>
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>

@implementation LarkWebViewMonitorService

+ (void)startMonitor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [IESLiveWebViewMonitor setStopUpdateBrowser:YES];
        [IESLiveWebViewMonitor startWithClasses:[NSSet setWithArray:@[LarkWebView.class]] settingModel:[IESLiveDefaultSettingModel defaultModel]];
    });
}

+ (void)registerReportReceiver:(id<LarkWebViewMonitorReceiver>)receiver {
    [IESLiveWebViewMonitor registerReportBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull data) {
        if ([key isKindOfClass:NSString.class] && [data isKindOfClass:NSDictionary.class]) {
            [receiver recvWithKey:key data:data];
        }
    }];
}

+ (void)configWebView:(LarkWebView *)webView {
    __weak LarkWebView *wWebView = webView;
    [webView attachNativeBaseContextBlock:^NSDictionary * _Nonnull(NSString * _Nonnull url) {
        __strong LarkWebView *sWebView = wWebView;
        return @{@"biz_type": sWebView.config.bizType.rawValue ?: @""};
    }];
    [webView chooseReportTime:BDWebViewPerfReportTime_JSPerfReady];
}

+ (void)updateWKWebViewConfiguration:(WKWebViewConfiguration *)configuration monitorConfig:(LarkWebViewMonitorConfig *)monitorConfig {
    configuration.bdwm_disableMonitor = !monitorConfig.enableMonitor;
    configuration.bdwm_disableInjectBrowser = !monitorConfig.enableInjectJS;
}

+ (NSString *)fetchNavigationId:(LarkWebView *)webView {
    IESLiveWebViewPerformanceDictionary *perfDict = webView.performanceDic;
    NSDictionary *commonInfo = [perfDict getNativeCommonInfo];
    if ([commonInfo isKindOfClass:NSDictionary.class] && commonInfo[kBDWebViewMonitorNavigationID]) {
        return commonInfo[kBDWebViewMonitorNavigationID];
    }
    return nil;
}

@end

