//
//  CJPayBizWebViewController+WebviewMonitor.m
//  Pods
//
//  Created by 尚怀军 on 2021/8/13.
//

#import "CJPayBizWebViewController+WebviewMonitor.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayBizWebViewController.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayWebviewMonitorConfigModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBizWebViewController (WebviewMonitor)

CJPAY_REGISTER_PLUGIN({
    if (![CJPaySettingsManager shared].currentSettings.webviewMonitorConfigModel.enableMonitor) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self btd_swizzleInstanceMethod:NSSelectorFromString(@"viewWillDisappear:")
                                   with:@selector(monitor_viewWillDisappear:)];
        
        [self btd_swizzleInstanceMethod:NSSelectorFromString(@"webView:decidePolicyForNavigationAction:decisionHandler:")
                                   with:@selector(monitor_webView:decidePolicyForNavigationAction:decisionHandler:)];
    });
})

- (void)monitor_viewWillDisappear:(BOOL)animated {
    [self monitor_viewWillDisappear:animated];
}

- (void)monitor_webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
        decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [self p_delayDetectPageTimeoutWithUrl:CJString(navigationAction.request.URL.absoluteString)];
    [self monitor_webView:webView
decidePolicyForNavigationAction:navigationAction
          decisionHandler:decisionHandler];
}



- (void)p_delayDetectPageTimeoutWithUrl:(NSString *)urlStr {
    // 重置对应url的状态，延迟对应时间检测该url有没有被置openstatus
    if (!Check_ValidString(urlStr)) {
        return;
    }
    
    if (![urlStr hasPrefix:@"http"]) {
        return;
    }
    
    [self.pageStatusDic cj_setObject:@(NO) forKey:CJString(urlStr)];
    NSInteger settingsWebviewTimeoutTime = [CJPaySettingsManager shared].currentSettings.webviewMonitorConfigModel.webviewPageTimeoutTime;
    NSInteger timeOutTime = settingsWebviewTimeoutTime > 0 ? settingsWebviewTimeoutTime : 10;
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeOutTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        [self p_tryUploadTimeOutStatusWithUrl:urlStr timeOutTime:timeOutTime];
    });
}

- (void)p_tryUploadTimeOutStatusWithUrl:(NSString *)urlStr
                            timeOutTime:(NSInteger)timeOutTime {
    NSURL *url = [NSURL URLWithString:CJString(urlStr)];
    if (!url) {
        return;
    }
    
    BOOL isSetOpenStatus = [self.pageStatusDic cj_boolValueForKey:CJString(url.path)];
    if (!isSetOpenStatus) {
        [CJMonitor trackService:@"wallet_rd_webview_page_timeout"
                         metric:@{}
                       category:@{@"timeout": @(timeOutTime), @"path": CJString(url.path)}
                          extra:@{@"url": CJString(urlStr)}];
    }
}

- (void)setPageStatusDic:(NSMutableDictionary *)pageStatusDic {
    objc_setAssociatedObject(self, @selector(pageStatusDic), pageStatusDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)pageStatusDic {
    NSMutableDictionary *pageDic = objc_getAssociatedObject(self, @selector(pageStatusDic));
    if (!pageDic) {
        pageDic = [NSMutableDictionary new];
        objc_setAssociatedObject(self, @selector(pageStatusDic), pageDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return pageDic;
}

- (BOOL)hasDetectBlank {
    return [objc_getAssociatedObject(self, @selector(hasDetectBlank)) boolValue];
}

- (void)setHasDetectBlank:(BOOL)hasDetectBlank {
    objc_setAssociatedObject(self, @selector(hasDetectBlank), @(hasDetectBlank), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
