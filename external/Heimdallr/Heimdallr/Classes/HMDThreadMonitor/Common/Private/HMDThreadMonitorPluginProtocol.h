//
//  HMDThreadMonitorPluginProtocol.h
//  Pods
//
//  Created by zhangxiao on 2021/9/9.
//

#ifndef HMDThreadMonitorPluginProtocol_h
#define HMDThreadMonitorPluginProtocol_h

@class HMDThreadMonitorConfig;

@protocol HMDThreadMonitorPluginProtocol <NSObject>

@required

+ (instancetype)pluginInstance;
- (void)start;
- (void)stop;
- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config;

@end

#endif /* HMDThreadMonitorPluginProtocol_h */
