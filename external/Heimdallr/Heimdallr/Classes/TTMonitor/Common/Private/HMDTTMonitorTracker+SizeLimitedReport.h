//
//  HMDTTMonitorTracker+SizeLimitedReport.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDTTMonitorTracker.h"
#import "HMDRecordStore+DeleteRecord.h"

@class HMDStoreCondition;
@class HMDMonitorDataManager;

@interface HMDTTMonitorTracker (SizeLimitedReport)

@property (nonatomic, assign) NSInteger hmdCountLimit;
@property (atomic, strong) NSArray<HMDStoreCondition *> *normalCondition;
@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, strong) HMDMonitorDataManager *dataManager;

@end
