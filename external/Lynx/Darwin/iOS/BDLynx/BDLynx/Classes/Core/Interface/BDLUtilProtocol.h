//
//  BDLUtilProtocol.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *调用宿主基础功能
 */

@protocol BDLUtilProtocol <NSObject>

/**
 * 单例对象
 */
+ (instancetype)sharedInstance;

@optional

/**
 * should use alog to println
 */
- (void)info:(NSString *)info __attribute__((deprecated("no need to implement")));

- (void)error:(NSString *)error __attribute__((deprecated("no need to implement")));

/**
  this log is very important and should upload as an event
 */
- (void)keyLog:(NSString *)message;

/**
 *  Sladar 监控
 *  监控某个service的值，并上报
 *  @param serviceName 埋点
 *  @param value 是一个float类型的，不可枚举
 *  @param extraValue 额外信息，方便追查问题使用
 */
- (void)trackService:(NSString *)serviceName value:(float)value extra:(NSDictionary *)extraValue;

/**
 *  Sladar 监控
 *  监控某个service的值，并上报
 *  @param data 上报字典
 *  @param type logTypeStr
 */
- (void)trackData:(NSDictionary *)data logTypeStr:(NSString *)type;

/**
 * 埋点上报
 * @param eventName 埋点名
 * @param params 自定义参数
 */
- (void)event:(NSString *)eventName params:(NSDictionary *)params;

/**
 * schema 跳转
 * @param schema schema名
 */

- (void)openSchema:(NSString *)schema;

/**
 * 监控上报， Heimdallr 需要是 0.6.28-rc.0 的以上版本
 * @param name NSString 类型的名称
 * @param metric 字典必须是key-value形式， 而且只有一级，是数值类型的信息，对应Slardar的Mmetric
 * @param category 字典必须是key-value形式，而且只有一级，对应Slardar的 category，
 * 要求h可枚举的字符串。
 * @param extraValue 额外信息，方便追查问题使用， Slardar 平台不会进行展示，hive中可以查询。
 */
- (void)monitorEventName:(NSString *)name
                  metric:(NSDictionary *)metric
                category:(NSDictionary *)category
                   extra:(NSDictionary *)extraValue;

/**
 * 日志上报，主要用于用户反馈定位问题，及其他特殊上报场景。
 * @param fetchStartTime 上报log文件的起始时间
 * @param fetchEndTime 上报log文件的截止时间
 * @param scene 主动上报log的场景，直接在平台上展示，如"崩溃"或者"用户主动反馈"
 */
- (void)reportLogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                       fetchEndTime:(NSTimeInterval)fetchEndTime
                              scene:(NSString *)scene;

@end

NS_ASSUME_NONNULL_END
