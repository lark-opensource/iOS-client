//
//  HMDWatchdogProtectRecord.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDTrackerRecord.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHMDWatchdogProtectTableName;

@interface HMDWatchdogProtectRecord : HMDTrackerRecord

// 监控数据
@property(nonatomic, strong) NSString *backtrace;
@property(nonatomic, assign, getter=isLaunchCrash) BOOL launchCrash;
@property(nonatomic, strong) NSDictionary *settings;

// 性能数据
@property(nonatomic, assign) double memoryUsage;
@property(nonatomic, assign) double freeMemoryUsage;
@property(nonatomic, assign) double freeDiskUsage;
@property(nonatomic, strong) NSString *_Nullable connectionTypeName;

// 业务数据
@property(nonatomic, strong) NSString *_Nullable internalSessionID;
@property(nonatomic, strong) NSString *_Nullable business;
@property(nonatomic, strong) NSString *_Nullable lastScene;
@property(nonatomic, strong) NSDictionary *_Nullable operationTrace;
@property(nonatomic, strong) NSDictionary<NSString*, id> *_Nullable customParams;
@property(nonatomic, strong) NSDictionary<NSString*, id> *_Nullable filters;

@end

NS_ASSUME_NONNULL_END
