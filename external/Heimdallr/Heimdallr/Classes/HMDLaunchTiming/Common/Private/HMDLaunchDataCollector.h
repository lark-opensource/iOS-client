//
//  HMDLaunchDataCollector.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/5/27.
//

#import <Foundation/Foundation.h>

@class HMDLaunchTimingRecord;
@class HMDLaunchTaskSpan;
@class HMDLaunchTraceTimingInfo;

#ifdef __cplusplus
extern "C" {
#endif

dispatch_queue_t _Nullable hmd_get_launch_monitor_queue(void);
void hmd_on_launch_monitor_queue(dispatch_block_t _Nonnull block);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol HMDLaunchDataCollectorDelegate <NSObject>

@optional
- (void)hmdLaunchCollectRecord:(HMDLaunchTimingRecord *)record;

@end


@interface HMDLaunchDataCollector : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *perf;
@property (nonatomic, strong, readonly) HMDLaunchTraceTimingInfo *trace;
@property (nonatomic, weak) id<HMDLaunchDataCollectorDelegate> datasource;

#pragma mark --- launch stage
- (void)insertOnceCompleteTrace:(HMDLaunchTraceTimingInfo *)lauchTrace;
#pragma mark --- perf
- (void)insertNormalPerfData:(NSDictionary *)perfDict;
#pragma mark --- collect finish
- (void)recordOnceLaunchData;

@end

NS_ASSUME_NONNULL_END
