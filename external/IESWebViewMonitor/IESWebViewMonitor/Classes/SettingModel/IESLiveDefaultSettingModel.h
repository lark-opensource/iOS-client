//
//  IESLiveDefaultSettingModel.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/9/4.
//

#import <Foundation/Foundation.h>
#import "IESMonitorSettingModelProtocol.h"
#if __has_include("IESLiveWebViewMonitor.h")
#import "IESLiveWebViewMonitor.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveFPSReportConfig : NSObject
@property (nonatomic, assign) NSInteger interval; // fps 指标上报周期，单位ms，默认 3000
@end

@interface IESLiveMemoryReportConfig : NSObject
@property (nonatomic, assign) NSInteger interval; // memory 指标上报周期，单位ms，默认 3000
@end

@interface IESLiveAPMReportConfig : NSObject
@property (nonatomic, strong) IESLiveFPSReportConfig *fpsReportConfig; // fps 上报配置
@property (nonatomic, strong) IESLiveMemoryReportConfig *memoryReportConfig; // memory 上报配置
@end

@interface IESLivePerformanceMonitorConfig : NSObject
@property (nonatomic, copy) NSArray *checkPoint;  // performance timing 采集时机 默认@[@"DOMContentLoaded", @"load"]
@end

@interface IESLivePerformanceReportConfig : NSObject
@property (nonatomic, strong) IESLivePerformanceMonitorConfig *performanceMonitorConfig; // performance 上报配置
@end

@interface IESLiveStaticErrorMonitorConfig : NSObject
@property (nonatomic, copy) NSArray *ignore; // static error(resource) 忽略的配置，支持正则，默认@[]
@end

@interface IESLiveErrorMsgReportConfig : NSObject
@property (nonatomic, strong) IESLiveStaticErrorMonitorConfig *staticErrorMonitorConfig; // static error 上报配置
@end

@interface IESLiveStaticPerformanceMonitor : NSObject
@property (nonatomic, assign) NSInteger slowSession; // 慢会话阈值，默认 8000ms
@property (nonatomic, assign) double sampleRate; // resource timing （static） 采样率，默认 1（100%）
@end

@interface IESLiveResourceTimingReportConfig : NSObject
@property (nonatomic, strong) IESLiveStaticPerformanceMonitor *staticPerformanceMonitorConfig; // resource timing 上报配置
@end

@interface IESLiveDefaultSettingModel : NSObject<IESMonitorSettingModelProtocol>

@property (nonatomic, strong) IESLiveAPMReportConfig *apmReportConfig;
@property (nonatomic, strong) IESLivePerformanceReportConfig *performanceReportConfig;
@property (nonatomic, strong) IESLiveErrorMsgReportConfig *errorMsgReportConfig;
@property (nonatomic, strong) IESLiveResourceTimingReportConfig *resourceTimingReportConfig;
@property (nonatomic, copy) NSArray *blockList; // 上报黑名单， 默认@[@"about:blank"]
@property (nonatomic, copy) NSString *bizTag; // 业务标识，默认为空，如果需要定制，请传非空字符串
@property (nonatomic, assign) BOOL offlineMonitor; // 离线化覆盖率监控，默认 YES
@property (nonatomic, assign) BOOL navigationMonitor; // 客户端跳转监控,默认NO, 建议逐步放量
@property (nonatomic, assign) BOOL webCoreMonitor; // webCore监控, 默认为NO, 建议逐步放量
@property (nonatomic, assign) BOOL emptyMonitor; // 白屏监控，默认NO,建议逐步放量


// web相关监控开关

@property (nonatomic, assign) BOOL injectBrowser; // 默认为YES，即由客户端统一注入browser sdk
@property (nonatomic, assign) BOOL onlyMonitorNavigationFinish; // 默认为YES，用于计算加载成功率
@property (nonatomic, assign) BOOL onlyMonitorOffline; // 默认为NO，仅监控离线化
@property (nonatomic, assign) BOOL turnOnWebJSBMonitor; // 默认为YES，监控web的JSB错误
@property (nonatomic, assign) BOOL turnOnWebFetchMonitor; // 默认为YES，监控web的fetch这个jsb的错误
@property (nonatomic, assign) BOOL turnOnWebBlankMonitor; // 默认为YES，监控web的白屏
@property (nonatomic, assign) BOOL turnOnWebJSBPerfMonitor; // 默认为YES，监控webview的JSB使用情况
@property (nonatomic, assign) BOOL turnOnFalconMonitor; //默认为YES，监控falcon详情
@property (nonatomic, assign) BOOL turnOnCollectBackAction; //默认为YES，打开webview在remove的时候回捞的操作
@property (nonatomic, assign) BOOL turnOnCollectAsyncAction; //默认为YES，打开webview在回捞时异步操作操作

// lynx相关监控开关

@property (nonatomic, assign) BOOL turnOnLynxJSBMonitor; // 默认为YES，监控lynx的JSB错误
@property (nonatomic, assign) BOOL turnOnLynxFetchMonitor; // 默认为YES，监控lynx的fetch这个jsb的错误
@property (nonatomic, assign) BOOL turnOnLynxBlankMonitor; // 默认为YES，监控lynx的白屏
@property (nonatomic, assign) BOOL turnOnLynxJSBPerfMonitor; // 默认为YES，监控lynx的JSB使用情况
@property (nonatomic, assign) BOOL turnOnLynxCustomErrorMonitor; //默认为YES，前端上报自定义错误;

@property (nonatomic, copy) NSDictionary<Class, NSArray<NSString*>*> *webViewInitSels;

+ (IESLiveDefaultSettingModel*)defaultModel;

- (NSDictionary*)toDic;

@end

NS_ASSUME_NONNULL_END
