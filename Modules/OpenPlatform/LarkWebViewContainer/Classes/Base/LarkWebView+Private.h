//
//  LarkWebView+Private.h
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/10/29.
//  


#import <LarkWebViewContainer/LarkWebViewContainer.h>
#import "LarkWebView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LarkWebViewSecLinkServiceProtocol;
@protocol LarkWebViewQualityServiceProtocol;
@protocol LarkWebViewMonitorServiceProtocol;

@class WKUIDelegateProxy;
@class WKNavigationDelegateProxy;

/// LarkWebView内部属性接口，模块外部请勿调用
@interface LarkWebView ()

/// 品质层Service
@property (nonatomic, strong, nullable) id<LarkWebViewSecLinkServiceProtocol> secLinkService;

/// SecLink安全拦截Service
@property (nonatomic, strong, nullable) id<LarkWebViewQualityServiceProtocol> qualityService;

/// 监控Service
@property (nonatomic, strong, nullable) id<LarkWebViewMonitorServiceProtocol> monitorService;

/// 渲染次数
@property (nonatomic) NSInteger renderTimes;
@property (nonatomic) NSInteger reloadTimes;
@property (nonatomic) BOOL isTemplateReady;
/// 可见崩溃次数
@property (nonatomic) NSInteger visibleTerminateCount;
/// 不可见崩溃次数
@property (nonatomic) NSInteger invisibleTerminateCount;
/// 是否是崩溃状态
@property (nonatomic) BOOL isTerminateState;
/// load URL次数
@property (nonatomic) NSInteger loadURLCount;
/// load URL End次数
@property (nonatomic) NSInteger loadURLEndCount;
///webview创建时间
@property (nonatomic) NSTimeInterval createTime;
///webview 将要消失时间
@property (nonatomic) NSTimeInterval disappearTime;

/// 内部的代理对象，封装外部设置的uiDelegate
@property (nonatomic, strong) WKUIDelegateProxy *uiDelegateProxy;
/// 内部的代理对象，封装外部设置的navigationDelegate
@property (nonatomic, strong) WKNavigationDelegateProxy *navigationDelegateProxy;

@end

NS_ASSUME_NONNULL_END
