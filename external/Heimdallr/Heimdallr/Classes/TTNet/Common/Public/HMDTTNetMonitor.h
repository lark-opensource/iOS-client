//
//  HMDTTNetMonitor.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/29.
//

#import <Foundation/Foundation.h>

@class HMDHTTPDetailRecord;

@interface HMDTTNetMonitor : NSObject

+ (nonnull instancetype)sharedMonitor;

- (void)start;
- (void)stop;

/**
 TTNet是否是Chromium内核

 @return  TTNet是否是Chromium内核
 */
- (nonnull NSNumber *)isTTNetChromiumCore;

/**
 网络配置发生了更新
 */
- (void)updateTTNetConfig;

/**
 hook TTNet内核切换的开关设置，调奇数次hook，调偶数次还原
 */
+ (void)changeMonitorTTNetImpSwitch;

@end
