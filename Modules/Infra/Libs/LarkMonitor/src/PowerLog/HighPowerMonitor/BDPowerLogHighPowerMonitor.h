//
//  BDPowerLogHighPowerMonitor.h
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogHighPowerConfig.h"
#import "BDPowerLogCPUMetrics.h"
#import "BDPowerLogDataListener.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BDPLLogMonitorDelegate;
@interface BDPowerLogHighPowerMonitor : NSObject<BDPowerLogDataListener,BDPLLogMonitorDelegate>

@property(atomic, copy) BDPowerLogHighPowerConfig *config;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
