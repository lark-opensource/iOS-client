//
//  HMDThreadMonitorConfig.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/9/8.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"
#import "HMDThreadMonitor.h"



extern NSString *_Nonnull const kHMDModuleThreadMonitor;//启动时间监控

@interface HMDThreadMonitorConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL enableThreadCount;
@property (nonatomic, assign) NSInteger threadCountThreshold;

@property (nonatomic, assign) BOOL enableSpecialThreadCount;
@property (nonatomic, assign) NSInteger specialThreadThreshold;

@property (nonatomic, assign) BOOL enableThreadSample;
@property (nonatomic, assign) NSInteger threadSampleInterval;
@property (nonatomic, copy) NSArray * _Nullable businessList;
@property (nonatomic, copy) NSDictionary * _Nullable specialThreadWhiteList;

//@property (nonatomic, assign) BOOL enableDeadLock;
//@property (nonatomic, assign) NSInteger deadLockCheckInterval;

@property (nonatomic, assign) BOOL enableBacktrace;
@property (nonatomic, assign) NSInteger countAnalysisInterval;

@property (nonatomic, assign) BOOL enableThreadInversionCheck;

@property (nonatomic, assign) BOOL enableObserverSubThreadRunloop;

@property (atomic, copy) NSArray * _Nullable subThreadRunloopNameList;

@property (nonatomic, assign) NSInteger subThreadRunloopTimeoutDuration;

@end


