//
//  BDPMonitorCenter.h
//  Timor
//
//  Created by MacPu on 2018/10/19.
//

#import <Foundation/Foundation.h>
#import "BDPMonitor.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPMonitorCenter : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedInstance;

- (void)addMonitor:(id<BDPMonitorProtocol>)monitor;
- (void)removeMonitror:(id<BDPMonitorProtocol>)monitor;
- (NSArray<id<BDPMonitorProtocol>>*)getMonitors;

// 自定义收集频率
- (void)customCollectInterval:(NSTimeInterval)interval
              reportIntervals:(NSTimeInterval)reportInterval
         reportFirstFireDelay:(NSTimeInterval)reportFirstFireDelay;
// 取消自定义频率
- (void)resetAllIntervalToDefault;

@end

NS_ASSUME_NONNULL_END
