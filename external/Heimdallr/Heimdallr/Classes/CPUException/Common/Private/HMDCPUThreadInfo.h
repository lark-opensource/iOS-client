//
//  HMDThreadCPUInfo.h
//  Heimdallr
//
//  Created by bytedance on 2020/5/12.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import "HMDThreadBacktraceFrame.h"

@class HMDThreadBacktrace;
@class HMDBinaryImage;

typedef NSString* HMDCPUExceptionImageName;

NS_ASSUME_NONNULL_BEGIN

#pragma mark ---------- HMDThreadCPUInfo ----------
@interface HMDCPUThreadInfo : NSObject

@property (nonatomic, assign) thread_t thread;
@property (nonatomic, assign) float usage;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) NSInteger weight;
@property (nonatomic, strong) HMDThreadBacktrace *backtrace;

- (NSDictionary *)reportDict;

@end

NS_ASSUME_NONNULL_END
