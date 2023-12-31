//
//  HMDThreadInversionMonitor.h
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/3/15.
//

#import <Foundation/Foundation.h>
#import "HMDThreadMonitorConfig.h"
#import "HMDThreadMonitorPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadInversionMonitorPlugin : NSObject<HMDThreadMonitorPluginProtocol>

+ (instancetype)pluginInstance;
- (void)start;
- (void)stop;
- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config;

@end

NS_ASSUME_NONNULL_END
