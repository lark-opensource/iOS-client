//
//  HMDControllerTimeManager+SizeLimitedReport.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDControllerTimeManager.h"
#import "HMDRecordStore+DeleteRecord.h"

@interface HMDControllerTimeManager (SizeLimitedReport)

@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, assign) NSInteger hmdCountLimit;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;

@end
