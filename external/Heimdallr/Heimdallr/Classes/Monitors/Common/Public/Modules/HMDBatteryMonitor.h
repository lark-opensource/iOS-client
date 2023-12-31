//
//  HMDBatteryMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"
#import <UIKit/UIKit.h>

extern NSString * _Nonnull const kHMDModuleBatteryMonitor;//电量监控

@interface HMDBatteryMonitorConfig : HMDMonitorConfig

@end

@interface HMDBatteryMonitor : HMDMonitor

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

@end
