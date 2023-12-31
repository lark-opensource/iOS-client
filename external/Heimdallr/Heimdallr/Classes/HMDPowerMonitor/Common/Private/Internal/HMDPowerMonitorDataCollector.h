//
//  BDPowerLogDataCollector.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import <Foundation/Foundation.h>
#import "HMDPowerMonitorDataListener.h"

NS_ASSUME_NONNULL_BEGIN

//@class BDPowerLogNetMetrics;
@class HMDPowerMonitorConfig;

@interface HMDPowerMonitorDataCollector : NSObject

@property(atomic,copy) HMDPowerMonitorConfig *config;

@property(nonatomic, assign) int collectInterval; //[5,60]

- (void)start;

- (void)stop;

- (void)queryDataFrom:(long long)start_sys_ts to:(long long)end_sys_ts
           completion:(void(^)(NSDictionary *data))completion;

- (void)clearCacheBefore:(long long)sys_ts;

//- (BDPowerLogNetMetrics *)currentNetMetrics;

- (void)updateAppState:(BOOL)isForeground;

- (void)addDataListener:(id<HMDPowerMonitorDataListener>)listener;

- (void)removeDataListener:(id<HMDPowerMonitorDataListener>)listener;

@end

NS_ASSUME_NONNULL_END
