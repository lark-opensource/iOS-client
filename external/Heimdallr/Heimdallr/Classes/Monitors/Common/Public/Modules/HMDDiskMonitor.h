//
//  HMDDiskMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

//##  这只是一个接入说明，接入完就没它啥事情了
//"disk": {
//    "refresh_interval": 600,
//    "flush_count": 60,
//    "flush_interval": 60,
//    "dump_threshold": 314572800,
//    "dump_top_count": 20,
//    "dump_increase_step": 52428800,
//
//
//    "ignored_relative_paths": ["Library/Heimdallr"],     Array 里面填写忽略的相对路径即可
//    "check_sparse_file": 1,
//    "sparse_file_least_differ_percentage": 0.2,
//    "sparse_file_least_differ_size": 104857600
//},

#import "HMDMonitor.h"
#import "HMDDiskUsage.h"

extern NSString * _Nonnull const kHMDModuleDiskMonitor;//磁盘监控
extern NSNotificationName const _Nonnull kHMDDiskCostWarningNotification;//磁盘占用超过危险阈值的通知
extern NSNotificationName const _Nonnull kHMDDiskCostNormalNotification;//磁盘监控数据通知，无需超过阈值

@interface HMDDiskMonitorConfig : HMDMonitorConfig
@property (nonatomic, assign) NSUInteger dumpThreshold;
@property (nonatomic, assign) NSUInteger dumpTopCount;
@property (nonatomic, assign) NSUInteger dumpIncreaseStep;
@property (nonatomic, assign) NSUInteger collectHourInterval;
@property (nonatomic, assign) double expiredDays;
@property (nonatomic, assign) NSInteger abnormalFolderSize;
@property (nonatomic, assign) NSInteger abnormalFolderFileNumber;
@property (nonatomic, copy, nullable) NSArray<NSString *> *ignoredRelativePaths;
@property (nonatomic, assign) double sparseFileLeastDifferPercentage;   // 多大的 "假占用空间" 比例被认为是 sparse file (两者同时满足)
@property (nonatomic, assign) NSUInteger sparseFileLeastDifferSize;     // 多大的 "假占用空间" 大小被认为是 sparse file
@property (nonatomic, assign) BOOL checkSparseFile;  // 是否测试 sparse 文件
@property (nonatomic, copy, nullable) NSDictionary *diskCustomedPaths;
@property (nonatomic, assign) BOOL enableCustomSearchDepth;
@property (nonatomic, assign) NSInteger fileMaxRecursionDepth;
@property (nonatomic, copy, nullable) NSDictionary *customSearchDepth;
// while the file's size out of the reportSizeThreshold, it will be reported;
@property (nonatomic, assign) NSUInteger reportSizeThreshold;
@property (nonatomic, copy, nullable) NSArray<NSString *> *complianceRelativePaths; // 需要脱敏的路径
@property (nonatomic, assign) NSUInteger freeDiskSpaceCacheTimeInterval; // 磁盘用量缓存时长支持可配
@end

/**
 HMDDiskMonitor 是磁盘监控的 module
 Multi-thread: not safe
 */
@interface HMDDiskMonitor : HMDMonitor

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

- (void)addFileVisitor:(_Nonnull id<HMDDiskVisitor>)visitor;
- (void)removeFileVisitor:(_Nonnull id<HMDDiskVisitor>)visitor;

@end
