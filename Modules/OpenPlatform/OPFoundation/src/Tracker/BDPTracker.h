//
//  BDPTracker.h
//  Timor
//
//  Created by 维旭光 on 2018/12/7.
//

#import <Foundation/Foundation.h>
#import "BDPTrackerConstants.h"
#import "BDPTrackerEvents.h"
#import "BDPUniqueID.h"

@class JSContext;

NS_ASSUME_NONNULL_BEGIN

DEPRECATED_ATTRIBUTE

/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
@interface BDPTracker : NSObject

/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (instancetype)sharedInstance;

/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 计数事件
 * eventId 事件ID
 * attributes 埋点参数
 * uniqueId 通用参数的唯一标识，nil则使用默认通用参数
 * withCommonParams 是否发送通用参数
 */
+ (void)event:(NSString *)eventId attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (void)event:(NSString *)eventId attributes:(nullable NSDictionary *)attributes withCommonParams:(BOOL)withCommonParams uniqueID:(nullable BDPUniqueID *)uniqueID  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 计算事件，自动计算begin和end间的耗时，并在end事件埋点上报duration参数，begin，end方法需要成对调用
 * eventId 事件ID
 * keyName 事件的主键，用于配对begin和end事件，不能为空，前缀在BDPTrackerConstants中统一定义，不能与已有前缀重复。为避免事件重复，内部会将keyName与uniqueId拼接生成新的primaryKey，调用方需要保证begin和end传入的uniqueId一致
 * attributes 埋点参数
 * uniqueId 通用参数的唯一标识，nil则使用默认通用参数
 * reportStart 是否上报begin事件，NO则只用于记录时间戳，不上报
 */
+ (void)beginEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (void)beginEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(nullable NSDictionary *)attributes reportStart:(BOOL)reportStart uniqueID:(nullable BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (void)endEvent:(NSString *)eventId primaryKey :(NSString *)keyName attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 页面统计，begin，end需要成对调用
 * pagePath 页面的路径
 * query 页面的参数
 * hasWebview 页面中是否包含webview组件
 * uniqueId 通用参数的唯一标识，nil则使用默认通用参数
 * duration 页面停留时长，单位ms
 * exitType 页面退出类型
 */
+ (void)beginLogPageView:(NSString *)pagePath query:(NSString *)query hasWebview:(BOOL)hasWebview uniqueID:(nullable BDPUniqueID *)uniqueID  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (void)endLogPageView:(NSString *)pagePath query:(NSString *)query duration:(NSUInteger)duration exitType:(NSString *)exitType uniqueID:(nullable BDPUniqueID *)uniqueID  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/**
 * 读写标记，用于埋点需要用到的一些标记，比如入口类型
 */
+ (void)setTag:(NSString *)key value:(nullable NSString *)value DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");
/// BDPTracker 已废弃，请使用 OPMonitor 相关方法
+ (NSString *)getTag:(NSString *)key  DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 生成JSContext埋点的常用参数
 */
+ (NSMutableDictionary *)buildJSContextParams:(JSContext *)context DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");


/**
 * 埋点默认通用参数
 */
+ (NSDictionary *)defaultCommonParams DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 设置埋点默认通用参数
 * params 通用参数，会将params和defaultCommonParams做合并，同名字段将使用params中的字段
 * uniqueId 通用参数的唯一标识
 */
+ (void)setCommonParams:(NSDictionary *)params forUniqueID:(BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

/**
 * BDPTracker 已废弃，请使用 OPMonitor 相关方法
 * 移除埋点默认通用参数
 * uniqueId 通用参数的唯一标识
 */
+ (void)removeCommomParamsForUniqueID:(BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

/** 埋点相关任务在tracker队列中执行 */
+ (void)executeBlkInTrackerQueue:(dispatch_block_t)blk DEPRECATED_MSG_ATTRIBUTE("Use OPMonitor instead");

@end

#pragma mark - 端监控
/**
 端监控, 文档: https://slardar.bytedance.net/docs/115/165/2402/
 */
DEPRECATED_ATTRIBUTE
@interface BDPTracker (BDPMonitor)

/**
 BDPTracker 已废弃，请使用 OPMonitor 相关方法
 端监控某个服务的值, 并上报
 
 @param service 服务名称
 @param extra 额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
 @param uniqueId 如果需要通用参数, 则带上uniqueId
 */
+ (void)monitorService:(NSString *)service
                 extra:(nullable NSDictionary *)extra
  uniqueID:(nullable BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("USE OPMonitor instead");

/**
 BDPTracker 已废弃，请使用 OPMonitor 相关方法
 端监控某个服务的值, 并上报

 @param service 服务名称
 @param metric 字典仅支持一级key-value，是数值类型的信息，对应 Slardar 的 metric
 @param category 字典仅支持一级key-value，是维度信息，对应 Slardar 的 category
 @param extra 额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
 @param uniqueId 如果需要通用参数, 则带上uniqueId
 */
+ (void)monitorService:(NSString *)service
                metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric
              category:(nullable NSDictionary *)category
                 extra:(nullable NSDictionary *)extra
  uniqueID:(nullable BDPUniqueID *)uniqueID DEPRECATED_MSG_ATTRIBUTE("USE OPMonitor instead");

@end

NS_ASSUME_NONNULL_END
