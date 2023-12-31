//
//  HMDOOMCrashConfig.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDTrackerConfig.h"

extern NSString *const _Nonnull kHMDModuleOOMCrashTracker;

@interface HMDOOMCrashConfig : HMDTrackerConfig

@property(atomic, assign) NSTimeInterval updateSystemStateInterval;

@property(nonatomic, assign) NSTimeInterval memoryPressureValidInterval;

//TODO remove this config when metrics of OOM is stable
@property(nonatomic, assign) BOOL isFixNoDataMisjudgment;
/// record binary info for shark cheat check, default is NO
@property(nonatomic, assign) BOOL isNeedBinaryInfo;

@end
