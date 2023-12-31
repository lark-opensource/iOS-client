//
//  BDPLLogMonitorConfig.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPLLogMonitorConfig : NSObject<NSCopying>

@property (nonatomic, assign) int timewindow;

@property (nonatomic, assign) int logThreshold;

@property (nonatomic, assign, readonly) double logThresholdPerSecond;

@property (nonatomic, assign) BOOL enableLogCountMetrics;

@end

NS_ASSUME_NONNULL_END
