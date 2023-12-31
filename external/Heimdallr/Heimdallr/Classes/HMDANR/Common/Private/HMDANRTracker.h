//
//  HMDANRTracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDTracker.h"
#import "HMDTrackerRecord.h"

@class HMDANRRecord;
@class HMDStoreCondition;

extern NSString *const kEnableANRMonitor;

@interface HMDANRTracker : HMDTracker

@property (nonatomic, assign) NSUInteger uploadCount;

- (NSArray<HMDANRRecord *> *)recordsFilteredByConditions:(NSArray<HMDStoreCondition *>*)conditions;

@end
