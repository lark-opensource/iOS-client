//
//  OPMonitorServiceProtocol.h
//  ECOProbe
//
//  Created by qsc on 2021/3/30.
//

#ifndef OPMonitorServiceProtocol_h
#define OPMonitorServiceProtocol_h

#import "OPMonitorReportPlatform.h"

@class OPMonitorEvent;
@class OPMonitorServiceConfig;

@protocol OPMonitorServiceProtocol <NSObject>

@required

/// 埋点提交
- (void)flush:(OPMonitorEvent * _Nonnull)monitor platform:(OPMonitorReportPlatform)platform;

/// 埋点日志
- (void)log:(OPMonitorEvent * _Nonnull)monitor;

/// 获取配置
- (OPMonitorServiceConfig * _Nonnull)config;

/// Flush 前,是否执行 Monitor 的附加 Task
- (BOOL)shouldExecuteTask:(NSString *) name;

@end

#endif /* OPMonitorServiceProtocol_h */
