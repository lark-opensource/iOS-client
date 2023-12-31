//
//  BDImageMonitorManager.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface BDImageMonitorManager : NSObject

/**
 *  上报
 *
 *  @param data 上报的字典信息
 *  @param logType   日志类型
 */
+ (void)trackData:(NSDictionary *)data logTypeStr:(NSString *)logType;

/**
 *  上报
 *
 *  @param serviceName  serviceName
 *  @param status       是一个float类型的，不可枚举
 *  @param extraValue  额外信息，方便追查问题使用
 */
+ (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue;

/**
 *  监控某个service的值，并上报
 *
 *  @param serviceName NSString 类型的名称
 *  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
 *  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
 *  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
 */
+ (void)trackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue;

NS_ASSUME_NONNULL_END
@end
