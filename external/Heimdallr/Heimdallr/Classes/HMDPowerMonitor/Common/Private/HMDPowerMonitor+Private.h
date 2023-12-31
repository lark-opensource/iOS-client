//
//  HMDPowerMonitor+Private.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/27.
//

#import "HMDPowerMonitor.h"
#import "HMDPowerMonitorDataListener.h"

NS_ASSUME_NONNULL_BEGIN

//@class BDPowerLogNetMetrics;

@interface HMDPowerMonitor (Private)

+ (NSInteger)currentUserInterfaceStyle;

+ (void)queryDataFrom:(long long)fromTS to:(long long)toTS
           completion:(void(^)(NSDictionary *data))completion;

//+ (BDPowerLogNetMetrics *)currentNetMetrics;

+ (void)addDataListener:(id<HMDPowerMonitorDataListener>)listener;

@end

NS_ASSUME_NONNULL_END
