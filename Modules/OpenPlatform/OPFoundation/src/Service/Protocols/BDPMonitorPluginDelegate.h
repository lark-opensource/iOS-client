//
//  BDPMonitorPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2019/2/28.
//

#ifndef BDPMonitorPluginDelegate_h
#define BDPMonitorPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import <ECOProbe/OPMonitorReportPlatform.h>

@protocol BDPMonitorPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 监控上报， Heimdallr 需要是 0.6.28-rc.0 的以上版本
 * @param name NSString 类型的名称
 * @param metric 字典必须是key-value形式， 而且只有一级，是数值类型的信息，对应Slardar的Mmetric
 * @param category 字典必须是key-value形式，而且只有一级，对应Slardar的 category， 要求h可枚举的字符串。
 * @param extraValue 额外信息，方便追查问题使用， Slardar 平台不会进行展示，hive中可以查询。
 */
- (void)bdp_monitorEventName:(NSString *)name metric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue platform:(OPMonitorReportPlatform)platform;

@end

#endif /* BDPMonitorPluginDelegate_h */
