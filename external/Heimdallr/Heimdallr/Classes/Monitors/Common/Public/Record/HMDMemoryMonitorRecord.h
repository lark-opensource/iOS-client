//
//  HMDMemoryMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

@interface HMDMemoryMonitorRecord : HMDMonitorRecord
@property (nonatomic, assign) HMDMonitorRecordValue totalMemory;
@property (nonatomic, assign) HMDMonitorRecordValue availableMemory;
@property (nonatomic, assign) HMDMonitorRecordValue usedMemory;
@property (nonatomic, assign) HMDMonitorRecordValue appUsedMemory;
@property (nonatomic, assign) HMDMonitorRecordValue pageUsedMemory;
@property (nonatomic, assign) HMDMonitorRecordValue customUsedMemory; ///业务方自定义打点数据
@property (nonatomic, assign) NSUInteger memoryWarning;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *dumpInfo;

@end
