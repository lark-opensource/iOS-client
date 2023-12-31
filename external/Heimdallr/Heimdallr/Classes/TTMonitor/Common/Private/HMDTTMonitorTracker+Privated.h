//
//  HMDTTMonitorTracker+Privated.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//
#import "HMDTTMonitorTracker.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDTTMonitorRecord;

@interface HMDTTMonitorTracker (Privated)

- (Class<HMDRecordStoreObject>)trackerStoreClass;
- (NSArray *)getTracksDataWithRecords:(NSArray<HMDTTMonitorRecord *> *)records;

@end

NS_ASSUME_NONNULL_END
