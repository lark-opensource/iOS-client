//
//  CJPayWKWebView.m
//  Pods
//
//  Created by 高航 on 2022/8/8.
//

#import "CJPayWKWebView.h"
#import "CJPaySDKMacro.h"
#import <IESWebViewMonitor/IESLiveWebViewMonitor.h>
//#import <IESWebViewMonitor/BDHybridMonitorXManager.h>
#import <IESWebViewMonitor/IESLiveDefaultSettingModel.h>

@implementation CJPayWKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    static dispatch_once_t webviewMonitor;
    dispatch_once(&webviewMonitor, ^{
        [self p_startWebviewMonitor];//对于同一class，在app运行周期内初始化一次即可
    });
    CJPayLogInfo(@"cjpay wkwebview init(%p)", self)
    return self;
}

- (void)p_startWebviewMonitor {
    //wkwebview启动
    [IESLiveWebViewMonitor startWithClasses:[NSSet setWithObject:self.class] settingModel:[IESLiveDefaultSettingModel defaultModel]];
    
}

- (void)dealloc {
    CJPayLogInfo(@"cjpay wkwebview dealloc(%p)", self)
}

@end
