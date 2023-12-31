//
//  OPMonitorService.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "OPMonitor.h"
#import "OPMonitorServiceConfig.h"
#import "OPMonitorServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPMonitorService : NSObject <OPMonitorServiceProtocol, OPMonitorReportProtocol, OPMonitorLogProtocol>

/// 配置
@property (nonatomic, strong, nonnull, readwrite) OPMonitorServiceConfig *config;

- (instancetype _Nonnull)initWithConfig:(OPMonitorServiceConfig * _Nullable)config;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;


/// 获取全局默认 service
+ (id<OPMonitorServiceProtocol> _Nonnull)defaultService;

/// 全局初始化，传入一个指定 config
+ (void)setup:(OPMonitorServiceConfig * _Nonnull)config;

@end

NS_ASSUME_NONNULL_END
