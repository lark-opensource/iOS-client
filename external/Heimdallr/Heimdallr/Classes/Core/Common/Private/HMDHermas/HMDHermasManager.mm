//
//  HMDHermasManager.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 22/3/2022.
//

#import "HMDHermasManager.h"
#import "HMDInjectedInfo.h"
#import "HMDHeimdallrConfig.h"
#import "HMDDoubleUploadSettings.h"
#import "HMDGeneralAPISettings.h"
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#import "HMDUploadHelper.h"
#import "HMDNetworkInjector.h"
#import <BDDataDecorator/NSData+DataDecorator.h>
#import "HMDDynamicCall.h"
#import "HMDHermasUploadSetting.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDDoubleReporter.h"
#import "HMDConfigManager.h"
#import "HMDMemoryUsage.h"
#import "HMDModuleProtocol.h"
#import "HMDPerformanceModule.h"
#import "HMDHighPriorityModule.h"
#import "HMDExceptionModule.h"
#import "HMDUserExceptionModule.h"
#import "HMDOpenTracingModule.h"
#import "HMDHermasHelper.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDALogProtocol.h"
#import "HMDUserDefaults.h"
#import "HMDHermasNetworkManager.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDGCDTimer.h"
#import "HMDReportDowngrador.h"
// Utility
#import "HMDMacroManager.h"
// PrivateServices
#import "HMDURLSettings.h"

NSString * const kHermasPlistSuiteName = @"hermas";

@interface HMDInfo (Description)
- (NSString *)devicePerformanceDescription;
@end

@implementation HMDInfo (Description)

- (NSString *)devicePerformanceDescription {
    NSString *desc = @"unknown";
    switch ([HMDInfo defaultInfo].devicePerformaceLevel) {
        case HMDDevicePerformanceLevelPoorest:
            desc = @"poorest";
            break;
        case HMDDevicePerformanceLevelPoor:
            desc = @"poor";
            break;
        case HMDDevicePerformanceLevelMedium:
            desc = @"medium";
            break;
        case HMDDevicePerformanceLevelHigh:
            desc = @"high";
            break;
        case HMDDevicePerformanceLevelHighest:
            desc = @"highest";
            break;
    }
    return desc;
}

@end

@interface HMEngine ()
+ (void)setEnableHermasRefactorFromSDK:(BOOL)enableHermasRefactor;
@end



@interface HMDHermasManager () <HMExternalSearchDataSource>
@property (nonatomic, strong) HMDHeimdallrConfig *heimdallrConfig;
@property (nonatomic, strong) HMGlobalConfig *globalConfig;
@property (nonatomic, strong) NSArray<id<HMDModuleProtocol, HMDMigrateProtocol, HMDExternalSearchProtocol>> *modules;
@property (nonatomic, strong) dispatch_queue_t migrateQueue;
@property (nonatomic, strong) HMDGCDTimer *timer;

@end

@implementation HMDHermasManager

+ (instancetype)defaultManager {
    static HMDHermasManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)dealloc {
    @try {
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"exceptionStopUpload"];
    } @catch (NSException *exception) {
        
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer cancelTimer];
}
    

- (instancetype)init {
    self = [super init];
    if (self) {
        // plist suite
        hermas_set_plist_suite_name_only_once([HeimdallrUtilities customPlistSuiteComponent:kHermasPlistSuiteName]);
        
        // set debug
        [[HMEngine sharedEngine] setIsDebug:HMD_IS_DEBUG];
        
        // try to inject ttnet, if it failed, the default NSURLSession will be used
        [[HMEngine sharedEngine] registerNetworkManager:[HMDHermasNetworkManager new]];
        
        // setup delegate
        [HMEngine sharedEngine].searchDataSource = self;
        
        // gcd timer
        self.timer = [[HMDGCDTimer alloc] init];
        
        // notification
        [self registerNotification];
        
        // setup config
        [self setupConfig];
        
        // update cogfig
        [self updateConfig:nil];
        
        // kvo
        [self addKVOObserver];
    }
    return self;
}

- (NSArray *)modules {
    if (!_modules) {
        _modules = @[
            [HMDPerformanceModule new],
            [HMDExceptionModule new],
            [HMDUserExceptionModule new],
            [HMDOpenTracingModule new],
            [HMDHighPriorityModule new]
        ];
    }
    return _modules;
}

- (void)setupConfig {
    [self setupGlobalConfig];
    
    // setup global and module config
    [self.modules enumerateObjectsUsingBlock:^(id<HMDModuleProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setupModuleConfig];
    }];
}


- (void)updateConfig:(HMDHeimdallrConfig *)config {
    self.heimdallrConfig = config;
    
    [HMDReportDowngrador sharedInstance].enabled = config.apiSettings.performanceAPISetting.enableDowngradeByChannel;
    
    // update global config
    [self updateGlobalConfig:config];
    
    // update module config
    [self.modules enumerateObjectsUsingBlock:^(id<HMDModuleProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj updateModuleConfig:config];
    }];
    
    // migrate when config is not nil at the first time
    [self migrateOnceIfNeeded:config];
}


- (void)migrateForward {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr Migration", @"start migrate data forward");
    // dispatch to modules
    [self.modules enumerateObjectsUsingBlock:^(id<HMDMigrateProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj migrateForward];
    }];
}


- (void)migrateBack {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr Migration", @"start migrate data back");
    // rollback migration
    [self.modules enumerateObjectsUsingBlock:^(id<HMDMigrateProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj migrateBack];
    }];
}

- (dispatch_queue_t)migrateQueue {
    if (!_migrateQueue) {
        _migrateQueue = dispatch_queue_create("queue.migrate.heimdallr.com", DISPATCH_QUEUE_SERIAL);
    }
    return _migrateQueue;
}

- (void)migrateOnceIfNeeded:(HMDHeimdallrConfig *)config {
    if (!config) return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __weak __typeof(self) wself = self;
        [self.timer scheduledDispatchTimerWithInterval:5 queue:self.migrateQueue repeats:NO action:^{
            __strong __typeof(wself) sself = wself;
            if (hermas_enabled()) {
                [sself migrateForward];
            } else {
                [sself migrateBack];
            }
        }];
    });
}

#pragma mark - Notification

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadSuccessed:) name:kModuleUploadSuccess object:nil];
}

- (void)uploadSuccessed:(NSNotification *)notification {
    [[HMDConfigManager sharedInstance] asyncFetchRemoteConfig:NO];
}

#pragma mark - GlobalConfig

- (void)setupGlobalConfig {
    HMGlobalConfig *globalConfig = [[HMGlobalConfig alloc] init];
    globalConfig.rootDir = [HMDHermasHelper rootPath];
    globalConfig.hostAid = [HMDInjectedInfo defaultInfo].appID;
    globalConfig.heimdallrAid = @"2085";
    globalConfig.zstdDictPath = @"/monitor/collect/zstd_dict/";
    globalConfig.devicePerformance = [[HMDInfo defaultInfo] devicePerformanceDescription];
    globalConfig.reportHeaderLowLevelParams = [HMDUploadHelper sharedInstance].infrequentChangeHeaderParam;
    globalConfig.reportHeaderConstantParams = [HMDUploadHelper sharedInstance].constantHeaderParam;
    globalConfig.encryptBlock = ^NSData * _Nonnull(NSData * _Nullable data) {
        HMDNetEncryptBlock encryptBlock = [HMDNetworkInjector sharedInstance].encryptBlock;
        return encryptBlock ? encryptBlock(data) : [data bd_dataByDecorated];
    };
    globalConfig.quotaDictPath = [HMDURLSettings quotaStateCheckPath];
    globalConfig.memoryBlock = ^int64_t{
        return hmd_getMemoryBytes().appMemory;
    };
    globalConfig.memoryLimitBlock = ^int64_t{
        return hmd_getDeviceMemoryLimit();
    };
    
    globalConfig.virtualMemoryBlock = ^int64_t{
        return hmd_getMemoryBytesExtend().virtualMemory;
    };
    globalConfig.totalVirtualMemoryBlock = ^int64_t{
        return hmd_getMemoryBytesExtend().totalVirtualMemory;
    };

    globalConfig.sequenceCodeGenerator = ^int64_t(NSString * _Nullable className) {
        @autoreleasepool {
            return [[HMDHermasCounter shared] generateSequenceCode:className];
        }
    };
    globalConfig.reportCommonParams = [HMDInjectedInfo defaultInfo].commonParams;
    globalConfig.reportCommonParamsBlock = ^{
        @autoreleasepool {
            return [[HMDInjectedInfo defaultInfo] commonParams];
        }
    };
    
    globalConfig.deviceIdRequestBlock = ^{
        @autoreleasepool {
            return [[HMDInjectedInfo defaultInfo] deviceID];
        }
    };
    
    globalConfig.useURLSessionUploadBlock = ^BOOL{
        @autoreleasepool {
            return [[HMDInjectedInfo defaultInfo] useURLSessionUpload];
        }
    };
    
    globalConfig.stopWriteToDiskWhenUnhitBlock = ^BOOL{
        @autoreleasepool {
            return [[HMDInjectedInfo defaultInfo] stopWriteToDiskWhenUnhit];
        }
    };
    
    self.globalConfig = globalConfig;
    [[HMEngine sharedEngine] setupGlobalConfig:globalConfig];
}


- (void)updateGlobalConfig:(HMDHeimdallrConfig *)config {
    // cleanup config
    HMDHermasCleanupSetting *hermasCleanupSetting = self.heimdallrConfig.cleanupConfig.hermasCleanupSetting;

    self.globalConfig.maxStoreTime = hermasCleanupSetting.maxStoreTime * SEC_PER_DAY ?: 7 * SEC_PER_DAY;
    self.globalConfig.maxStoreSize = hermasCleanupSetting.maxStoreSize * BYTE_PER_MB ?: 500 * BYTE_PER_MB;

    // upload config
    HMDHermasUploadSetting *hermasUploadSetting = self.heimdallrConfig.apiSettings.hermasUploadSetting;
    self.globalConfig.maxLogNumber = hermasUploadSetting.maxLogNumber ?: 1000;
    self.globalConfig.maxFileSize =  hermasUploadSetting.maxFileSize * BYTE_PER_MB ?: 0.25 * BYTE_PER_MB;
    self.globalConfig.maxReportSize = hermasUploadSetting.maxUploadSize * BYTE_PER_MB ?: 20 * BYTE_PER_MB;
    self.globalConfig.limitReportSize = hermasUploadSetting.limitUploadSize * BYTE_PER_MB ?: 10 * BYTE_PER_MB;
    self.globalConfig.reportInterval = hermasUploadSetting.uploadInterval * MILLISECONDS ?: 30 * MILLISECONDS;
    self.globalConfig.limitReportInterval = hermasUploadSetting.limitUploadInterval * MILLISECONDS ?: 15 * MILLISECONDS;
    
    // if the device is low level performance, make maxReportSize smaller to avoid oom
    if ([HMDInfo defaultInfo].devicePerformaceLevel <= HMDDevicePerformanceLevelPoor) {
        self.globalConfig.maxReportSize = self.globalConfig.maxReportSize * 0.7;
    }
    
    self.globalConfig.hostAid = [HMDInjectedInfo defaultInfo].appID;
    
    // update global config to hermas
    [[HMEngine sharedEngine] updateGlobalConfig:self.globalConfig];
    
    // update refactor switch (which will determine if the app enable refactor on the next launch)
    if (hermasUploadSetting) {
        BOOL enableHermasRefactor = hermasUploadSetting.enableRefactorOpen;
        [HMEngine setEnableHermasRefactorFromSDK:enableHermasRefactor];
       
        NSInteger recordThreadShareMask = hermasUploadSetting.recordThreadShareMask;
        [[HMDUserDefaults standardUserDefaults] setInteger:recordThreadShareMask forKey:@"record_thread_share_mask"];
    }
}

#pragma mark - HMExternalSearchDataSource

- (NSArray *)getDataWithParam:(HMSearchParam *)param {
    NSMutableArray *result = @[].mutableCopy;
    [self.modules enumerateObjectsUsingBlock:^(id<HMDExternalSearchProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *temp = [obj getDataWithParam:param];
        [result addObjectsFromArray:temp];
    }];
    return result;
}

- (void)removeDataWithParam:(HMSearchParam *)param {
    [self.modules enumerateObjectsUsingBlock:^(id<HMDExternalSearchProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeDataWithParam:param];
    }];
}

+ (HMInstance *)sharedPerformanceInstance {
    HMInstanceConfig *instanceConfig = [[HMInstanceConfig alloc] initWithModuleId:kModulePerformaceName aid:[HMDInjectedInfo defaultInfo].appID];
    instanceConfig.enableAggregate = YES;
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithConfig:instanceConfig];
    return instance;
}

+ (HMInstance *)sharedHighPriorityInstance {
    HMInstanceConfig *instanceConfig = [[HMInstanceConfig alloc] initWithModuleId:kModuleHighPriorityName aid:[HMDInjectedInfo defaultInfo].appID];
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithConfig:instanceConfig];
    return instance;
}

#pragma mark - KVO
- (void)addKVOObserver {
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"exceptionStopUpload"
                                       options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                       context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == [HMDInjectedInfo defaultInfo] && [keyPath isEqualToString:@"exceptionStopUpload"]) {
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        BOOL needDegrade = NO;
        if (newValue && ![newValue isKindOfClass:[NSNull class]]) {
            HMDStopUpload exceptionStopUpload = newValue;
            needDegrade = exceptionStopUpload && exceptionStopUpload();
        }
        [[HMEngine sharedEngine] updateReportDegradeState:needDegrade moduleId:kModuleExceptionName];
        [[HMEngine sharedEngine] updateReportDegradeState:needDegrade moduleId:kModuleUserExceptionName];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
