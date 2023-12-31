//
//  BDXMonitorProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>

#import "BDXServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXMonitorReportPlatform) {
    BDXMonitorReportPlatformWebView,
    BDXMonitorReportPlatformTimor, // 小程序
    BDXMonitorReportPlatformRN,
    BDXMonitorReportPlatformLynx,
    BDXMonitorReportPlatformFlutter,
};

typedef NS_ENUM(NSInteger, BDXMonitorResourceStatus) {
    BDXMonitorResourceStatusFail = -1, //加载失败的资源
    BDXMonitorResourceStatusGecko,     //命中gecko资源
    BDXMonitorResourceStatusCdn,       //从cdn加载
    BDXMonitorResourceStatusCdnCache,  //从cdn缓存中加载
    BDXMonitorResourceStatusBuildIn,   //加载打包的默认资源
    BDXMonitorResourceStatusOffline,   //加载已经下载到本地的离线资源
};

typedef NS_ENUM(NSInteger, BDXMonitorResourceType) {
    BDXMonitorResourceTypeTemplate, //主模版资源
    BDXMonitorResourceTypeRes,      //子资源
};

typedef NS_ENUM(NSInteger, BDXMonitorLogLevel) {
    BDXMonitorLogLevelVerbose = 0,
    BDXMonitorLogLevelDebug = 1, // Detailed information on the flow through the system.
    BDXMonitorLogLevelInfo = 2,  // Interesting runtime events (startup/shutdown),
                                 // should be cautious and keep to a minimum.
    BDXMonitorLogLevelWarn = 3,  // Other runtime situations that are undesirable
                                 // or unexpected, but not necessarily "wrong".
    BDXMonitorLogLevelError = 4, // Other runtime errors or unexpected conditions.
    BDXMonitorLogLevelFatal = 5,
};

@protocol BDXMonitorProtocol <BDXServiceProtocol>

/// 记录生命周期事件/时间戳的dictionary.
/// 生命周期事件(NSString*) : 时间戳(NSNumber*)
@property(nonatomic, readonly) NSDictionary *lifeCycleDictionary;

/// 容器自定义上报接口
/// @param eventName 事件名称
/// @param bizTag 业务标识（主要用于横跨app的业务，例如：直播等，默认为@""）
/// @param commonParams
/// 通用参数（通用key为kBDHMURL（必填）、kBDHMPid、kBDHMBid，其他key可业务方自行填入）
/// @param metric 主要用于统计duration
/// @param category 用于统计分布
/// @param extra 额外信息
/// @param platform 上报平台
/// @param aid 上报平台的虚拟aid
- (void)reportWithEventName:(nonnull NSString *)eventName bizTag:(nullable NSString *)bizTag commonParams:(nullable NSDictionary *)commonParams metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra platform:(BDXMonitorReportPlatform)platform aid:(NSString *)aid maySample:(BOOL)maySample;

/// 容器自定义上报资源状态接口，service会采样
/// @param containerView 容器对象，lynxView的实例或者WKWebView的实例
/// @param resourceStatus 资源状态，是Gecko,cdn，还是本地资源
/// @param resourceType 资源类型，主文档模版还是子资源
/// @param resourceUrl 资源链接
/// @param extraInfo 附加信息
/// @param extraMetrics 附加统计类信息
- (void)reportResourceStatus:(nullable __kindof UIView *)containerView resourceStatus:(BDXMonitorResourceStatus)resourceStatus resourceType:(BDXMonitorResourceType)resourceType resourceURL:(NSString *)resourceUrl resourceVersion:(NSString *)resourceVersion extraInfo:(NSDictionary* _Nullable)extraInfo extraMetrics:(NSDictionary* _Nullable)extraMetrics;

///为view配置虚拟aid
/// @param virtualAid 虚拟aid
/// @param view 需要配置的view
- (void)attachVirtualAid:(NSString *)virtualAid toView:(__kindof UIView *)view;

/// log接口
/// @param tag tag
/// @param level level
/// @param format format
- (void)logWithTag:(NSString *)tag level:(BDXMonitorLogLevel)level format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

- (void)clearLifeCycleEventDic;
- (void)trackLifeCycleWithEvent:(NSString *)eventName;
- (void)trackLifeCycleWithEvent:(NSString *)eventName timeStamp:(NSTimeInterval)timeStamp;

@end

NS_ASSUME_NONNULL_END
