//
//  OPMonitorServiceConfig.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "OPMonitorReportPlatform.h"
NS_ASSUME_NONNULL_BEGIN

@class OPMonitorServiceRemoteConfig;

typedef NS_ENUM(NSUInteger, OPMonitorLogLevel) {
    OPMonitorLogLevelDebug = 1,
    OPMonitorLogLevelInfo  = 2,
    OPMonitorLogLevelWarn  = 3,
    OPMonitorLogLevelError = 4,
    OPMonitorLogLevelFatal = 5
};

/// 埋点上报协议
@protocol OPMonitorReportProtocol <NSObject>

@required

/**
 * 埋点上报
 * @param name 事件名
 * @param metrics 统计值类型数据集合
 * @param categories 枚举/分类类型数据集合
 */
- (void)reportWithName:(NSString * _Nonnull)name
               metrics:(NSDictionary<NSString *, id> * _Nullable)metrics
            categories:(NSDictionary<NSString *, id> * _Nullable)categories
              platform:(OPMonitorReportPlatform)platform;

@end

/// 日志协议
@protocol OPMonitorLogProtocol <NSObject>

@required

/// 日志打印
- (void)logWithLevel:(OPMonitorLogLevel)level tag:(NSString * _Nullable)tag file:(NSString * _Nullable)file function:(NSString * _Nullable)function line:(NSInteger)line content:(NSString * _Nullable)content;

@end

/// 上报服务配置
@interface OPMonitorServiceConfig : NSObject <OPMonitorReportProtocol, OPMonitorLogProtocol>

/// 全局默认远端配置
@property (class, nonatomic, strong, nonnull, readonly) OPMonitorServiceRemoteConfig *globalRemoteConfig;

/// 远端配置（默认值为 OPMonitorServiceConfig.globalRemoteConfig ）
@property (nonatomic, strong, nonnull, readonly) OPMonitorServiceRemoteConfig *remoteConfig;

/// 缺省事件名，未指定事件名时被作为默认值
@property (nonatomic, copy, nonnull, readwrite) NSString *defaultName;

/// 上报能力
@property (nonatomic, weak, nullable, readonly) id<OPMonitorReportProtocol> reportProtocol;

/// 日志能力
@property (nonatomic, weak, nullable, readonly) id<OPMonitorLogProtocol> logProtocol;

/// 公共 metrics 参数，在埋点创建时作为默认值
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, id> *commonMetrics;

/// 公共 categories 参数，在埋点创建时作为默认值
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, id> *commonCatrgories;

/// 公共 tags 参数，在埋点创建时作为默认值
@property (nonatomic, copy, nullable, readwrite) NSSet<NSString *> *commonTags;

/// reportDebugEnable， 是否要在Debug下做上传，默认为false
@property (nonatomic, assign, readwrite) BOOL reportDebugEnable;

/// 默认打点平台
@property (nonatomic, assign, readwrite) OPMonitorReportPlatform defaultPlatform;

/// 获取默认上报使用的 event_name
- (NSString * _Nonnull)defaultEventNameForDomain: (NSString * _Nullable) domain;

- (instancetype _Nonnull)initWithReportProtocol:(id<OPMonitorReportProtocol> _Nonnull)reportProtocol
                                    logProtocol:(id<OPMonitorLogProtocol> _Nonnull)logProtocol;

/// 注入上报、日志能力
/// @param config 外部实现的 Config，包含日志、上报能力
- (void)injectConfigAbilityFrom:(OPMonitorServiceConfig * _Nonnull)config;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
