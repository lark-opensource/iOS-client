//
//  BDPowerLogNetMetrics.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/12.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogNetMetricsInterval.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogNetMetrics : NSObject

@property (nonatomic, assign) long long timestamp;

@property (nonatomic, assign) long long sys_ts;

@property (nonatomic, assign) long long reqCount;

@property (nonatomic, assign) long long lastReqTime;

@property (nonatomic, assign) long long sendBytes;

@property (nonatomic, assign) long long recvBytes;

@property (nonatomic, assign) long long deviceSendBytes;

@property (nonatomic, assign) long long deviceRecvBytes;

@property (nonatomic, copy) NSArray<BDPowerLogNetMetricsInterval *> * _Nullable intervalDatas;

@end

NS_ASSUME_NONNULL_END
