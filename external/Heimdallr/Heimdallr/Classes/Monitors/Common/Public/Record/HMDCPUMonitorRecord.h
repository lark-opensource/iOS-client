//
//  HMDCPUMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

@interface HMDCPUMonitorRecord : HMDMonitorRecord
@property (nonatomic, assign) HMDMonitorRecordValue totalUsage;
@property (nonatomic, assign) HMDMonitorRecordValue systemUsage;
@property (nonatomic, assign) HMDMonitorRecordValue userUsage;
@property (nonatomic, assign) HMDMonitorRecordValue appUsage;
@property (nonatomic, assign) HMDMonitorRecordValue nice;
@property (nonatomic, assign) HMDMonitorRecordValue idle;
@property (nonatomic, assign) HMDMonitorRecordValue gpu;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, strong, nullable) NSDictionary *threadDict;
@property (nonatomic, copy, nullable) NSString *service;

@end
