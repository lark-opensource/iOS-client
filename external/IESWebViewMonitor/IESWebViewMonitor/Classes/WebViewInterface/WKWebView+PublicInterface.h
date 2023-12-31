//
//  WKWebView+PublicInterface.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/7/28.
//

#import <WebKit/WebKit.h>
#import <IESWebViewMonitor/BDWebView+BDWebViewMonitor.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDWebViewMonitorPerfExtType) {
    BDWebViewMonitorPerfExtType_preloadContainer,
    BDWebViewMonitorPerfExtType_prefetchData,
    BDWebViewMonitorPerfExtType_isOffline
};

typedef NS_ENUM(NSUInteger, BDWebViewMonitorPerfExtValue) {
    BDWebViewMonitorPerfExtValue_Unknown = 0,
    BDWebViewMonitorPerfExtValue_YES = 1,
    BDWebViewMonitorPerfExtValue_NO = 2
};

typedef NS_ENUM(NSUInteger, BDWebViewPerfReportTime) {
    BDWebViewPerfReportTime_Default = 0, //默认上报时机，在dealloc的时机触发上报，有最全的生命周期时间
    BDWebViewPerfReportTime_JSPerfReady = 1, //在前端JSSDK返回performance数据时上报，部分生命周期时间点会丢失，建议常驻缓存型页面使用
    BDWebViewPerfReportTime_Custom = 2, //自定义时间点触发上报，如果有特殊业务需求要用，可以先联系@周一川
};

@interface WKWebView (PublicInterface)

- (void)updatePerfExt:(BDWebViewMonitorPerfExtType)perfExtType withValue:(BDWebViewMonitorPerfExtValue)perfExtValue;

// 选择上报时机，如果不是特殊页面处理或者常驻缓存的页面，可以不调用，默认在webview的dealloc时机上报。
- (void)chooseReportTime:(BDWebViewPerfReportTime)reportTime;

// 如果选择的reportTime是手动触发，则需要业务方自己选择合适的时机调用此方法触发上报。
- (void)customTriggerReportPerf;

// 绑定kv到上报的nativebase中去，注意，此处配置建议kv都是用string类型，是可枚举的值，如bizId，ABTest等，避免识别问题，此处block会被持有，避免在内部使用webview造成循环引用。
- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block;

// 绑定虚拟aid到对应容器上
- (void)attachVirtualAid:(NSString *)virtualAid;
- (NSString *)fetchVirtualAid;

// 绑定容器UUID到实例
- (void)attachContainerUUID:(NSString *)containerUUID;

// 上报ContainerError事件
- (void)reportContainerError:(nullable NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(nullable NSString *)msg bizTag:(nullable NSString *)bizTag;

- (NSString *)bdlm_fetchCurrentUrl;
- (NSString *)bdlm_fetchBizTag;

@end

NS_ASSUME_NONNULL_END
