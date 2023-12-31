//
//  HMDMatrixMonitor.m
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#define HMD_THIS_IS_BD_MATRIX_FILE

#import "HMDMatrixMonitor+Uploader.h"
#import "HMDMemoryGraphMatrixBridge.h"
#import <SSZipArchive/SSZipArchive.h>
#import <Heimdallr/HMDUITrackerManager.h>
#import <Heimdallr/HMDUserDefaults.h>
#import <Heimdallr/HMDDynamicCall.h>
#import <Heimdallr/NSDictionary+HMDSafe.h>
#import <Heimdallr/NSArray+HMDSafe.h>
#import <Heimdallr/HMDApplicationSession.h>
#import <Heimdallr/HMDMemoryUsage.h>
#import <Heimdallr/HMDSessionTracker.h>
#import <Heimdallr/HMDExcludeModuleHelper.h>
#import <Heimdallr/HMDAppExitReasonDetector.h>
#import <Heimdallr/hmd_crash_async_stack_trace.h>
#import <Heimdallr/HMDOOMCrashInfo.h>
#import <Heimdallr/HMDBDMatrixPortable.h>
#import <Heimdallr/HMDDiskUsage.h>
#import <Heimdallr/HMDTracker.h>
#import <Heimdallr/HMDInjectedInfo.h>
#import <Heimdallr/HMDALogProtocol.h>
#import "HMDCustomAlog.h"
#import "HMDMatrixConfig.h"

#define MemoryPressureTimeInterval 10*60
#define RemainingVirtualMemory 100*1024*1024
#define MilliSecond(x) (long long)(1000ll * x)
#ifndef HMD_MB
#define HMD_MB (1024.f * 1024.f)
#endif

extern NSString *const kHMDUITrackerSceneDidChangeNotification;
static NSString *const KHMDMatrixLastTimeAsyncStackTraceOpen = @"KHMDMatrixLastTimeAsyncStackTraceOpen";///是否开启异步调用栈获取
const char *KALOGPrefix = "Matrix";
bool matrix_async_stack_enable = 0;
static int matrixMaxTimesPerDay = 100;
static double matrixMinGenerateMinuteInterval = 0;

@implementation HMDMatrixMonitor

+ (instancetype)sharedMonitor {
    static HMDMatrixMonitor *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _uploadQueue = dispatch_queue_create("com.heimdallr.matrix.upload", DISPATCH_QUEUE_SERIAL);
        self.uploadSemaphore = dispatch_semaphore_create(0);
        self.filters = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)start {
#ifdef DEBUG
    ///须在podfile中移除对Heimdallr中'HMDOOM'子库的依赖
    NSAssert(NSClassFromString(@"HMDOOMDetector") == nil, @"'HMDOOM'not removed");
#endif
    [super start];
    HMDMemoryMatrixSupported startEnabled = [self startEnabled];
    if (startEnabled == HMDMemoryMatrixSupportedEnabled) {
        [self asyncStackOpen];
        [self matrixOpen];
    } else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Memory", @"Heimdallr Matrix Module start failed : %@", [self memoryMatrixUnsupportedReason:startEnabled]);
    }
}

- (HMDMemoryMatrixSupported)startEnabled {
    HMDMemoryMatrixSupported supported = 0;

    if (@available(iOS 10.0, *)) {
        supported = supported | HMDMemoryMatrixSupportedIOSVersion;
    }
    HMDMatrixConfig *config = (HMDMatrixConfig *)self.config;
    unsigned long freeDiskMB = [HMDDiskUsage getFreeDiskSpace] / HMD_MB;
    if (freeDiskMB >= config.minRemainingDiskSpaceMB) {
        supported = supported | HMDMemoryMatrixSupportedLimitDisk;
    }
    return supported;
}

- (NSString *)memoryMatrixUnsupportedReason:(HMDMemoryMatrixSupported)supported {
    NSMutableArray *reasonArr = [NSMutableArray new];
    if (!(supported & HMDMemoryMatrixSupportedIOSVersion)) {
        [reasonArr addObject:@"iOS version is too low"];
    }
    if (!(supported & HMDMemoryMatrixSupportedLimitDisk)) {
        [reasonArr addObject:@"Insufficient free disk space"];
    }
    NSString *reason = [reasonArr componentsJoinedByString:@","];
    return reason;
}

#pragma mark - Matrix Start Task
/*
 * @note: Heimdallr的启动任务项，完成matrix数据上报、清理工作
 */
- (void)runTaskIndependentOfStart {
    if (@available(iOS 10.0, *)); else return;   // iOS10+
    [super runTaskIndependentOfStart];
    [self matrixOfMemoryGraphUpload];
    [self matrixOfCustomUpload];
    [HMDAppExitReasonDetector registerDelegate:self];
}
/*
 * @note: 获取APP上次退出原因，判断是否上报matrix数据
 * 1. 未发生OOM、Crash，但是收到内存压力警告：
 *    如果打开平台配置项is_memory_pressure_upload_enabled则上报; 默认不上报；
 *    可以通过过滤项筛选该场景下数据：execptionType=MemoryPressure
 * 2. 发生OOM：上报matrix数据
 * 3. 发生crash：
 *    ① 由于虚拟内存耗尽导致的崩溃，上报matrix数据
 *    ② 其他原因导致的崩溃，如果打开了平台配置项is_crash_upload_enabled则上报; 默认不上报
 * 4. 发生watchDog: 默认不上报，可通过平台配置项is_watchDog_upload_enabled配置上报
 * 5. 未发生oom、watchdog、crash，通过平台配置项is_enforce_upload_enabled可上报上次的matrix数据
 * 6. 非以上情况，则删除matrix数据
 */
- (void)didDetectExitReason:(HMDApplicationRelaunchReason)reason desc:(NSString* _Nullable)desc info:(HMDOOMCrashInfo* _Nullable)info {
    HMDMatrixConfig *config = (HMDMatrixConfig *)self.config;
    NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
    self.sessionData = latestSessionDic.mutableCopy;
    NSTimeInterval timestamp = MAX(info.latestTime, info.memoryInfo.updateTime);
    if(latestSessionDic != nil) {
        double sessionDuration = [latestSessionDic hmd_doubleForKey:@"duration"];
        double sessionTimestamp = [latestSessionDic hmd_doubleForKey:@"timestamp"];
        if(sessionDuration + sessionTimestamp > timestamp) {
            timestamp = sessionDuration + sessionTimestamp;
        }
        NSDictionary *sessionFilters = [latestSessionDic hmd_dictForKey:@"filters"];
        if([sessionFilters count] > 0) {
            [self.filters addEntriesFromDictionary:sessionFilters];
        }
    }
    
    if (info.memoryPressure > 0) {
        /// 10min内的内存警告认为是有效警告
        if (timestamp - info.memoryPressureTimestamp < MemoryPressureTimeInterval) {
            [self.filters setObject:[@(info.memoryPressure) stringValue] forKey:@"memory_pressure"];
        }
    }
    
    bool upload_flag = 0;
    
    if (reason == HMDApplicationRelaunchReasonFOOM) {
        [self.filters setObject:@"oom" forKey:@"execptionType"];
        upload_flag = 1;
    } else if (reason == HMDApplicationRelaunchReasonCrash) {
        uint64_t lastCrashUsedVM = HMDBDMatrixPortable_lastCrashUsedVM();
        uint64_t lastCrashTotalVM = HMDBDMatrixPortable_lastCrashTotalVM();
        uint64_t lastCrashRemainVM = lastCrashTotalVM - lastCrashUsedVM;
        if (lastCrashUsedVM != 0 && lastCrashTotalVM != 0 && lastCrashRemainVM < RemainingVirtualMemory) {
            [self.filters setObject:@"VMExhaustion" forKey:@"execptionType"];
            upload_flag = 1;
        } else if (config.isCrashUploadEnabled) {
            [self.filters setObject:@"crash" forKey:@"execptionType"];
            upload_flag = 1;
        }
    } else if (reason == HMDApplicationRelaunchReasonWatchDog && config.isWatchDogUploadEnabled) {
        [self.filters setObject:@"watchDog" forKey:@"execptionType"];
        upload_flag = 1;
    } else if (info.memoryPressure > 0 && config.isMemoryPressureUploadEnabled) {
        [self.filters setObject:@"MemoryPressure" forKey:@"execptionType"];
        upload_flag = 1;
    }
    
    if (upload_flag == 0) {
        if (config.isEnforceUploadEnabled == 1) {
            [self.filters setObject:@"notMatch" forKey:@"execptionType"];
            upload_flag = 1;
        }
    }
    
    [self.sessionData setValue:[self.filters copy] forKey:@"filters"];
    [self.sessionData hmd_setObject:info.lastScene forKey:@"last_scene"];
    [self.sessionData hmd_setObject:@(info.inAppTime) forKey:@"inapp_time"];
    [self.sessionData hmd_setObject:@(MilliSecond(timestamp)) forKey:@"timestamp"];///转换为毫秒的单位，避免服务端将非int类型的数据过滤
    
    if (upload_flag == 1) {
        [self writeSessionDataToFile];
        [self uploadMatrixAlog];
        [self reportLastSessionMemoryData];
    } else {
        [self matrixOfExceptionUpload];
        [[MMMemoryAdapter shared] deleteOldRecords];
    }
}

#pragma mark - Generate Report

- (void)reportLastSessionMemoryData {
    if ([MMMemoryAdapter shared].delegate == nil) {
        [MMMemoryAdapter shared].delegate = self;
    }
    [[MMMemoryAdapter shared] report];
}

#pragma  mark - Matrix Open

- (void)asyncStackOpen {
    bool res = [[HMDUserDefaults standardUserDefaults] boolForKey:KHMDMatrixLastTimeAsyncStackTraceOpen];
    [self.filters setObject:((res == 1)?@"1":@"0") forKey:@"asyncStackOpen"];
    bool isAsyncStackOpen = hmd_async_stack_trace_open();
    [[HMDUserDefaults standardUserDefaults] setBool:isAsyncStackOpen forKey:KHMDMatrixLastTimeAsyncStackTraceOpen];
}

-(void)matrixOpen {
    HMDMatrixConfig *config = (HMDMatrixConfig *)self.config;
    if (config.isAsyncStackEnabled) {
        matrix_async_stack_enable = 1;
    } else {
        matrix_async_stack_enable = 0;
    }
    [self customDumpfrequencyLimit];
    bd_log_open_default_instance(KALOGMemoryInstance,KALOGPrefix);
    
    setup_matrix_dump_time_callback();
    
    [MMMemoryAdapter shared].delegate = self;
    [[MMMemoryAdapter shared] start];
    [[MMMemoryAdapter shared] getEventTime:config.isEventTimeEnabled];
    if (config.isVCLevelEnabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerChanged:) name:kHMDUITrackerSceneDidChangeNotification object:nil];
        
        //Set first vc name
        char *vcName = strdup([[[HMDUITrackerManager sharedManager] scene] cStringUsingEncoding:NSUTF8StringEncoding]);
        [[MMMemoryAdapter shared] setVCName:vcName];
        free(vcName);
    }
}

#pragma mark - Notification Observer Selector
- (void)viewControllerChanged: (NSNotification *)notifi {
    char* vcName = strdup([[[HMDUITrackerManager sharedManager] scene] cStringUsingEncoding:NSUTF8StringEncoding]);
    [[MMMemoryAdapter shared] setVCName:vcName];
    free(vcName);
}

#pragma mark - Get Current Session Params

/*
 * @note: 将上一次的session数据写入env文件中
 */
- (void)writeSessionDataToFile {
    NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
    NSString *identifier = [latestSessionDic hmd_stringForKey:@"eternalSessionID"];
    if (identifier == nil) {
        identifier = [latestSessionDic hmd_stringForKey:@"internal_session_id"];///兼容新老版本heimdallr，避免强要求同步升级
        if (identifier == nil) {
            return;
        }
    }
    NSString *envFileName = [identifier stringByAppendingPathExtension:KHMDMatrixEnvFileExtension];
    NSString *envPath = [[HMDMatrixMonitor matrixOfExceptionUploadPath] stringByAppendingPathComponent:envFileName];
    [self.sessionData writeToFile:envPath atomically:YES];
}

/*
 * @note: 将当前的session数据写入env文件中：matrix数据dump时，获取当前时刻的状态信息写入文件，下次启动时上报
 */
+ (void)hmdMatrixSessionParamsTracker:(NSString *)rootPath customFilters:(NSString *)customData  paramsWriteToFileName:(NSString *)fileName {
    long long timestamp = MilliSecond([[NSDate date] timeIntervalSince1970]);
    hmd_MemoryBytes memoryInfo = hmd_getMemoryBytes();
    NSInteger freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data hmd_setObject:@(timestamp) forKey:@"timestamp"];
    [data hmd_setObject:@(memoryInfo.appMemory/HMD_MB) forKey:@"memory_usage"];
    [data hmd_setObject:@(hmd_calculateMemorySizeLevel(memoryInfo.availabelMemory)) forKey:HMD_Free_Memory_Key];
    [data hmd_setObject:@(hmd_calculateMemorySizeLevel(memoryInfo.totalMemory)) forKey:HMD_Total_Memory_Key];
    [data hmd_setObject:@(freeDiskBlockSize) forKey:@"d_zoom_free"];
    [data hmd_setObject:@([HMDSessionTracker currentSession].timeInSession) forKey:@"inapp_time"];
    [data hmd_setObject:[HMDTracker getLastSceneIfAvailable] forKey:@"last_scene"];
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if (customData.length != 0) {
        [filters hmd_setObject:customData forKey:@"customScene"];///自定义时机上报的数据通过该筛选项进行筛选
    }
    if ([HMDInjectedInfo defaultInfo].filters.count > 0) {
        [filters hmd_addEntriesFromDict:[HMDInjectedInfo defaultInfo].filters];
    }
    [data hmd_setObject:[filters copy] forKey:@"filters"];
    NSString *envPath = [rootPath stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:KHMDMatrixEnvFileExtension]];
    [data writeToFile:envPath atomically:YES];
}

#pragma mark - Protocol MMMemoryAdapterDelegate

- (NSString*)getTempZipFileFromData:(NSData*)data fileName:(NSString*)name {
    NSString *rootPath = [HMDMatrixMonitor matrixOfExceptionUploadPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:rootPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            return NULL;
        }
    }
    NSString *path = [rootPath stringByAppendingPathComponent:name];
    
    SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:path];
    BOOL success = [zipArchive open];
    if (!success) {
        return nil;
    }
    
    if (![zipArchive writeData:data filename:@"data.json" withPassword:nil]) {
        [zipArchive close];
        return nil;
    }
    
    if (![zipArchive close]) {
        return nil;
    }

    HMDALOG_PROTOCOL_INFO_TAG(@"Memory", @"OOMMemory data compress sucess");
    
    return path;
}

- (void)onMemoryIssueReport:(MMMemoryIssue*)issue
{
    HMDALOG_PROTOCOL_INFO_TAG(@"Memory", @"Memory Monitor Issue : %@", issue);
    NSString *lastSessionID = [HMDSessionTracker sharedInstance].lastTimeEternalSessionID;
    // compress data
    NSString * fileName = [NSString stringWithFormat:@"%@.dat", lastSessionID];
    NSString * filePath = [self getTempZipFileFromData:issue.issueData fileName:fileName];
    if (filePath == nil) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Memory", @"OOMMemory data compress failed");
        return;
    }

    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    HMDALOG_PROTOCOL_INFO_TAG(@"Memory", @"Memory compressed file info : %@", [fileInfo objectForKey:NSFileSize]);

    [self matrixOfExceptionUpload];
}

- (void)onMemoryIssueNotFound:(NSString *)errorInfo {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory Monitor Issue Not Found: %@", errorInfo);
}

- (void)onMemoryAdapterReason:(NSString *)reason type:(NSString *)type {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSDictionary *category = @{@"status": reason};
    DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_matrix_fail_reason", nil, category, nil, YES);
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Matrix Stop Logging Reason: %@", reason);
}

#pragma mark - Get Matrix Config

- (void)customDumpfrequencyLimit {
    matrixMinGenerateMinuteInterval = ((HMDMatrixConfig *)self.config).minGenerateMinuteInterval;///单位为秒
    matrixMaxTimesPerDay = (int)((HMDMatrixConfig *)self.config).maxTimesPerDay;
}

#pragma mark - Return Root Path Of All Pending Files
+ (NSString *)removableFileDirectoryPath {
    return [self matrixUploadRootPath];
}

@end

#pragma mark - Get Frequency Control Parameters

double getMatrixMinGenerateMinuteInterval(void) {
    return matrixMinGenerateMinuteInterval;
}

int getMatrixMaxTimesPerDay(void) {
    return matrixMaxTimesPerDay;
}
