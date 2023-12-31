//
//  HMDLauchPerfCollector.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/6/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDLaunchPerfBaseDataKey;
extern NSString *const kHMDLaunchPerfThreadListKey;
extern NSString *const kHMDLaunchPerfSleepTime;
extern NSString *const kHMDLaunchPerfRunnableTime;
extern NSString *const kHMDLaunchPerfThreadCount;
extern NSString *const kHMDLaunchPerfCPUTime;


@interface HMDLaunchPerfCollector : NSObject

@property (nonatomic, assign) BOOL enableThreadList;
@property (nonatomic, assign) BOOL enableCPU;
@property (nonatomic, assign) BOOL enabelBasePerf;
@property (nonatomic, assign) BOOL disable;
@property (nonatomic, assign) BOOL isLaunchEnd;
@property (nonatomic, strong) dispatch_queue_t targetQueue;

- (void)installThreadCountMonitor;

- (NSDictionary *)collectLaunchStagePerf;

@end

NS_ASSUME_NONNULL_END
