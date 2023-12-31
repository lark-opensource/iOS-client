//
//  HMDThreadSamplingMonitorPlugin.h
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/2.
//

#import <Foundation/Foundation.h>
#import "HMDThreadMonitorPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDThreadMonitorConfig;

@interface HMDThreadSamplingMonitorPlugin : NSObject <HMDThreadMonitorPluginProtocol>

+ (instancetype)pluginInstance;
- (void)start;
- (void)stop;
- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config;

@end

NS_ASSUME_NONNULL_END
