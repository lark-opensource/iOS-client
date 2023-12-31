//
//  HMDDartRecord.h
//  Heimdallr
//
//  Created by joy on 2018/10/24.
//

#import "HMDTrackerRecord.h"

@interface HMDDartRecord : HMDTrackerRecord
@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, copy) NSString *backTrace;
@property (nonatomic, copy) NSString *customLog;
@property (nonatomic, copy) NSDictionary *injectedInfo;
@property (nonatomic, strong) NSDictionary *filters;
#if RANGERSAPM
@property (nonatomic, strong) NSDictionary *operationTrace;
#endif
@property (nonatomic, copy) NSString *commitID;

@end

