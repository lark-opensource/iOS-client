//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//

#import "HMDTrackerRecord.h"

@interface HMDGameRecord : HMDTrackerRecord
@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, copy) NSString *backTrace;
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary<NSString*, id> *customParams;
@property (nonatomic, strong) NSDictionary *filters;
@end

