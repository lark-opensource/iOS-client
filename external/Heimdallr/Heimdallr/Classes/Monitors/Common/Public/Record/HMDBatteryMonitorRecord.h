//
//  HMDBatteryMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

@protocol HMDRecordStoreObject;

@interface HMDBatteryMonitorRecord : HMDMonitorRecord

@property (nonatomic, assign) UIDeviceBatteryState batteryState;
@property (nonatomic, assign) HMDMonitorRecordValue batteryLevel;
@property (nonatomic, assign) HMDMonitorRecordValue pageUsage;
@property (nonatomic, assign) HMDMonitorRecordValue perMinuteUsage;
@property (nonatomic, assign) HMDMonitorRecordValue sessionUsage;
@end
