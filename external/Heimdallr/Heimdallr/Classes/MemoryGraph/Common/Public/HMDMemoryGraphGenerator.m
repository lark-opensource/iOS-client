//
//  HMDMemoryGraphGenerator.m
//  Pods
//
//  Created by fengyadong on 2020/02/21.
//

#import "HMDMemoryGraphGenerator.h"
#import "Heimdallr+Private.h"
#import "HMDMemoryGraphConfig.h"
#if RANGERSAPM
#import <MemoryGraphCaptureToB/AWEMemoryGraphGenerator.h>
#else
#import <MemoryGraphCapture/AWEMemoryGraphGenerator.h>
#endif
#import "HeimdallrUtilities.h"
#import "HMDFileUploader.h"
#import "HMDMemoryChecker.h"
#import "HMDMemoryGraphUploader.h"
#import "HMDSessionTracker.h"
#import "HMDSessionTracker.h"
#import "HMDMemoryGraphTool.h"
#import "HMDMemoryGraphTool+Private.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#include <sys/utsname.h>
#import "HMDInfo+DeviceInfo.h"
#if RANGERSAPM
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#endif
#import "HMDUploadHelper.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDDynamicCall.h"
#import "HMDALogProtocol.h"
#import "HMDDiskUsage.h"
#import "HMDTracker.h"
#import "HMDNetworkHelper.h"
#import "HMDUserDefaults.h"
#import "HMDGCD.h"
#import "NSObject+HMDAttributes.h"
#import "HMDDiskSpaceDistribution.h"
#import "HMDAsyncThread.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"

#if RANGERSAPM
static NSString * const kEventMemoryGraphGenerateStart = @"memory_graph_generate_start";
static NSString * const kEventMemoryGraphGenerateEnd = @"memory_graph_generate_end";
static NSString * const kEventMemoryGraphZip = @"memory_graph_zip";
#else
static NSString * const kEventMemoryGraphGenerateStart = @"slardar_memory_graph_generate_start";
static NSString * const kEventMemoryGraphGenerateEnd = @"slardar_memory_graph_generate_end";
static NSString * const kEventMemoryGraphZip = @"slardar_memory_graph_zip";
#endif /* RANGERSAPM */

static NSString *const kHMDMemoryGrapthGenerateDateAndCount = @"kHMDMemoryGrapthGenerateDateAndCount";

static const uint64_t minRemainingDiskSpaceMB = 10;
//上次采集是否完成标记
static NSString *const HHMDMemoryGraphLastTimeInterrupt = @"HHMDMemoryGraphLastTimeInterrupt";
@interface HMDMemoryGraphGenerator ()

@property (nonatomic, strong) HMDMemoryChecker *checker;
@property (nonatomic, strong) HMDMemoryGraphUploader *uploader;
@property (nonatomic, strong) dispatch_queue_t generateQueue;
@property (nonatomic, assign) BOOL memoryWarningReceived;
#if RANGERSAPM
@property (nonatomic, assign) BOOL isBackground;
#endif
@property (nonatomic, copy) NSDictionary<NSString*, id>* filters;
@property (nonatomic, copy) NSDictionary<NSString*, id>* context;
@property (nonatomic, assign) BOOL isMemorySurge;

@end

@implementation HMDMemoryGraphGenerator 

+ (instancetype)sharedGenerator {
    static HMDMemoryGraphGenerator *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _checker = [HMDMemoryChecker new];
        _uploader = [HMDMemoryGraphUploader new];
        _generateQueue = dispatch_queue_create("com.heimdallr.memorygraph.generate", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - HeimdallrModule Protocol Method
- (BOOL)needSyncStart {
    return NO;
}

- (void)runTaskIndependentOfStart {
    [super runTaskIndependentOfStart];
    [self.uploader asyncCheckAndUpload];
}

- (void)start {
    [super start];
    HMDMemoryGraphSupported startEnabled = [self startEnabled];
    if(startEnabled == HMDMemoryGraphSupportedStartEnabled) {
        [self activateMemoryChecker];
        if (((HMDMemoryGraphConfig*)self.config).enableCircularReferenceDetect) {
            DC_CL(AWEMemoryGraphGenerator, associateHook);
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory Graph hook objc association");
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryPeakedNotification:)
                                                     name:kHMDMemoryHasPeakedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWillPeakedNotification:)
                                                     name:kHMDMemoryWillPeakNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr MemoryGraph Module started");
        
#if RANGERSAPM
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationStateChanged:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationStateChanged:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationStateChanged:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
#endif
        [HMDDebugLogger printLog:@"MemoryGraph start successfully!"];
    }
    else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr MemoryGraph Module start failed : %@", [self memoryGraphUnsupportedReason:startEnabled]);
        [HMDDebugLogger printLog:[NSString stringWithFormat:@"MemoryGraph start failed. Reason: %@", [self memoryGraphUnsupportedReason:startEnabled]]];
    }
}

- (void)updateConfig:(HMDModuleConfig *)config {
    if (!config.isValid) {
        //downgrade for performance reason
        config = [HMDMemoryGraphConfig hmd_objectWithDictionary:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr MemoryGraph Module config invalid!");
    }
    
    [super updateConfig:config];
    HMDMemoryGraphConfig *mgConfig = (HMDMemoryGraphConfig *)config;
    if (mgConfig.maxPreparedFolderSizeMB < 200) {
        mgConfig.maxPreparedFolderSizeMB = 200;
    }
    
    //because this method can be invoked before start
    if ([self startEnabled] == HMDMemoryGraphSupportedStartEnabled && self.isRunning) {
        [self activateMemoryChecker];
    }
}

- (void)stop {
    [super stop];
    [self.checker invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (((HMDMemoryGraphConfig*)self.config).enableCircularReferenceDetect) {
        DC_CL(AWEMemoryGraphGenerator, associateUnHook);
    }
}

- (HMDMemoryGraphSupported)startEnabled {
    HMDMemoryGraphSupported startEnabled = [self isDeviceSupported];
    HMDMemoryGraphConfig *config = (HMDMemoryGraphConfig *)self.config;
    if (![self exceedLimitPerDayForConfig:config]) {
        startEnabled = startEnabled | HMDMemoryGraphSupportedLimitPerDay;
    }
    
    return startEnabled;
}

- (HMDMemoryGraphSupported)isDeviceSupported {
    HMDMemoryGraphSupported supported = 0;
        
    if (@available(iOS 10, *)) {
        supported = supported | HMDMemoryGraphSupportedIOSVersion;
    }
    
#if !TARGET_OS_SIMULATOR
    supported = supported | HMDMemoryGraphSupportedNotSimulator;
#endif
    
#if defined(__arm64__)
    supported = supported | HMDMemoryGraphSupportedARM64;
#endif
    
#if !__has_feature(address_sanitizer)
    supported = supported | HMDMemoryGraphSupportedNotASAN;
#endif
    
    HMDMemoryGraphConfig *config = (HMDMemoryGraphConfig *)self.config;
    if ([HMDInfo defaultInfo].devicePerformaceLevel >= config.devicePerformanceLevelThreshold) {
        supported = supported | HMDMemoryGraphSupportedPerformance;
    }
    
    return supported;
}

- (NSString *)memoryGraphUnsupportedReason:(HMDMemoryGraphSupported)supported {
    NSMutableArray *reasonArr = [NSMutableArray new];
    if (!(supported & HMDMemoryGraphSupportedNotSimulator)) {
        [reasonArr addObject:@"Simulator is not supported"];
    }
    if (!(supported & HMDMemoryGraphSupportedIOSVersion)) {
        [reasonArr addObject:@"iOS version is too low"];
    }
    if (!(supported & HMDMemoryGraphSupportedARM64)) {
        [reasonArr addObject:@"32-bit devices are not supported"];
    }
    if (!(supported & HMDMemoryGraphSupportedPerformance)) {
        [reasonArr addObject:@"Device performance is poor"];
    }
    if (!(supported & HMDMemoryGraphSupportedNotASAN)) {
        [reasonArr addObject:@"ASAN is not supported"];
    }
    if (!(supported & HMDMemoryGraphSupportedLimitPerDay)) {
        [reasonArr addObject:@"Trigger the limit of daily analysis"];
    }
    
    NSString *reason = [reasonArr componentsJoinedByString:@","];
    return reason;
}

- (void)activateMemoryChecker {
    HMDMemoryGraphConfig *config = (HMDMemoryGraphConfig *)self.config;
    HMDMemoryCheckerBuilder builder = {0};
    builder.manualMemoryWarning = config.manualMemoryWarning;
    builder.dangerThreshold = config.dangerThresholdMB*HMD_MB;
    builder.growingStep = config.growingStepMB*HMD_MB;
    builder.checkInterval = config.checkInterval;
    builder.minNotifyInterval = config.minGenerateMinuteInterval*60.f;
    builder.calculateSlardarMallocMemory = config.calculateSlardarMallocMemory;
    builder.memorySurgeThresholdMB = (int)config.memorySurgeThresholdMB;
    [self.checker activateByBuilder:builder];
}

- (BOOL)exceedLimitPerDayForConfig:(HMDMemoryGraphConfig *)config {
    NSDictionary *dateAndCountDict = [[HMDUserDefaults standardUserDefaults] objectForKey:kHMDMemoryGrapthGenerateDateAndCount];
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    //A string representation of date formatted using the receiver’s current settings.
    NSString *todayString = [dateFormatter stringFromDate:nowDate];
    NSNumber *generateTimes = [dateAndCountDict objectForKey:todayString];
    BOOL exceedLimitPerDay = generateTimes && generateTimes.unsignedIntegerValue >= config.maxTimesPerDay;
    
    if (exceedLimitPerDay)
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Memorygraph module exceed limit : %lu, today : %@", config.maxTimesPerDay, todayString);
    
    return exceedLimitPerDay;
}

#pragma mark - notification
- (void)didReceiveMemoryWarningNotification:(NSNotification *)notification {
    self.memoryWarningReceived = YES;
}

- (void)didReceiveMemoryWillPeakedNotification:(NSNotification *)notification {
//    dispatch_async(dispatch_get_main_queue(), ^{
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        [[UIApplication sharedApplication] performSelector:NSSelectorFromString([NSString stringWithFormat:@"_%@%@%@", @"perform", @"Memory", @"Warning"])];
//#pragma clang diagnostic pop
//    });
}

- (void)didReceiveMemoryPeakedNotification:(NSNotification *)notification {
    hmd_MemoryBytes memoryInfo = {0};
    NSData *data = notification.object;
    if(data && data.length > 0) {
        [data getBytes:&memoryInfo length:sizeof(memoryInfo)];
    } else {
        //取不到就用当前的兜底
        memoryInfo = hmd_getMemoryBytes();
    }
    self.isMemorySurge = [notification.userInfo hmd_boolForKey:kHMDMemorySurgeStr];
    __weak typeof(self) weakSelf = self;
    
    [self doGenerateMemoryGraphActivateManner:@"online" memoryInfo:memoryInfo minRemainingMemoryMB:((HMDMemoryGraphConfig *)self.config).minRemainingMemoryMB completeBlock:^(NSError * _Nullable error, NSString * _Nullable identifier) {
        [weakSelf increaseGenerateTimesAndCheckLimit];
    }];
}

- (void)increaseGenerateTimesAndCheckLimit {
    NSDictionary *dateAndCountDict = [[HMDUserDefaults standardUserDefaults] objectForKey:kHMDMemoryGrapthGenerateDateAndCount];
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    //A string representation of date formatted using the receiver’s current settings.
    NSString *todayString = [dateFormatter stringFromDate:nowDate] ?: @"today";
    NSNumber *generateTimes = [dateAndCountDict objectForKey:todayString];
    NSUInteger thisTimes = generateTimes.unsignedIntegerValue;

    
    if (!dateAndCountDict) {
        thisTimes = 1;
    } else {
        if (generateTimes) {
            thisTimes++;
        } else {
            thisTimes = 1;
        }
    }
    dateAndCountDict = @{todayString:@(thisTimes)};
    [[HMDUserDefaults standardUserDefaults] setObject:dateAndCountDict forKey:kHMDMemoryGrapthGenerateDateAndCount];
    
    //超过单日的最大上限则尝试在第二天0点的时候继续工作
    if (thisTimes >= ((HMDMemoryGraphConfig *)self.config).maxTimesPerDay) {
        [self.checker invalidate];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:nowDate];
        NSDate *todayZeroDate = [calendar dateFromComponents:components];
        NSDate *tomorrowZeroDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:todayZeroDate options:0];
        NSTimeInterval delaySeconds = [tomorrowZeroDate timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970];
        hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), self.generateQueue, ^{
            [self activateMemoryChecker];
        });
    }
}

#if RANGERSAPM
- (void)applicationStateChanged:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification] || [notification.name isEqualToString:UIApplicationDidBecomeActiveNotification] ) {
        self.isBackground = NO;
    } else if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        self.isBackground = YES;
    }
}
#endif

#pragma mark - generate memory graph

- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload
                          finishBlock:(HMDMemoryGraphFinishBlock)finishBlock {
    [self manualGenerateImmediateUpload:immediateUpload activateManner:@"manual" finishBlock:finishBlock];
}

- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload activateManner:(NSString *)activateManner finishBlock:(HMDMemoryGraphFinishBlock)finishBlock {
    [self manualGenerateImmediateUpload:immediateUpload activateManner:activateManner customFilters:nil customContext:nil finishBlock:finishBlock];
}

- (void)manualGenerateImmediateUpload:(BOOL)immediateUpload activateManner:(NSString *)activateManner customFilters:(NSDictionary<NSString *,id> *)filters customContext:(NSDictionary<NSString *,id> *)context finishBlock:(HMDMemoryGraphFinishBlock)finishBlock {
    self.filters = filters;
    self.context = context;
    [self resetMemorySurgeFlag]; // 手动触发默认无内存突增
    __weak typeof(self) weakSelf = self;
    hmd_MemoryBytes memoryInfo = hmd_getMemoryBytes();
    
    [self doGenerateMemoryGraphActivateManner:activateManner ?: @"manual" memoryInfo:memoryInfo minRemainingMemoryMB:((HMDMemoryGraphConfig *)self.config).minRemainingMemoryMB completeBlock:^(NSError * _Nullable error, NSString * _Nullable identifier) {
        if (error || !immediateUpload) {
            if (finishBlock) finishBlock(error);
        }
        else {
            [weakSelf zipMemoryGraphWithIdentifier:identifier activateManner:activateManner immediateUpload:immediateUpload completeBlock:^(NSError * _Nullable error, NSString * _Nullable zipPath) {
                if (finishBlock) finishBlock(error);
            }];
        }
    }];
}

- (void)cloudCommandGenerateWithRemainingMemory:(NSUInteger)remainingMemory
                                  completeBlock:(HMDMemoryGraphCloudControlCompleteBlock)completeBlock {
    __weak typeof(self) weakSelf = self;
    NSString *activateManner = @"cloud_control";
    hmd_MemoryBytes memoryInfo = hmd_getMemoryBytes();
    remainingMemory = remainingMemory ?: [(HMDMemoryGraphConfig *)self.config minRemainingMemoryMB];
    [self resetMemorySurgeFlag]; //云控触发默认无内存突增
    [self doGenerateMemoryGraphActivateManner:activateManner memoryInfo:memoryInfo minRemainingMemoryMB:remainingMemory completeBlock:^(NSError * _Nullable error, NSString * _Nullable identifier) {
        if (error) {
            if (completeBlock) completeBlock(error, nil, nil);
        }
        else {
            NSDictionary *finalEnvParams = [HMDMemoryGraphUploader checkEnvParamsWithIdentifier:identifier];
            
            [weakSelf zipMemoryGraphWithIdentifier:identifier activateManner:activateManner immediateUpload:NO completeBlock:^(NSError * _Nullable error, NSString * _Nullable zipFilepath) {
                if (completeBlock) {
                    completeBlock(error, zipFilepath, finalEnvParams);
                }
            }];
        }
    }];
}

- (void)doGenerateMemoryGraphActivateManner:(NSString*)activateManner
                                 memoryInfo:(hmd_MemoryBytes)memoryInfo
                       minRemainingMemoryMB:(NSUInteger)minRemainingMemoryMB
                              completeBlock:(HMDMemoryGraphCompleteBlock)completeBlock {
    if ([self isDeviceSupported] != HMDMemoryGraphSupportedDeviceAll) {
        if (completeBlock) {
            NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeDeviceNotSupported userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar device do not support memory graph", NSLocalizedDescriptionKey:@"slardar device do not support memory graph"}];
            
            completeBlock(error, nil);
        }
        return;
    }
    if (hmd_drop_data(HMDReporterMemoryGraph)) {
        return;
    }
    hmd_safe_dispatch_async(self.generateQueue, ^{
        static NSInteger times = 0;
        NSString *identifier = [NSString stringWithFormat:@"%@_%ld", [HMDSessionTracker sharedInstance].eternalSessionID, (long)times];
        NSString *envFileName = [identifier stringByAppendingPathExtension:kHMDMemoryGraphEnvFileExtension];
        NSString *preparedPath = [HMDMemoryGraphUploader memoryGraphPreparedPath];
        NSString *envPath = [preparedPath stringByAppendingPathComponent:envFileName];
        
        NSMutableDictionary *envParams = [NSMutableDictionary dictionary];
        [envParams hmd_setObject:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        long long timestamp = MilliSecond([[NSDate date] timeIntervalSince1970]);
        uint64_t freeDiskMB = [HMDDiskUsage getFreeDiskSpace] / HMD_MB;
        NSInteger freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
        NSString *file_uuid = [[NSUUID UUID] UUIDString];
        [data hmd_setObject:file_uuid forKey:@"file_uuid"];//data association with memorygraph
        [data hmd_setObject:@(timestamp) forKey:@"timestamp"];
        [data hmd_setObject:activateManner forKey:@"activate_manner"];
        [data hmd_setObject:@(self.memoryWarningReceived) forKey:@"memory_warning_received"];
        [data hmd_setObject:@(memoryInfo.appMemory/HMD_MB) forKey:@"memory_usage"];
        [data hmd_setObject:@(freeDiskBlockSize) forKey:@"d_zoom_free"];
        [data hmd_setObject:@(hmd_calculateMemorySizeLevel(memoryInfo.availabelMemory)) forKey:HMD_Free_Memory_Key];
        [data hmd_setObject:@(hmd_calculateMemorySizeLevel(memoryInfo.totalMemory)) forKey:HMD_Total_Memory_Key];
        [data hmd_setObject:@([HMDSessionTracker currentSession].timeInSession) forKey:@"inapp_time"];
        [data hmd_setObject:[HMDNetworkHelper connectTypeName] forKey:@"access"];
        [data hmd_setObject:[HMDTracker getLastSceneIfAvailable] forKey:@"last_scene"];
#if RANGERSAPM
        [data hmd_setObject:[HMDInfo defaultInfo].systemVersion forKey:@"os_version"];
        [data hmd_setObject:[HMDInfo defaultInfo].shortVersion forKey:@"app_version"];
        [data hmd_setObject:[HMDInfo defaultInfo].buildVersion forKey:@"update_version_code"];
        [data hmd_setObject:[HMDInfo defaultInfo].sdkVersion forKey:@"heimdallr_version"];
        [data hmd_setObject:@(self.isBackground) forKey:@"is_background"];
        
        NSMutableDictionary *customContext = [NSMutableDictionary dictionaryWithDictionary:[HMDInjectedInfo defaultInfo].customContext];
        [customContext hmd_setObject:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
        [customContext hmd_setObject:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
        [customContext hmd_setObject:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
        
        [data hmd_setObject:customContext forKey:@"custom"];
        [data hmd_setObject:[HMDInjectedInfo defaultInfo].filters forKey:@"filters"];
#endif
        NSMutableDictionary *filters = [NSMutableDictionary dictionary];
        if ([HMDInjectedInfo defaultInfo].filters.count > 0) {
            [filters hmd_addEntriesFromDict:[HMDInjectedInfo defaultInfo].filters];
        }
        if (self.filters.count > 0) {
            [filters hmd_addEntriesFromDict:self.filters];
            //reset custom filters
            self.filters = nil;
        }
        [filters hmd_setObject:self.isMemorySurge?@"1":@"0" forKey:@"isMemorySurge"];
        [self resetMemorySurgeFlag];
        if (filters.count > 0) {
            [data hmd_setObject:filters forKey:@"filters"];
        }
        
        NSMutableDictionary *context = [NSMutableDictionary dictionary];
        if ([HMDInjectedInfo defaultInfo].customContext.count > 0) {
            [context hmd_addEntriesFromDict:[HMDInjectedInfo defaultInfo].customContext];
        }
        if (self.context.count > 0) {
            [context hmd_addEntriesFromDict:self.context];
            //reset custom context
            self.context = nil;
        }
        if (context.count > 0) {
            [data hmd_setObject:context forKey:@"custom"];
        }
        
        [envParams hmd_setObject:[data copy] forKey:@"data"];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr do generate memory graph with activateManner : %@, identifier : %@, envParams : %@", activateManner, identifier, envParams);
        
        // memory graph内部预留了10MB供其他使用，如果maxMemoryUsage小于10MB，则会导致其使用maxMemoryUsage的默认值100MB，这不是我们想要的
        if ((float)memoryInfo.availabelMemory / HMD_MB <= 10) {
            NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeNoMemorySpace userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar no memory space for memorygraph", NSLocalizedDescriptionKey:@"slardar no memory space for memorygraph"}];
            
            if (completeBlock) completeBlock(error, nil);
            
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr do generate memory graph failed : %@, identifier : %@, envParams : %@", error.localizedFailureReason, identifier, envParams);
            return ;
        }
        
        // 磁盘空间小于等于minRemainingDiskSpaceMB时，memory graph一定会失败
        if (freeDiskMB <= minRemainingDiskSpaceMB) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            __block BOOL hasSpace = NO;
            [[HMDDiskSpaceDistribution sharedInstance] getMoreDiskSpaceWithSize:(NSUInteger)(minRemainingMemoryMB * HMD_MB) priority:HMDDiskSpacePriorityMemoryGraph usingBlock:^(BOOL * _Nonnull stop, BOOL moreSpace) {
                if (moreSpace) {
                    if ((NSUInteger)[HMDDiskUsage getFreeDiskSpace] > minRemainingMemoryMB) {
                        hasSpace = YES;
                        *stop = YES;
                        dispatch_semaphore_signal(semaphore);
                    }
                }
                else {
                    dispatch_semaphore_signal(semaphore);
                }
            }];
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 2.f * NSEC_PER_SEC));
            
            if (!hasSpace) {
                NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeNoDiskSpace userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar no disk space for memorygraph", NSLocalizedDescriptionKey:@"slardar no disk space for memorygraph"}];
                
                if (completeBlock) completeBlock(error, nil);
                
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr do generate memory graph failed : %@, identifier : %@, envParams : %@", error.localizedFailureReason, identifier, envParams);
                return ;
            }
        }
        
        NSFileManager *manager = [NSFileManager defaultManager];
        //必须先创建文件夹否则文件写入一定会失败
        NSError *createDicErr = nil;
        if (![manager fileExistsAtPath:preparedPath]) {
            [manager createDirectoryAtPath:preparedPath withIntermediateDirectories:YES attributes:nil error:&createDicErr];
        }
        if (!createDicErr) {
            BOOL writeEnvSuccess = [envParams writeToFile:envPath atomically:YES];
            if (!writeEnvSuccess)
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph write envParams failed, identifier : %@", identifier);
        }
        else {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph create directory failed : %@, path : %@", createDicErr.localizedDescription, preparedPath);
        }
        
        NSError *error = nil;
        uint64_t appAvailableMemory = floorf(memoryInfo.availabelMemory / HMD_MB);
        HMDMemoryGraphConfig *config = (HMDMemoryGraphConfig *)self.config;
        uint64_t maxFileSize = MIN(freeDiskMB, config.maxFileSizeMB);
        BOOL enbaleCPPSymbolicate = config.enableCPPSymbolicate;
        BOOL enableLeakNodeCalibration = config.enableLeakNodeCalibration;
        NSMutableDictionary *extraConfiguration = [NSMutableDictionary dictionary];//新增配置项统一存储
        [extraConfiguration hmd_setObject:[NSNumber numberWithBool:enableLeakNodeCalibration] forKey:@"enableLeakNodeCalibration"];
        [extraConfiguration hmd_setObject:[NSNumber numberWithBool:config.calculateSlardarMallocMemory] forKey:@"shouldCalculateSlardarMallocMemory"];
        [extraConfiguration hmd_setObject:[NSNumber numberWithBool:config.enableCFInstanceSymbolicate] forKey:@"enableCFInstanceSymbolicate"];
        [extraConfiguration hmd_setObject:[NSNumber numberWithBool:config.enableCircularReferenceDetect] forKey:@"enableCircularReferenceDetect"];
        [extraConfiguration hmd_setObject:file_uuid forKey:@"fileUuid"];
        AWEMemoryGraphGenerateRequest *request = [AWEMemoryGraphGenerateRequest new];
        request.path = [[HMDMemoryGraphUploader memoryGraphProcessingPath] stringByAppendingPathComponent:identifier];
        /* 预留的安全内存的空间也就是MemoryGraph模块本身允许占用的最大内存
        如果当前App可用内存已经小于等于这个阈值，则强制降级，降级模式开启之后会忽略maxMemoryUsage参数 */
        request.useNaiveVersion = appAvailableMemory <= minRemainingMemoryMB;
        request.maxMemoryUsage = [NSNumber numberWithUnsignedLongLong:minRemainingMemoryMB];
        request.maxFileSize = [NSNumber numberWithUnsignedLongLong:maxFileSize];
        request.doCppSymbolic = enbaleCPPSymbolicate;
        request.memoryUsageBeforeSuspend = memoryInfo.appMemory;
        request.checker = ^BOOL{
            return isMemoryGraphEnvSafe()? YES:NO;
        };
        request.threadParser = ^NSString *(thread_t port) {
            char threadName[256] = {0};
            hmdthread_getName(port, threadName, 256);
            if (strlen(threadName) > 0 && strcmp(threadName, "null") != 0) {
                return [NSString stringWithUTF8String:threadName];
            }
            return @"";
        };

        request.timeOutDuration = config.timeOutInterval;
        request.extraConfiguration = extraConfiguration;
        
        NSDictionary *extra = @{@"identifier":identifier ?: @"unkonwn"};
        NSDictionary *category = @{@"activateManner":activateManner ?: @"unkonwn"};
        NSTimeInterval generatorTimeStart = [[NSDate date] timeIntervalSince1970];
        [HMDMonitorService trackService:kEventMemoryGraphGenerateStart metrics:nil dimension:category extra:extra syncWrite:YES];
        [HMDDebugLogger printLog:@"MemoryGraph generate start."];
        AWEMemoryGraphDegradeType degrade_flag = DegradeTypeNone;
        [[HMDUserDefaults standardUserDefaults] setBool:YES forKey:HHMDMemoryGraphLastTimeInterrupt];
        [AWEMemoryGraphGenerator generateMemoryGraphWithRequest:request error:&error degrade:&degrade_flag];
        [[HMDUserDefaults standardUserDefaults] setBool:NO forKey:HHMDMemoryGraphLastTimeInterrupt];
        NSTimeInterval generatorTimeEnd = [[NSDate date] timeIntervalSince1970];
        NSString *reasonStr = error ? error.localizedFailureReason : @"success";
        NSNumber *status = error ? [NSNumber numberWithInteger:error.code] : @(0);
        NSString *degrade_type = @"none";
        if(degrade_flag == DegradeTypeNodeOverSize) {
            degrade_type = @"nodeOverSize";
        }
        else if(degrade_flag == DegradeTypeMemoryIssue) {
            degrade_type = @"memoryIssue";
        }
#if !RANGERSAPM
        degrade_type = [NSString stringWithFormat:@"%@-%@", error?@"fail":@"success", degrade_type];
#endif
        category = @{@"status":status, @"reason":reasonStr, @"activateManner":activateManner ?: @"unkonwn", @"degradeType":degrade_type};
        NSDictionary *metric = @{@"duration":@(generatorTimeEnd - generatorTimeStart)};
        [HMDMonitorService trackService:kEventMemoryGraphGenerateEnd metrics:metric dimension:category extra:extra syncWrite:YES];
        if (error) {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr generate memory graph failed : %@, error code : %ld", error.localizedFailureReason, error.code);
            [HMDDebugLogger printLog:[NSString stringWithFormat:@"MemoryGraph generate failed, reason : %@.", error.localizedDescription]];
        } else {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr generate memory graph end");
            [HMDDebugLogger printLog:@"MemoryGraph generate successfully!"];
        }
        
        times++;
        if (error) {
            if ([manager fileExistsAtPath:envPath]) {
                [manager removeItemAtPath:envPath error:nil];
            }
        }
        
        if (completeBlock) {
            completeBlock(error, identifier);
        }
    });
}

- (void)zipMemoryGraphWithIdentifier:(NSString *)identifier
                      activateManner:(NSString*)activateManner
                     immediateUpload:(BOOL)immediateUpload
                       completeBlock:(HMDMemoryGraphCompleteBlock)completeBlock {
    NSString *zipPath = [[HMDMemoryGraphUploader memoryGraphPreparedPath] stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:kHMDMemoryGraphZipFileExtension]];
    NSString *graphPath = [[HMDMemoryGraphUploader memoryGraphProcessingPath] stringByAppendingPathComponent:identifier];
    NSString *zipTmpName = [NSString stringWithFormat:@"%lld.tmp",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
    NSString *zipTmpPath = [[HMDMemoryGraphUploader memoryGraphPreparedPath] stringByAppendingPathComponent:zipTmpName];
    
    NSTimeInterval zipTimeStart = [[NSDate date] timeIntervalSince1970];
    BOOL zipValid = [self.uploader safeCreateZipFileAtPath:zipTmpPath withContentsOfDirectory:graphPath];
    NSTimeInterval zipTimeEnd = [[NSDate date] timeIntervalSince1970];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:graphPath error:nil];
    });
    if (zipValid) {
        rename(zipTmpPath.UTF8String, zipPath.UTF8String);
        if (immediateUpload) {
            [self.uploader uploadIdentifier:identifier
                             activateManner:activateManner
                            needCheckServer:NO
                                finishBlock:^(NSError * _Nullable error) {
                if (completeBlock) completeBlock(error, zipPath);
                if (!error) [HMDMemoryGraphUploader cleanupIdentifier:identifier];
            }];
        }
        else {
            if (completeBlock) completeBlock(nil, zipPath);
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:zipTmpPath error:nil];
            [HMDMemoryGraphUploader cleanupIdentifier:identifier];
        });
        NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeGraphZipError userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar zip memorygraph raw directory error", NSLocalizedDescriptionKey:@"slardar zip memorygraph raw directory error"}];
        if (completeBlock) completeBlock(error, nil);
        NSDictionary *extra = @{@"identifier":identifier ?: @"unkonwn"};
        NSDictionary *category = @{@"status":@(error.code).stringValue, @"reason":error.localizedFailureReason, @"activateManner":activateManner ?: @"unkonwn"};
        NSDictionary *metric = @{@"duration":@(zipTimeEnd - zipTimeStart)};
        [HMDMonitorService trackService:kEventMemoryGraphZip metrics:metric dimension:category extra:extra syncWrite:YES];
        
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph zip is not valid, identifier : %@", identifier);
    }
}

/// 提供给OOMCrash模块使用，获取上一次MemoryGraph采集是否完成，辅助分析OOM
+ (BOOL)lastTimeMemoryDumpInterrupt {
    BOOL res = [[HMDUserDefaults standardUserDefaults]boolForKey:HHMDMemoryGraphLastTimeInterrupt];
    [[HMDUserDefaults standardUserDefaults]setBool:NO forKey:HHMDMemoryGraphLastTimeInterrupt];
    return res;
}

- (void)resetMemorySurgeFlag {
    self.isMemorySurge = NO;
}

@end
