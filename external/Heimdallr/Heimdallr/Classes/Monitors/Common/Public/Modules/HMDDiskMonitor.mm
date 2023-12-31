//
//  HMDDiskMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDSimpleBackgroundTask.h"
#import "HMDDiskMonitor.h"
#import "HMDMonitor+Private.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDDiskUsage+Private.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
#import "HMDDiskMonitorRecord.h"
#import "NSObject+HMDAttributes.h"
#import "HMDPerformanceReporter.h"
#import "HMDFolderInfo.h"
#import "hmd_section_data_utility.h"
#import "HMDGCD.h"
#import "HMDALogProtocol.h"
#import "HMDPathComplianceTool.h"
#import "NSDictionary+HMDSafe.h"
// PrivateServices
#import "HMDMonitorService.h"

#define kMaxFileNameLength 20

NSString *const kHMDDiskNextAvailableIntervalKey = @"kHMDDiskNextAviaibleIntervalKey";
NSString *const kHMDModuleDiskMonitor = @"disk";
NSNotificationName const kHMDDiskCostWarningNotification = @"kHMDDiskCostWarningNotification";
NSNotificationName const kHMDDiskCostNormalNotification = @"kHMDDiskCostNormalNotification";

HMD_MODULE_CONFIG(HMDDiskMonitorConfig)

@implementation HMDDiskMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(refreshInterval, refresh_interval, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(dumpThreshold, dump_threshold, @(500 * HMD_MB), @(100 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(dumpTopCount, dump_top_count, @(20), @(20))
        HMD_ATTR_MAP_DEFAULT(dumpIncreaseStep, dump_increase_step, @(30 * HMD_MB), @(30 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(collectHourInterval, collect_hour_interval, @(24), @(24))
        HMD_ATTR_MAP_DEFAULT(expiredDays, expired_days, @(100), @(30))
        HMD_ATTR_MAP_DEFAULT(abnormalFolderFileNumber, abnormal_folder_file_number, @(500), @(500))
        HMD_ATTR_MAP_DEFAULT(abnormalFolderSize, abnormal_folder_size, @(800 * HMD_MB), @(800 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(ignoredRelativePaths, ignored_relative_paths, @[], @[])
        HMD_ATTR_MAP_DEFAULT(sparseFileLeastDifferPercentage, sparse_file_least_differ_percentage, @(0.2), @(0.2))
        HMD_ATTR_MAP_DEFAULT(sparseFileLeastDifferSize, sparse_file_least_differ_size, @(100 * HMD_MB), @(100 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(checkSparseFile, check_sparse_file, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(diskCustomedPaths, disk_customed_paths, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(enableCustomSearchDepth, enable_custom_search_depth, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(fileMaxRecursionDepth, file_max_recursion_depth, @(2), @(4))
        HMD_ATTR_MAP_DEFAULT(customSearchDepth, custom_search_depth, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(reportSizeThreshold, report_size_threshold, @(100), @(100))
        HMD_ATTR_MAP_DEFAULT(complianceRelativePaths, compliance_relative_paths, @[], @[])
        HMD_ATTR_MAP_DEFAULT(freeDiskSpaceCacheTimeInterval, free_disk_space_cache_time_interval, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT_TOB(uploadDiskMetric, disk_metric_sampling_rate, @(YES))
        HMD_ATTR_MAP_DEFAULT_TOB(uploadDiskException, disk_exception_sampling_rate, @(YES))
    };
}

+ (NSString *)configKey {
    return kHMDModuleDiskMonitor;
}

- (NSUInteger)collectHourInterval {
    if (_collectHourInterval < 1) {
        return 1;
    }
    return _collectHourInterval;
}

- (id<HeimdallrModule>)getModule {
    return [HMDDiskMonitor sharedMonitor];
}

@end

@interface HMDDiskMonitor ()

@property (nonatomic, strong) NSHashTable<id<HMDDiskVisitor>> *visitors;
@property (nonatomic, strong) HMDFolderInfo *folderVisitor;
@property (nonatomic, strong) HMDDiskMonitorConfig *diskConfig;
@property (atomic, assign) NSTimeInterval nextAvailableTimeInterval;

@end

@implementation HMDDiskMonitor
SHAREDMONITOR(HMDDiskMonitor)

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDDiskMonitorRecord class];
}

- (instancetype)init {
    if (self = [super init]) {
        _nextAvailableTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kHMDDiskNextAvailableIntervalKey] ?: 0;
        _visitors = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)start {
    [super start];
    [self addFolderInfoVisitor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)stop {
    [super stop];
    [self removeFolderInfoVisitor];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)addFolderInfoVisitor {
    if (!self.folderVisitor) {
        self.folderVisitor = [[HMDFolderInfo alloc] init];
        [self.folderVisitor customPathWithConfigDict:[self.diskConfig.diskCustomedPaths copy]];
        [self.folderVisitor addCustomSearchDepathConfig:[self.diskConfig.customSearchDepth copy]];
        self.folderVisitor.allowCustomLevel = self.diskConfig.enableCustomSearchDepth;
        self.folderVisitor.fileMaxRecursionDepth = self.diskConfig.fileMaxRecursionDepth;
        self.folderVisitor.collectMinSize = self.diskConfig.reportSizeThreshold;
    }
    [self addFileVisitor:self.folderVisitor];
}

- (void)removeFolderInfoVisitor {
    if (self.folderVisitor) {
        [self removeFileVisitor:self.folderVisitor];
    }
}

- (NSArray*)complianceConvert:(NSArray*)fileLists {
    NSArray* compliancePaths = self.diskConfig.complianceRelativePaths;
    if (compliancePaths.count == 0) {
        return fileLists;
    }
    NSMutableArray *tmp = [NSMutableArray arrayWithArray:fileLists];
    for (int i = 0; i < fileLists.count; i++) {
        NSDictionary *pathData = fileLists[i];
        NSString *name = [pathData hmd_stringForKey:@"name"];
        NSString *compliancePath = [HMDPathComplianceTool complianceReleativePath:name compliancePaths:compliancePaths];
        if (![name isEqualToString:compliancePath]) {
            NSMutableDictionary *newPathData = [pathData mutableCopy];
            newPathData[@"name"] = compliancePath;
            tmp[i] = newPathData.copy;
        }
    }
    return tmp.copy;
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) recordForSpecificScene:(NSString *)scene {
    __weak typeof(self) weakSelf = self;
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:@"com.heimdallr.diskMonitor.backgroundTask" expireTime:8 task:^(void (^ _Nonnull completeHandle)()) {
        dispatch_on_monitor_queue(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            double expiredDays = strongSelf.diskConfig.expiredDays;
            NSInteger abnormalFolderSize = strongSelf.diskConfig.abnormalFolderSize;
            NSInteger abnormalFolderFileNumber = strongSelf.diskConfig.abnormalFolderFileNumber;
            NSUInteger dumpThreshold = strongSelf.diskConfig.dumpThreshold;
            NSUInteger dumpIncreaseStep = strongSelf.diskConfig.dumpIncreaseStep;
            NSUInteger dumpTopCount = strongSelf.diskConfig.dumpTopCount;
            double sparseFileLeastDifferPercentage = strongSelf.diskConfig.sparseFileLeastDifferPercentage;
            NSUInteger sparseFileLeastDifferSize = strongSelf.diskConfig.sparseFileLeastDifferSize;
            BOOL checkSparseFile = strongSelf.diskConfig.checkSparseFile;
            NSUInteger minCollectSize = strongSelf.diskConfig.reportSizeThreshold;
            __auto_type visitors = strongSelf.visitors;
            NSArray<NSString *> *ignoredRelativePathsConvert = [strongSelf.diskConfig.ignoredRelativePaths copy];
            NSArray<NSString *> *complianceRelativePathsConvert = [strongSelf.diskConfig.complianceRelativePaths copy];
            HMDDiskUsage *diskTool = [[HMDDiskUsage alloc] initWithOutdatedDays:expiredDays
                                                             abnormalFolderSize:abnormalFolderSize
                                                       abnormalFolderFileNumber:abnormalFolderFileNumber ignoreRelativePathes:ignoredRelativePathsConvert
                                                                checkSparseFile:checkSparseFile
                                                sparseFileLeastDifferPercentage:sparseFileLeastDifferPercentage
                                                      sparseFileLeastDifferSize:sparseFileLeastDifferSize
                                                                 minCollectSize:minCollectSize
                                                                       visitors:visitors];

            if([diskTool isAbnormalReturnValue]) {return;}
            // app total usage
            double currentAppDiskCost = [diskTool getThisAppSpace];
            // discard extreme values
            if(currentAppDiskCost >= [HMDDiskUsage getTotalDiskSpace]) {return;}
            double currentFreeDisk = [HMDDiskUsage getFreeDiskSpace];
            NSInteger totalDiskLevel = [HMDDiskUsage getTotalDiskSizeLevel];
            NSInteger freeBlockCount = [HMDDiskUsage getFreeDisk300MBlockSize];

            HMDDiskMonitorRecord *record = [HMDDiskMonitorRecord newRecord];
            record.appUsage = currentAppDiskCost;
            record.freeBlockCounts = freeBlockCount;
            record.totalDiskLevel = totalDiskLevel;
            record.documentsAndDataUsage = [strongSelf.folderVisitor sizeOfDocumentsAndData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kHMDDiskCostNormalNotification object:record userInfo:nil];
            record.diskInfo = [strongSelf.folderVisitor reportDiskFolderInfoWithAppFolderSize:currentAppDiskCost compliancePaths:complianceRelativePathsConvert];
            [strongSelf.folderVisitor clearData];
            if (currentAppDiskCost > dumpThreshold) {
                //防止超过阈值之后的频繁dump
                if(strongSelf != nil) {
                    strongSelf.diskConfig.dumpThreshold += dumpIncreaseStep;
                }
                NSArray<NSDictionary*> *topFileLists = [diskTool getAppFileListForTopRank:dumpTopCount];
                record.topFileLists = [strongSelf complianceConvert:topFileLists];
                if (expiredDays > 0) {
                    record.outdatedFiles = [strongSelf complianceConvert:[diskTool getOutDateFilesWithTopRank:dumpTopCount]];
                }
                if (abnormalFolderSize || abnormalFolderFileNumber) {
                    record.exceptionFolders = [strongSelf complianceConvert:[diskTool getExceptionFoldersWithTopRank:dumpTopCount]];
                }
                // 超过阈值，发送通知给外界
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kHMDDiskCostWarningNotification object:record userInfo:nil];
            }
            [HMDSessionTracker currentSession].freeDisk = currentFreeDisk/HMD_MB;

            if (scene) {
                record.scene = scene;
                record.pageUsage = record.appUsage - strongSelf.curPageUsage;
            }
            
            /// 一般磁盘的采集间隔是小时级别 如果等待达到 flushCount 的话, 需要很长时间 有可能 APP 此时就被kill 掉了, 信息就丢失了
            [strongSelf.curve pushRecordToDBImmediately:record];

            // if disk free space size less than 30M
            size_t statfDiskFreeSize = [HMDDiskUsage getFreeDiskSpaceByStatf];
            if(statfDiskFreeSize < ((unsigned long)(30 * HMD_MB))) {
                NSDictionary *metric = @{@"free_block": @(freeBlockCount)};
                NSDictionary *extra = @{@"total_type": @(totalDiskLevel), @"app_usage": @(currentAppDiskCost)};
                [HMDMonitorService trackService:@"slardar_disk_free_space_not_enough" metrics:metric dimension:nil extra:extra syncWrite:YES];

                if(hmd_log_enable()) {
                    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDDiskMonitor current disk space info: app_usage:%lf, total type:%ld, free block less than 30M", currentAppDiskCost, totalDiskLevel);
                }
            }

            if(completeHandle) completeHandle();
        });
    }];
}

- (void)didEnterBackground:(NSNotification *)notification {
    if ([[NSDate date] timeIntervalSince1970] > self.nextAvailableTimeInterval) {
        NSInteger hmdHourInterval = self.diskConfig.collectHourInterval;
        hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self recordForSpecificScene:@"didEnterBackground"];
            NSTimeInterval nextAvailableTimeInterval = [[NSDate date] timeIntervalSince1970] + (60 * 60 * hmdHourInterval);
            self.nextAvailableTimeInterval = nextAvailableTimeInterval;
            [[NSUserDefaults standardUserDefaults] setValue:@(nextAvailableTimeInterval) forKey:kHMDDiskNextAvailableIntervalKey];
        });
    }
}

#pragma mark HeimdallrModule

- (void)updateConfig:(HMDDiskMonitorConfig *)config {
    [super updateConfig:config];
    if (![config isKindOfClass:[HMDDiskMonitorConfig class]]) {
        return;
    }
    dispatch_on_monitor_queue(^{
        self.diskConfig = (HMDDiskMonitorConfig *)config;
        // valid check
        if (config.dumpThreshold < 0) {
            self.diskConfig.dumpThreshold = 0;
        }
        if (config.dumpTopCount < 0) {
            self.diskConfig.dumpTopCount = 0;
        }
        if (config.dumpIncreaseStep < 0) {
            self.diskConfig.dumpIncreaseStep = 0;
        }
        if (config.collectHourInterval <= 0) {
            self.diskConfig.collectHourInterval = 1;
        }
        if (config.expiredDays <= 0) {
            self.diskConfig.expiredDays = 1;
        }
        if (config.abnormalFolderSize <= 0) {
            self.diskConfig.abnormalFolderSize = 1;
        }
        if (config.abnormalFolderFileNumber <= 0) {
            self.diskConfig.abnormalFolderFileNumber = 1;
        }
        
        NSMutableArray *complianceRelativePaths = [NSMutableArray arrayWithCapacity:self.diskConfig.complianceRelativePaths.count];
        [self.diskConfig.complianceRelativePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // only support ["/tmp/GWPASanTmp","/tmp/test"]
            NSString *path = obj;
            if ([path hasSuffix:@"/"]) {
                path = [path substringToIndex:path.length-1];
            }
            if (![path hasPrefix:@"/"]) {
                path = [NSString stringWithFormat:@"/%@", path];
            }
            [complianceRelativePaths addObject:path];
        }];
        self.diskConfig.complianceRelativePaths = complianceRelativePaths.copy;
        
        if (self.folderVisitor) {
            self.folderVisitor.allowCustomLevel = config.enableCustomSearchDepth;
            self.folderVisitor.fileMaxRecursionDepth = config.fileMaxRecursionDepth;
            self.folderVisitor.collectMinSize = config.reportSizeThreshold;
            [self.folderVisitor customPathWithConfigDict:[config.diskCustomedPaths copy]];
            [self.folderVisitor addCustomSearchDepathConfig:[config.customSearchDepth copy]];
        }
        [HMDDiskUsage setFreeDiskSpaceCacheTimeInterval:self.diskConfig.freeDiskSpaceCacheTimeInterval];
    });
}

- (void)addFileVisitor:(_Nonnull id<HMDDiskVisitor>)visitor {
    NSCParameterAssert(visitor);
    dispatch_on_monitor_queue(^{
        [self.visitors addObject:visitor];
    });
}

- (void)removeFileVisitor:(id<HMDDiskVisitor>)visitor {
    NSCParameterAssert(visitor);
    dispatch_on_monitor_queue(^{
        [self.visitors removeObject:visitor];
    });
}

#pragma mark - KVO

- (void)didEnterScene:(NSString *)scene {
//    dispatch_on_monitor_queue(^{
//        self.curPageUsage = [HMDDiskUsage getThisAppSpace];
//    });
}

- (void)willLeaveScene:(NSString *)scene {
    //[self recordForSpecificScene:scene];
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityDiskMonitor;
}

@end
