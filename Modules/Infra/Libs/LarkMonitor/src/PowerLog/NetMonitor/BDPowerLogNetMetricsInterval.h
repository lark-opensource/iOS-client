//
//  BDPowerLogNetMetricsInterval.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/12.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogNetEvent.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogNetMetricsInterval : NSObject

@property (nonatomic, assign) long long reqCount;

@property (nonatomic, assign) long long sendBytes;

@property (nonatomic, assign) long long recvBytes;

@property (nonatomic, strong) BDPowerLogNetEvent *_Nullable firstEvent;

@property (nonatomic, strong) BDPowerLogNetEvent *_Nullable lastEvent;

@end

NS_ASSUME_NONNULL_END
