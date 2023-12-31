//
//  IESLiveWebViewPerformanceDictionary.h
//
//  Created by renpengcheng on 2019/5/24.
//

#import <Foundation/Foundation.h>
#import "IESLiveWebViewMonitor.h"

@class WKWebView;

extern NSString * _Nonnull const kBDWebViewMonitorNativeBase;
extern NSString *  _Nullable const kBDWebViewMonitorNavigationID;
extern NSString * _Nullable const kBDWebViewMonitorURL;
extern NSString * _Nonnull const kBDWebViewMonitorClientParams;
extern NSString * _Nonnull const kBDWebViewMonitorServiceType;
extern NSString * _Nonnull const kBDWebViewMonitorEvent;
extern NSString * _Nonnull const vBDWMHttpStatusCodeError;
extern NSString * _Nonnull const vBDWMNavigationFail;
extern NSString * _Nonnull const kBDWebViewMonitorSDKVersion;

typedef NSDictionary *_Nullable(^BDHMBaseContextBlock)(NSString * _Nullable url);

@class IESLiveWebViewMonitorSettingModel;

typedef NS_ENUM(NSUInteger, BDWebViewMonitorPerfReportTime) {
    BDWebViewMonitorPerfReportTime_Default = 0, //默认上报时机，在dealloc的时机触发上报，有最全的生命周期时间
    BDWebViewMonitorPerfReportTime_JSPerfReady = 1, //在前端JSSDK返回performance数据时上报，部分生命周期时间点会丢失，建议常驻缓存型页面使用
    BDWebViewMonitorPerfReportTime_Custom = 2, //自定义时间点触发上报，如果有特殊业务需求要用，可以先联系@周一川
};

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveWebViewPerformanceDictionary : NSObject

@property (nonatomic, assign) BOOL isLive;

@property (nonatomic, copy, readonly) NSString *currentUrl;

@property (nonatomic, copy) NSDictionary *customDic;

@property (nonatomic, copy) void(^doubleReportBlock)(NSDictionary*);

@property (nonatomic, copy) NSArray *doubleReportKeys;

@property (atomic, copy) NSString *bid;
@property (atomic, copy) NSString *pid;

// webview related ts
@property (nonatomic, assign) NSTimeInterval bdwm_webViewInitTs;
@property (nonatomic, assign) NSTimeInterval bdwm_attachTs;
@property (nonatomic, assign) NSTimeInterval bdwm_detachTs;
@property (nonatomic, assign) long long bdwm_loadStartTS;
@property (nonatomic, assign) BOOL bdwm_hasAttach;

// webview extend abilities
@property (nonatomic, assign) int bdwm_isPrefetch;
@property (nonatomic, assign) int bdwm_isOffline;
@property (nonatomic, assign) int bdwm_isPreload;
@property (nonatomic, assign) BOOL bdwm_isContainerReuse;
@property (nonatomic, strong) NSMutableArray *contextBlockList;
@property (nonatomic, strong) NSString *bdwm_virtualAid;
@property (nonatomic, strong) NSMutableArray *containerUUIDList;

@property (nonatomic, assign) BDWebViewMonitorPerfReportTime bdwm_reportTime;

- (instancetype)initWithSettingModel:(IESLiveWebViewMonitorSettingModel *)settingModel
                             webView:(id)webView;

- (void)setNavigationID:(NSString *)navigationID;

- (void)setUrl:(NSString *)url;
- (NSString *)fetchCurrentUrl;
- (NSString *)fetchBizTag;

- (void)updateClickStartTs;

- (NSDictionary *)getNativeCommonInfo;

// 覆盖类型
- (void)coverWithDic:(NSDictionary *)dic;
- (void)coverWithDic:(NSDictionary *)dic nativeCommon:(NSDictionary * __nullable)commonInfo;

// jsError, resourceError, HttpError 累加
- (void)accumulateWithDic:(NSDictionary *)dic;

// 透传类型
- (void)reportBatchWithDic:(NSDictionary *)dic webView:(WKWebView *)webview;
- (void)reportDirectlyWithDic:(NSDictionary *)dic;
- (void)reportDirectlyWithDic:(NSDictionary *)srcDic nativeCommon:(NSDictionary * __nullable)commonInfo;

// 透传类型，用nativeInfo包裹一层
- (void)reportDirectlyWrapNativeInfoWithDic:(NSDictionary *)srcDic;

// 平均值类型
- (void)mergeDicToCalAverage:(NSDictionary *)dic;

// 客户端添加指标
- (void)coverClientParams:(NSDictionary *)dic;

- (void)coverClientParamsOnce:(NSDictionary *)dic;

- (void)appendParams:(NSDictionary *)dic path:(NSString*)path;
- (void)appendClientParams:(NSDictionary *)srcDic forKey:(NSString *)subKey;

// PV 融合overview一同上报
- (void)reportPVWithURLStr:(NSString *)urlStr;

// stage: "loadUrl", "DomContentLoaded", "finishNavigation"
- (void)reportPVWithStageDic:(NSDictionary *)stageDic;

// 自定义埋点上报（覆盖类型）
- (void)coverWithEventName:(NSString *)eventName
              clientMetric:(NSDictionary *)metric
            clientCategory:(NSDictionary *)category
                     extra:(NSDictionary *)extra;

// 立即上报自定义埋点
- (void)reportDirectlyWithEventName:(NSString *)eventName
                       clientMetric:(NSDictionary *)metric
                     clientCategory:(NSDictionary *)category
                              extra:(NSDictionary *)extra;

// 暴露给前端的自定义埋点
- (void)reportCustomWithDic:(NSDictionary *)dic webView:(WKWebView *)webview;

// 上报request error
- (void)reportRequestError:(NSError *)error withURLStr:(NSString *)urlStr;

// 上报ContainerError事件
- (void)reportContainerError:(nullable NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(nullable NSString *)msg bizTag:(nullable NSString *)bizTag;

// 上报web进程中止的异常
- (void)reportTerminate:(NSError *)error;

// 上报navigationstart
- (void)reportNavigationStart;

+ (void)registerInitParamsBlock:(NSDictionary*(^)(NSString *navigationID))initParamsBlock;

+ (void)registerFormatBlock:(NSDictionary*(^)(NSDictionary *record, NSString *_Nullable* _Nullable key))formatBlock;

// report current navigation page perf
- (void)reportCurrentNavigationPagePerf;

// judge whether can report in js cover
+ (BOOL)canReportInCover:(NSDictionary *)jsInfo;

@end

NS_ASSUME_NONNULL_END
