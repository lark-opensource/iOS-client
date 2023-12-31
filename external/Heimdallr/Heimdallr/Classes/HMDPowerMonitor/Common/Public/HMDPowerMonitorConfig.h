//
//  BDPowerLogConfig.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/29.
//

#import "HMDMonitorConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDPowerMonitorConfig : HMDMonitorConfig

@property (nonatomic,assign) int sceneUpdateSessionMinTime; // sec = 2s

@property (nonatomic,assign) BOOL disableSceneUpdateSession; // no

@property (nonatomic,assign) BOOL includeSceneUpdateBackgroundSession; // no

@end

NS_ASSUME_NONNULL_END
