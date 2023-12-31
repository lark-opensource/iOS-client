//
//  TTMonitor.h
//  Heimdallr
//
//  Created by joy on 2018/3/25.
//

#import <Foundation/Foundation.h>
#import "HMDInjectedInfo.h"
#import "HMDTTMonitorUserInfo.h"
typedef NS_ENUM(NSInteger, HMDTTMonitorTrackerType)
{
    HMDTTMonitorTrackerTypeUnknown = 0,
    HMDTTMonitorTrackerTypeAPIError = 1,
    HMDTTMonitorTrackerTypeAPISample = 2,
    HMDTTMonitorTrackerTypeDNSReport = 3,
    HMDTTMonitorTrackerTypeDebug = 4,//线上实时处理， 注意量不要太大
    HMDTTMonitorTrackerTypeAPIAll = 5,//针对人群采样
    HMDTTMonitorTrackerTypeHTTPHiJack = 6,//针对人群采样
    HMDTTMonitorTrackerTypeLocalLog = 8, // 定向上报本地日志
};

extern NSString * _Nonnull const kHMDTTMonitorServiceLogTypeStr;

typedef void(^HMDTTMonitorLodModifyBlock)(NSString * _Nullable logType, NSString * _Nullable serviceName, NSDictionary * _Nullable * _Nullable data, BOOL * _Nonnull isAbandoned);

@interface HMDTTMonitor : NSObject

// 默认应该使用的实例，此时的 aid 使用的就是接入的 App 的 aid
+ (nonnull HMDTTMonitor *)defaultManager;

/// 指定自己的 aid 和一些必要参数
/// sdk 事件监控调用的时候, 初始化 injectedInfo 不能为空
- (nonnull instancetype)initMonitorWithAppID:(nonnull NSString *)appID injectedInfo:(nullable HMDTTMonitorUserInfo *)info;
- (nonnull id)init __attribute__((unavailable("please use initMonitorWithAppID:injectedInfo:")));
+ (nonnull instancetype)new __attribute__((unavailable("please use initMonitorWithAppID:injectedInfo:")));


/**
 * 设置日志修改block，可以修改日志或者丢弃日志
 */
+ (void)setLogModifyBlock:(HMDTTMonitorLodModifyBlock _Nullable )block;

/**
 打开或者关闭TTMonitor接口的Hook开关，开的话用于TTMonitor和Heimdallr两套SDK并且不修改原有埋点接口调用的同时将埋点搜集和上报交由Heimdallr托管
 
 @param needHook 是否打开TTMonitor接口的Hook开关
 */
- (void)hookTTMonitorInterfaceIfNeeded:(nonnull NSNumber *)needHook;

/**
 *  监控某个service的值，并上报
 *
 *  @param serviceName NSString 类型的名称
 *  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
 *  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
 *  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
 */
- (void)hmdTrackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue;

/**
*  监控某个service的值，并上报 ;  ⚠️不建议将此方法作为默认的方法, 只在特殊情况下需要数据马上存储到本地的情况下设置
*
*  @param serviceName NSString 类型的名称
*  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
*  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
*  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
*  @param syncWrite  是否同步写入数据库 -
*/
- (void)hmdTrackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue syncWrite:(BOOL)syncWrite;

/**
*  监控某个service的值，并立即上报，不进行采样率的判断 ;  ⚠️不建议将此方法作为默认的方法, 只在特殊情况下需要事件马上上传的时候使用
*
*  @param serviceName NSString 类型的名称
*  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
*  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
*  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
*/
- (void)hmdUploadImmediatelyTrackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue;

/**
*  监控某个service的值，如果采样命中或者本地无采样配置则立即上报 ;  ⚠️不建议将此方法作为默认的方法, 只在特殊情况下需要事件马上上传的时候使用
*
*  @param serviceName NSString 类型的名称
*  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
*  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
*  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
*/
- (void)hmdUploadImmediatelyIfNeedTrackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue;

/**
*  自定义事件：监控某个log_type的值，并上报
*
*  @param data             上报数据字典
*  @param logType      自定义事件名称，NSString 类型
*/
- (void)hmdTrackData:(nullable NSDictionary *)data
          logTypeStr:(nonnull NSString *)logType;

/**
*  自定义事件：监控某个log_type的值，如果采样命中或者本地无采样配置则立即上报 ;  ⚠️不建议将此方法作为默认的方法, 只在特殊情况下需要事件马上上传的时候使用
*
*  @param data             上报数据字典
*  @param logType      自定义事件名称，NSString 类型
*/
- (void)hmdUploadImmediatelyIfNeedTrackData:(nullable NSDictionary *)data
                                 logTypeStr:(nonnull NSString *)logType;

/**
*  自定义事件：监控某个log_type的值，如果采样命中或者本地无采样配置则立即上报 ;  ⚠️不建议将此方法作为默认的方法, 只在特殊情况下需要事件马上上传的时候使用
*
*  @param data             上报数据字典
*  @param logType      自定义事件名称，NSString 类型
*/
- (void)hmdUploadImmediatelyTrackData:(nullable NSDictionary *)data
                           logTypeStr:(nonnull NSString *)logType;

/**
*  获取事件采样率，只适用于采样率小且耗时的埋点 ; ⚠️无须业务方自己判断是否命中采样；未从网络获取到采样率时，同样返回NO，所以不建议业务方自己判断
*
*  @param logTypeStr  传入nil，则为默认的logType
*  @param serviceName 事件名称
*/
- (BOOL)needUploadWithlogTypeStr:(nullable NSString *)logTypeStr serviceName:(nonnull NSString *)serviceName;

/**
 * 获取log type采样率
 * ⚠️无须业务方自己判断是否命中采样；未从网络获取到采样率时，同样返回NO，所以不建议业务方自己判断
 *
 *  @param logType 自定义事件名
 */
- (BOOL)logTypeEnabled:(nullable NSString *)logType;

/**
 * 获取service type的采样率
 * ⚠️无须业务方自己判断是否命中采样；未从网络获取到采样率时，同样返回NO，所以不建议业务方自己判断
 * @param serviceType 事件名称
 */
- (BOOL)serviceTypeEnabled:(nullable NSString *)serviceType;

/**
*  获取事件模块配置是否可用；⚠️当可用时，才是业务方自己配置的采样率
*/
- (BOOL)configurationAvailable;

/**
*  针对MT无法上报直播埋点的临时方案，⚠️其他App无需调用
*
*  @param ignore 传入YES，"ttlive_"前缀的事件，忽略log_type，采样率只判断service_name
*/
- (void)configTTLiveEventIgnoreLogType:(BOOL)ignore;

#pragma mark -- The following interfaces are to be discarded.

//  临时接口，代表HMDTTMonitorTracker的所有实例是否共享同一个队列
+ (void)setUseShareQueueStrategy:(BOOL)on __attribute__((deprecated("the method id deprecated and the queue-sharing strategy is solidified as YES")));

/**
 *  监控某个service的值，并上报
 *
 *  @param serviceName NSString 类型的名称
 *  @param value       是一个id类型的，可以传一个nsnumber，nsstring，字典， 字典必须是key-value形式，而且只有一级
 *  @param extraValue  额外信息，方便追查问题使用
 */
- (void)hmdTrackService:(nonnull NSString *)serviceName
                  value:(nullable id)value
                  extra:(nullable NSDictionary *)extraValue __attribute__((deprecated("deprecated. Please use new interface hmdTrackService: metric: category: extra:")));

/**
 *  监控某个service的状态，并上报
 *
 *  @param serviceName NSString 类型的名称
 *  @param status      是一个int类型的值，可枚举的几种状态
 *  @param extraValue  额外信息，方便追查使用
 */
- (void)hmdTrackService:(nonnull NSString *)serviceName
                 status:(NSInteger)status
                  extra:(nullable NSDictionary *)extraValue __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));

- (void)hmdTrackService:(nonnull NSString *)serviceName
             attributes:(nullable NSDictionary *)attributes __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));

- (void)hmdTrackData:(nullable NSDictionary *)data
                type:(HMDTTMonitorTrackerType)type __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));


#pragma mark -- The following interfaces are to be discarded 2018.03.30
/**
 *  监控统计-count打点  type和label非常重要，是在服务端区分不同事件的唯一参考，譬如
 [[TTMonitor shareManager] event:@"monitor_fps" label:@"feed" count:60 needAggregate:NO];
 上面的这条统计，在服务端metrics这样查询：client.monitor_fps.feed.ios 就可以查到了。当然还可以继续.其他信息（版本号等，但
 但client.monitor.monitor_fps.feed是必须的）。
 *
 *  @param type     监控的类型，自己定义  相当于title
 *  @param label    可以作为一种简要的解释 相当于subtitle
 *  @param count    具体数字
 *  @param needAggr 要不要聚合   聚合就会求均值
 */
- (void)event:(nonnull NSString *)type label:(nullable NSString *)label count:(NSUInteger)count needAggregate:(BOOL)needAggr __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));

/**
 *   监控统计-count打点  默认count是1
 *
 *  @param type     监控的类型，自己定义  相当于title
 *  @param label    可以作为一种简要的解释 相当于subtitle
 *  @param needAggr 要不要聚合   聚合就会求均值
 */
- (void)event:(nonnull NSString *)type label:(nullable NSString *)label needAggregate:(BOOL)needAggr __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));

/**
 *  监控统计-time打点  type和label非常重要，是在服务端区分不同事件的唯一参考，譬如
 [[TTMonitor shareManager] event:@"monitor_launch" label:@"duratin" count:60 needAggregate:NO];
 上面的这条统计，在服务端metrics这样查询：client.monitor_launch.duratin.ios 就可以查到了。当然还可以继续.其他信息（版本号等，但
 但client.monitor.monitor_launch.duratin.ios是必须的）。
 *
 *  @param type     监控的类型，自己定义  相当于title
 *  @param label    可以作为一种简要的解释 相当于subtitle
 *  @param duration    具体数字
 *  @param needAggr 要不要聚合   聚合就会求均值
 */
- (void)event:(nonnull NSString *)type label:(nullable NSString *)label duration:(float)duration needAggregate:(BOOL)needAggr __attribute__((deprecated("deprecated. Please use hmdTrackService: metric: category: extra:")));

@end
