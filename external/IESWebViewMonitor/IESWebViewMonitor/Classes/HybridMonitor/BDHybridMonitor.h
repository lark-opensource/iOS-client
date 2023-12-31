//
//  BDHybridMonitor.h
//  BDAlogProtocol
//
//  Created by renpengcheng on 2020/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kBDHMURL;
extern NSString * const kBDHMPid;
extern NSString * const kBDHMBid;

#pragma mark ContainerField
// 容器侧打点字段
extern NSString * const kBDHMContainerNameField;
extern NSString * const kBDHMSceneField;
extern NSString * const kBDHMContainerTraceIDField;

extern NSString * const kBDHMIsFallbackField;
extern NSString * const kBDHMInvokeFallbackField;
extern NSString * const kBDHMFallbackUrlField;
extern NSString * const kBDHMFallbackErrorCodeField;
extern NSString * const kBDHMFallbackErrorMsgField;

extern NSString * const kBDHMOpenTimeField;
extern NSString * const kBDHMPageIDField;
extern NSString * const kBDHMSchemaField;
extern NSString * const kBDHMTemplateResTypeField;

extern NSString * const kBDHMContainerInitStartField;
extern NSString * const kBDHMContainerInitEndField;

extern NSString * const kBDHMPrepareInitDataStartField;
extern NSString * const kBDHMPrepareInitDataEndField;

extern NSString * const kBDHMPrepareComponentStartField;
extern NSString * const kBDHMPrepareComponentEndField;

extern NSString * const kBDHMPrepareTemplateStartField;
extern NSString * const kBDHMPrepareTemplateEndField;

extern NSString * const kBDHMContainerLoadErrorCodeField;
extern NSString * const kBDHMContainerLoadErrorMsgField;

// ContainerError相关字段
extern NSString * const kBDHMContainerErrorCodeField;
extern NSString * const kBDHMContainerErrorMsgField;
extern NSString * const kBDHMContainerVirtualAidField;
extern NSString * const kBDHMContainerBizTagField;
#pragma mark -

typedef NS_ENUM(NSInteger, BDHybridCustomReportType) {
    BDHybridCustomReportDirectly
};

typedef NS_ENUM(NSInteger, BDHybridCustomReportPlatform) {
    BDCustomReportWebView,
    BDCustomReportTimor, // 小程序
    BDCustomReportRN,
    BDCustomReportLynx,
    BDCustomReportFlutter,
};

typedef NS_ENUM(NSInteger, BDHM_ContainerType) {
    BDHM_ContainerTypeLynx,
    BDHM_ContainerTypeWeb,
    BDHM_ContainerTypeNative
};

typedef NS_ENUM(NSInteger, BDHM_ResourceStatus) {
    BDHM_ResourceStatusFail = -1,       //加载失败的资源
    BDHM_ResourceStatusGurd,           //命中gecko资源
    BDHM_ResourceStatusCdn,             //从cdn加载
    BDHM_ResourceStatusCdnCache,        //从cdn缓存中加载
    BDHM_ResourceStatusBuildIn,         //加载打包的默认资源
    BDHM_ResourceStatusOffline,         //加载已经下载到本地的离线资源
};

typedef NS_ENUM(NSInteger, BDHM_ResourceType) {
    BDHM_ResourceTypeTemplate,  //主模版资源
    BDHM_ResourceTypeRes,       //子资源
};

typedef NS_ENUM(NSInteger, BDHM_FallBackType) {
    BDHM_FallBackTypeSchema,    //解析schema出错引起的fallback
    BDHM_FallBackTypeLoad,      //加载时出错引起的fallback
};

typedef struct BDHM_ContainerError_t {
    NSInteger error_code;
    NSString * error_msg;
    NSString * virtualAid;
    NSString * bizTag;
} BDHM_ContainerError;

@interface BDHybridMonitor : NSObject

/// 生成容器事件上报的唯一标识,后期会和Lynx/WebView实例关联
+ (nonnull NSString *)generateIDForContainer;

/// 标记uuid无效,标记后无法再用该uuid上报数据; andData 表示是否同步删除数据,如果没有View实例,建议直接删除,否则会在View dealloc时清理
+ (void)invalidateID:(nonnull NSString *)uuid andData:(BOOL)willDelete;

/// 如果传入的 uuid 已经被 invalidate,就会删除保存的容器数据.  isForce=YES 表示强制删除,不关心uuid是否被invalidate
+ (void)deleteData:(nonnull NSString *)uuid isForce:(BOOL)isForce;

/// 容器创建Lynx/WebView后,将generateIDForContainer生成的ID同View实例关联
+ (void)attach:(nonnull NSString *)uuid webView:(nonnull id)webView;
+ (void)attach:(nonnull NSString *)uuid LynxView:(nonnull id)lynxView;

/// 用于上报容器加载错误
/// errorInfo[kBDHMContainerErrorCodeField]  -  NSInteger   - 错误码
/// errorInfo[kBDHMContainerErrorMsgField]    -  NSString    - 错误描述信息
/// errorInfo{kBDHMContainerVirtualAidField]   -  NSString    - 注册的virtualAid
/// errorInfo[kBDHMContainerBizTagField]        -  NSString    - 注册的bizTag,用于上报区分serviceName
+ (void)reportContainerError:(nullable id)view withID:(nullable NSString *)uuid withError:(NSDictionary *)errorInfo;

/// 容器上报接口
+ (void)collectBoolean:(nonnull NSString *)uuid
                 field:(nonnull NSString *)field
                  data:(BOOL)data;
+ (void)collectString:(nonnull NSString *)uuid
                field:(nonnull NSString *)field
                 data:(nullable NSString *)data;
+ (void)collectLong:(nonnull NSString *)uuid
              field:(nonnull NSString *)field
               data:(long long)data;
+ (void)collectInt:(nonnull NSString *)uuid
             field:(nonnull NSString *)field
              data:(int)data;

// block will run on monitor-thread
+ (void)fetchContainerData:(nonnull NSString *)uuid block:(void (^)(NSDictionary *containerBase, NSDictionary *containerInfo))dataBlock;

/// lynx容器自定义上报接口，接入了lynx性能上报的才能用这个接口，注意：上报量大的允许采样的请用带maySample的接口
+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName
                             LynxView:(nonnull id)lynxView
                               metric:(nullable NSDictionary *)metric
                             category:(nullable NSDictionary *)category
                                extra:(nullable NSDictionary *)extra;
+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName
                             LynxView:(nonnull id)lynxView
                               metric:(nullable NSDictionary *)metric
                             category:(nullable NSDictionary *)category
                                extra:(nullable NSDictionary *)extra
                            maySample:(BOOL)maySample;
+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName
                             LynxView:(nonnull id)lynxView
                               metric:(nullable NSDictionary *)metric
                             category:(nullable NSDictionary *)category
                                extra:(nullable NSDictionary *)extra
                               timing:(nullable NSDictionary *)timing
                            maySample:(BOOL)maySample;

/// web容器自定义上报接口，接入了web性能上报的才能用这个接口，注意：上报量大的允许采样的请用带maySample的接口
+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra;
+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra
                           maySample:(BOOL)maySample;
+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra
                              timing:(nullable NSDictionary *)timing
                           maySample:(BOOL)maySample;

/// 容器自定义上报接口，默认会上报到宿主aid中
+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform;

/// 容器自定义上报接口
/// @param eventName 时间名称
/// @param bizTag 业务标识（主要用于横跨app的业务，例如：直播等，默认为@""）
/// @param commonParams 通用参数（通用key为kBDHMURL（必填）、kBDHMPid、kBDHMBid，其他key可业务方自行填入）
/// @param metric 主要用于统计duration
/// @param category 用于统计分布
/// @param extra 额外信息
/// @param reportType 上报类型（预留）
/// @param platform 上报平台
/// @param aid 上报平台的虚拟aid
+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform
                        aid:(NSString *)aid;

/// 容器自定义上报接口
/// @param eventName 时间名称
/// @param bizTag 业务标识（主要用于横跨app的业务，例如：直播等，默认为@""）
/// @param commonParams 通用参数（通用key为kBDHMURL（必填）、kBDHMPid、kBDHMBid，其他key可业务方自行填入）
/// @param metric 主要用于统计duration
/// @param category 用于统计分布
/// @param extra 额外信息
/// @param reportType 上报类型（预留）
/// @param platform 上报平台
/// @param aid 上报平台的虚拟aid
/// @param maySample 此上报是否允许采样，性能相关类建议加上，避免影响其他上报
+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform
                        aid:(NSString *)aid
                  maySample:(BOOL)maySample;

/// 容器自定义上报资源状态接口，service会采样
/// @param containerView 容器对象，lynxView的实例或者WKWebView的实例
/// @param resourceStatus 资源状态，是Gecko,cdn，还是本地资源
/// @param resourceType 资源类型，主文档模版还是子资源
/// @param resourceUrl 资源链接
+ (void)reportResourceStatus:(UIView *)containerView
              resourceStatus:(BDHM_ResourceStatus)resourceStatus
                resourceType:(BDHM_ResourceType)resourceType
                 resourceURL:(NSString *)resourceUrl;

+ (void)reportResourceStatus:(UIView *)containerView
              resourceStatus:(BDHM_ResourceStatus)resourceStatus
                resourceType:(BDHM_ResourceType)resourceType
                 resourceURL:(NSString *)resourceUrl
             resourceVersion:(NSString *)resourceVersion;


/// 容器自定义上报fallback的情况
/// @param fallBackType fallback类型
/// @param sourceUrl fallback前url
/// @param sourceContainer fallback前容器类型
/// @param targetUrl fallback后url
/// @param targetContainer fallback后容器类型
+ (void)reportFallBack:(BDHM_FallBackType)fallBackType sourceUrl:(NSString *)sourceUrl sourceContainer:(BDHM_ContainerType)sourceContainer targetUrl:(NSString *)targetUrl targetContainer:(BDHM_ContainerType)targetContainer aid:(NSString *)aid;

@end

NS_ASSUME_NONNULL_END
