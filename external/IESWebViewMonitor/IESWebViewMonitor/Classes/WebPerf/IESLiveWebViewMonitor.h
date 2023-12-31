//
//  IESLiveWebViewMonitor.h
//
//  Created by renpengcheng on 2019/5/13.
//  Copyright © 2019 renpengcheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IESLiveWebViewMonitorSettingModel.h"
#import "IESWebViewCustomReporter.h"
#import "BDWebView+BDWebViewMonitor.h"
#import "IESMonitorSettingModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const IESLiveWebViewClassesKey;

typedef NS_ENUM(NSInteger, IESLiveWebViewReportType) {
    IESLiveWebViewCover,
    IESLiveWebViewAccumulate,
    IESLiveWebViewAverage,
    IESLiveWebViewReportDirectly,
    IESLiveWebViewReportDiff,
    IESLiveWebViewReportCustom
};

@interface IESLiveWebViewMonitor : NSObject

+ (void)startMonitor;
/**
 iOS担心下发js文件会有审核风险，因此宿主通知是否在审核中

 @param stop 审核中为YES
 */
+ (void)setStopUpdateBrowser:(BOOL)stop;

// 注意，正常接入了新Gecko的会默认注册这些参数，可以不用设置，如果没有注册过gecko，才调用这个注册一下，注意设置的时候需要保证是正常的，否则会覆盖掉原来正常的配置，要在start之前调用
+ (void)setUpGurdEnvWithAppId:(NSString *)appId appVersion:(NSString *)appVersion cacheRootDirectory:(NSString *)directory deviceId:(NSString *)deviceId;

/**
 SDK 开启监控入口，冷启时调用即可
 @param classes @[WKWebView, OtherWebView], // 需要监控的 webview class 集合
 @param settings 监控配置，详见IESLiveWebViewMonitorSettingModel
 */
+ (void)startWithClasses:(NSSet<Class>*)classes
                settings:(nullable NSDictionary*)settings;

/**
 SDK 开启监控入口，冷启时调用即可(便捷调用方式)
 @param classes @[WKWebView, OtherWebView], // 需要监控的 webview class 集合
 @param settingModel 详见IESLiveDefaultSettingModel
 */
+ (void)startWithClasses:(NSSet<Class>*)classes
            settingModel:(id<IESMonitorSettingModelProtocol>)settingModel;

/**
 SDK 开启监控入口，冷启时调用即可(由于swift不是动态调用，因此支持不传入class，而是传入string，内部再转成class)
 @param classes @[@"WKWebView", @"OtherWebView"], // 需要监控的 webview class 集合
 @param settingModel 详见IESLiveDefaultSettingModel
 */
+ (void)startWithClassNames:(NSSet<NSString *>*)classNames
               settingModel:(id<IESMonitorSettingModelProtocol>)settingModel;

/**
 业务方上报block，（如果业务方需要对上传数据做更改，可设置此block，实现自定义上报逻辑，但建议使用sdk默认实现，不设置此block）

 @param reportBlock 自定义上报实现，参数为serviceName，和上报数据dic
 */
+ (void)registerReportBlock:(void(^)(NSString *, NSDictionary*))reportBlock;

/**
 获取注册 WebView 继承链上的叶子节点
 */
+ (Class)getNodeClassWithWebView:(Class)webViewClass;

@end

NS_ASSUME_NONNULL_END
