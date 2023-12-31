//
//  HMDWatchDogRecord.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDTrackerRecord.h"

extern NSString * const kHMDWatchDogRecordTableName;
extern NSString * const kHMDWatchDogEventType;

@interface HMDWatchDogRecord : HMDTrackerRecord

@property(nonatomic, assign) NSTimeInterval timeoutDuration;
@property(nonatomic, strong) NSString *internalSessionID;
@property(nonatomic, assign) double memoryUsage;
@property(nonatomic, assign) double freeMemoryUsage;
@property(nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlocks;
@property(nonatomic, strong) NSString *business;
@property(nonatomic, strong) NSString *lastScene;
@property(nonatomic, strong) NSString *backtrace;
@property(nonatomic, strong) NSString *connectionTypeName;
@property(nonatomic, strong) NSDictionary<NSString*, id> *customParams;
@property(nonatomic, assign, getter=isLaunchCrash) BOOL launchCrash;
@property(nonatomic, assign, getter=isBackground) BOOL background;
@property(nonatomic, strong) NSDictionary<NSString*, id> *filters;
@property(nonatomic, strong) NSDictionary *operationTrace;
@property(nonatomic, strong) NSDictionary *settings;
@property(nonatomic, strong) NSString *timeline;
@property(nonatomic, strong) NSArray *deadlock;
@property(nonatomic, assign, getter=isMainDeadlock) BOOL MainDeadlock;
@property(nonatomic, assign) unsigned long exceptionMainAddress;
@property(nonatomic, assign) double main_thread_cpu_usage;
@property(nonatomic, assign) double host_cpu_usage;
@property(nonatomic, assign) double task_cpu_usage;
@property(nonatomic, assign) int cpu_count;

@end
