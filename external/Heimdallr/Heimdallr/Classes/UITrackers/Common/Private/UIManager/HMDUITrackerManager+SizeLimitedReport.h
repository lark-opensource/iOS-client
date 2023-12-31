//
//  HMDUITrackerManager+SizeLimitedReport.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDUITrackerManager.h"
#import "HMDRecordStore+DeleteRecord.h"

@interface HMDUITrackerManager (SizeLimitedReport)

@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property (nonatomic, assign) NSInteger hmdCountLimit;


@end
