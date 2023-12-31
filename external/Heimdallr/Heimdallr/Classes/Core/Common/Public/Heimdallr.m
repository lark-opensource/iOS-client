//
//  Heimdallr.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#include "pthread_extended.h"
#include <stdatomic.h>
#import "HMDSimpleBackgroundTask.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "Heimdallr+DebugReal.h"
#import "HMDRecordStore.h"
#import "HMDExceptionReporter.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "HMDConfigManager.h"
#import "HeimdallrLocalModule.h"
#import "NSObject+HMDAttributes.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDInjectedInfo+Upload.h"
#import "HeimdallrModule.h"
#import "HMDMacro.h"
#import "Heimdallr+ModuleCallback.h"
#import "HMDModuleCallbackPair.h"
#import "HMDGeneralAPISettings.h"

#import "NSArray+HMDSafe.h"
#if !SIMPLIFYEXTENSION
#import "HMDModuleConfig+StartWeight.h"
#endif
#import "NSDictionary+HMDSafe.h"

#import "HMDDynamicCall.h"
#import "HeimdallrUtilities.h"
#import "NSDictionary+HMDJSON.h"
#import "NSData+HMDJSON.h"
#import "HMDMemoryUsage.h"
#import "HMDUserDefaults.h"
#import "HMDBackgroundMonitor.h"
#import "HMDGCD.h"
#import "HMDCustomReportManager+Private.h"
#import "HMDServiceContext.h"
#import "HMDHeimdallrConfig+CloudCommand.h"
#import "Heimdallr+ManualControl.h"
#import "Heimdallr+SafeMode.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import "HMDHermasManager.h"
// PrivateServices
#import "HMDMonitorService.h"

NSString *kHMDSyncModulesKey = @"HeimdallrSyncModules";
static NSDictionary *syncStartModuleSettings;


@interface Heimdallr()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<HeimdallrModule>> *remoteModules;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<HeimdallrModule>> *manualStartedModules;
@property (nonatomic, copy) NSSet<NSString *> *manualControlModuleSet;
@property (nonatomic, strong) NSMutableArray<id<HeimdallrLocalModule>> *localModules;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeModules;

@property (nonatomic, strong, readwrite) HMDInjectedInfo *userInfo;
@property (atomic, strong, readwrite) HMDHeimdallrConfig *config;

@property (nonatomic, strong) HMDConfigManager *configManager;

@property (nonatomic, strong, readwrite) HMDPerformanceReporter *reporter;
@property (nonatomic, strong, readwrite) HMDRecordStore *store;
@property (nonatomic, strong, readwrite) HMDSessionTracker *sessionTracker;
@property (atomic, assign, readwrite) BOOL enableWorking; //Heimdallr各个功能模块是否允许启动
@property (atomic, assign, readwrite) BOOL isRemoteReady; //Heimdallr远程配置是否成功加载
@property (nonatomic, assign, readwrite) BOOL initializationCompleted; // Heimdallr是否启动完成
@property (nonatomic, assign, readwrite) HMDSafeModeType safeModeType;

@end

@implementation Heimdallr {
    pthread_rwlock_t _remoteModuleLock;
    pthread_rwlock_t _manualStartedModuleLock; // lock for record manual started modules
    pthread_rwlock_t _callbackLock;
    pthread_rwlock_t _manualControlModuleLock; // lock for mark manual control modules
    NSMutableDictionary<NSString *, NSMutableArray<HMDModuleCallbackPair *> *> *_callbackDictionary;
}

static Heimdallr *shared = nil;

static void *heimdallr_queue_key = &heimdallr_queue_key;
static void *heimdallr_queue_context = &heimdallr_queue_context;
static void *clean_queue_key = &clean_queue_key;
static void *clean_queue_context = &clean_queue_context;

dispatch_queue_t hmd_get_heimdallr_queue(void) {
    static dispatch_queue_t heimdallr_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        heimdallr_queue = dispatch_queue_create("com.heimdallr.main", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(heimdallr_queue, heimdallr_queue_key, heimdallr_queue_context, 0);
    });
    return heimdallr_queue;
}

void dispatch_on_heimdallr_queue(bool async, dispatch_block_t block) {
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(heimdallr_queue_key) == heimdallr_queue_context) {
        block();
    } else {
        if (async) {
            hmd_safe_dispatch_async(hmd_get_heimdallr_queue(), block);
        } else {
            dispatch_sync(hmd_get_heimdallr_queue(), block);
        }
    }
}

#ifdef DEBUG
void debug_assert_on_heimdallr_queue(void) {
    DEBUG_ASSERT(dispatch_get_specific(heimdallr_queue_key) == heimdallr_queue_context);
}
#endif

void dispatch_async_on_cleanup_queue(dispatch_block_t block) {
    static dispatch_queue_t clean_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clean_queue = dispatch_queue_create("com.heimdallr.cleanup", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(clean_queue, clean_queue_key, clean_queue_context, 0);
    });
    
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(clean_queue_key) == clean_queue_context) {
        block();
    } else {
        hmd_safe_dispatch_async(clean_queue, block);
    }
}

+ (void)setEnableHermasRefactor:(BOOL)enableHermasRefactor {
    [HMEngine setEnableHermasRefactor:enableHermasRefactor];
}

+ (BOOL)enableHermasRefactor {
    return [HMEngine enableHermasRefactor];
}

+ (void)setRefactorMaxUploadSizeWeight:(NSDictionary *)refactorMaxUploadSizeWeight {
    if ([[HMEngine sharedEngine] respondsToSelector:@selector(updateMaxReportSizeWeights:)]) {
        [[HMEngine sharedEngine] performSelector:@selector(updateMaxReportSizeWeights:) withObject: refactorMaxUploadSizeWeight];
    }
}

+ (NSDictionary *)refactorMaxUploadSizeWeight {
    NSDictionary *weights = nil;
    if ([[HMEngine sharedEngine] respondsToSelector:@selector(getUpdateMaxReportSizeWeights)]) {
        weights = [[HMEngine sharedEngine] performSelector:@selector(getUpdateMaxReportSizeWeights)];
    }
    return weights;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 初始化较早(无论Hermas重构是否开启，hermasManager必须初始化）注释原因：实际上不需要这么早的，只需要在落盘前初始化即可，埋点和trace落盘前会各自触发；
        [HMDHermasManager defaultManager];
        
        //为保证内存获取异步信号安全，提前设置总内存大小
        hmd_setTotalMemoryBytes(NSProcessInfo.processInfo.physicalMemory);
        pthread_rwlock_init(&_remoteModuleLock, NULL);
        pthread_rwlock_init(&_manualStartedModuleLock, NULL);
        pthread_rwlock_init(&_callbackLock, NULL);
        pthread_rwlock_init(&_manualControlModuleLock, NULL);
        _callbackDictionary = [NSMutableDictionary dictionary];
        _remoteModules = [NSMutableDictionary dictionary];
        _localModules = [NSMutableArray array];
        _activeModules = [NSMutableSet set];
        self.configManager = [HMDConfigManager sharedInstance];
        self.store = [HMDRecordStore shared];
        self.sessionTracker = [HMDSessionTracker sharedInstance];
        self.showDebugAlert = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidUpdate:)
                                                     name:HMDConfigManagerDidUpdateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(performanceReportSuccessed:)
                                                     name:HMDPerformanceReportSuccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [super allocWithZone:zone];
    });
    return shared;
}


- (id<HMDStoreIMP>)database
{
    return self.store.database;
}

- (void)setEnablePriorityInversionProtection:(BOOL)enablePriorityInversionProtection {
    _enablePriorityInversionProtection = enablePriorityInversionProtection;
    [[HMDConfigManager sharedInstance] setEnablePriorityInversionProtection:enablePriorityInversionProtection];
}

- (void)setupWithInjectedInfo:(HMDInjectedInfo *)info
{
    NSAssert([NSThread isMainThread], @"Heimdallr must be initialized synchronously on the main thread, otherwise the date from modules such as Crash, WatchDog, HMDStart may be missing or inaccurate.");
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        
        self.userInfo = info;
        [[HMDBackgroundMonitor sharedInstance] updateBackgroundState];
        [self safeModeCheck];
        [[HMDConfigManager sharedInstance] setupAsyncWithDefaultInfo:YES];
        self.enableWorking = YES;
        NSTimeInterval totalStart = 0;
        if (hmd_log_enable()) {
            totalStart = [[NSDate date] timeIntervalSince1970] * 1000;
        }
        
        // 重构后，PerformanceReporter模块将被Hermas替换，所以这里不需要再进行初始化
        if (!hermas_enabled()) {
            self.reporter = [[HMDPerformanceReporter alloc] initWithProvider:info];
            [[HMDPerformanceReporterManager sharedInstance] addReporter:self.reporter withAppID:info.appID];
        }
        
        self.config = [self.configManager remoteConfigWithAppID:info.appID];
        // 无论是否开启重构，都需要进行更新操作
        [[HMDHermasManager defaultManager] updateConfig:self.config];
        
        [self recordDatabaseSizeAndDevastateIfNeeded];
        BOOL hasSetupDefaultMoudle = [self setupUserDefaultModules];
        BOOL needUpdateCurrentConfig = !hasSetupDefaultMoudle || self.config.activeModulesMap.count > 0;
        [self setupSyncModules];
        //为了优化启动时间，异步读取缓存的配置文件
        if (needUpdateCurrentConfig) {
            [self setupConfigAsync];
        }
        //异步启动一些无需开关配置的模块
        [self setupLocalModuesAsync];
        
        if (!hermas_enabled()) {
            //延时上报性能和异常数据
            [self reportCachedDataDelayAsync];
        }
        
        if (hermas_enabled()) {
            [[HMEngine sharedEngine] updateHeimdallrInitCompleted:YES];
        }
        
        if (hmd_log_enable()) {
            NSTimeInterval totalEnd = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *duration = [NSString stringWithFormat:@"Heimdallr total load time:%f ms", totalEnd - totalStart];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@", duration);
        }
        dispatch_on_heimdallr_queue(true, ^{
            self.initializationCompleted = YES;
        });
    }
#ifdef DEBUG
    else NSAssert(NO, @"[NO!] - [Heimdallr setupWithInjectInfo:] can be invoked only once. \n"
                     " Heimdallr had used KVO [HMDInjectInfo defaultInfo] \n"
                     " Multiple calls will cause online CRASH.\n");
#endif
}

+ (void)setupAllSDKMonitors {
    [[HMDConfigManager sharedInstance] setupAsyncWithDefaultInfo:NO];
}

- (void)setupSyncModules
{
    __block NSMutableArray *configs = nil;
    NSDictionary *syncModules = [[self class] syncStartModuleSettings];
    [syncModules enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        Class clazz = NSClassFromString(key);
        if (clazz) {
            HMDModuleConfig *config = [[clazz alloc] initWithDictionary:obj];
            if (config && !configs) {
                configs = [NSMutableArray array];
            }
            [configs hmd_addObject:config];
        }
    }];
    if (configs.count==0) {
        return;
    }
    
#if !SIMPLIFYEXTENSION
    [configs sortUsingComparator:^NSComparisonResult(HMDModuleConfig *  _Nonnull obj1, HMDModuleConfig * _Nonnull obj2) {
        return [obj1 compareStartWeight:obj2];
    }];
#endif
    
    [configs hmd_enumerateObjectsUsingBlock:^(HMDModuleConfig *  _Nonnull config, NSUInteger idx, BOOL * _Nonnull stop) {
        id<HeimdallrModule> module = [self moduleWithConfig:config];
        [self setupModule:module];
    } class:[HMDModuleConfig class]];
}

/// 启动用户设置的默认启动的模块
- (BOOL)setupUserDefaultModules
{
    if (!self.configManager.configFromDefaultDictionary) return NO;
    if (!self.userInfo.defaultSetupModules || self.userInfo.defaultSetupModules.count == 0) return NO;
    NSArray *moduleNames = self.userInfo.defaultSetupModules;
    NSMutableArray<id<HeimdallrModule>> *syncStartModuels = [NSMutableArray array];
    NSMutableArray<id<HeimdallrModule>> *asyncStartModules = [NSMutableArray array];

    NSArray *avaliableModules = [HMDModuleConfig allRemoteModuleClasses];
    [moduleNames enumerateObjectsUsingBlock:^(id  _Nonnull moduleName, NSUInteger idx, BOOL * _Nonnull stop) {
        if(moduleName) {
            for (Class clazz in avaliableModules) {
                if ([[(id)clazz configKey] isEqualToString:moduleName]) {
                    HMDModuleConfig *config = [(HMDModuleConfig *)[clazz alloc] initWithDictionary:nil];
                    id<HeimdallrModule> module = [self moduleWithConfig:config];
                    //module不存在则跳过
                    if(!module) {
                        continue;
                    }
                    //做一些默认启动项额外的准备工作，如全量api_all的采样率
                    if([module respondsToSelector:@selector(prepareForDefaultStart)]) {
                        [module prepareForDefaultStart];
                    }
                    // 区分默认启动的模块是同步启动模块还是异步启动模块
                    if ([module respondsToSelector:@selector(needSyncStart)] && [module needSyncStart]) {
                        [syncStartModuels addObject:module];
                    } else {
                        [asyncStartModules addObject:module];
                    }
                }
            }
        }
    }];

    [self setupHMDModulesWithArray:syncStartModuels async:NO];
    [self setupHMDModulesWithArray:asyncStartModules async:YES];
    return YES;
}

- (void)setupHMDModulesWithArray:(NSArray<id<HeimdallrModule>> *)syncModules async:(BOOL)async {
    dispatch_on_heimdallr_queue(async, ^{
        for (HeimdallrModule *module in syncModules) {
            [self setupModule:module];
        }
    });
}

- (id<HeimdallrModule>)moduleWithConfig:(HMDModuleConfig *)config
{
    id<HeimdallrModule> module = [config getModule];
    if ([module respondsToSelector:@selector(updateConfig:)] && module.config != config) {
        [module updateConfig:config];
    }
    return module;
}

- (id<HeimdallrModule>)moduleWithName:(NSString*)name {
    id<HeimdallrModule> module = [[self.config.allModulesMap objectForKey:name] getModule];
    return module;
}

- (void)setupConfigAsync
{
    dispatch_on_heimdallr_queue(YES, ^{
        [self updateConfig:[self.configManager remoteConfigWithAppID:self.userInfo.appID]];
    });
}

- (void)updateConfig:(HMDHeimdallrConfig *)config
{
    //HMDTTMonitor模块可能触发Heimdallr配置更新进而开启各个功能模块，这里加一个判断，如果Heimdallr主入口没开启则忽略
    if(!self.enableWorking) return;
    pthread_rwlock_t *remoteModuleLock = &_remoteModuleLock;
    dispatch_on_heimdallr_queue(YES, ^{
        
        self.config = config;
        
        [self updateTTMonitorExchangeSwitchIfNeeded];
        [self updateNetQualityTrackerStatus];
        
        [self.configManager setUpdateInterval:(NSTimeInterval)config.apiSettings.fetchAPISetting.fetchInterval withAppID:self.userInfo.appID];

        if (hermas_enabled()) {
            [[HMDHermasManager defaultManager] updateConfig:config];
        } else {
            [[HMDPerformanceReporterManager sharedInstance] updateConfig:config withAppID:self.userInfo.appID];
            [[HMDExceptionReporter sharedInstance] updateConfig:config];
        }
    
        DC_OB(DC_CL(HMDCloudCommandManager, sharedInstance), updateConfig:, config.cloudCommandConfig);
        [[HMDCustomReportManager defaultManager] updateConfig:config];
        
        NSDictionary *latestActiveModulesMap = config.activeModulesMap;
        NSArray *moduleConfigs = latestActiveModulesMap.allValues;
        NSMutableArray *modules = [NSMutableArray array];
        NSMutableDictionary *category = [NSMutableDictionary dictionary];
        for (HMDModuleConfig *moduleConfig in moduleConfigs) {
            id<HeimdallrModule> module = [self moduleWithConfig:moduleConfig];
            if (module) {
                [modules addObject:module];
                if(![self.activeModules containsObject:module.moduleName]) {
                    [category hmd_setObject:self.userInfo.appID forKey:module.moduleName];
                    [self.activeModules addObject:module.moduleName];
                }
            }
        }
        
        if(!HMDIsEmptyDictionary(category)) {
            [HMDMonitorService trackService:@"slardar_module_setup" metrics:nil dimension:category extra:nil syncWrite:YES];
        }
        
        NSMutableArray *stopedModules = [NSMutableArray array];
        NSArray<id<HeimdallrModule>> *remoteArray;
        pthread_rwlock_rdlock(remoteModuleLock);
        remoteArray = self.remoteModules.allValues;
        pthread_rwlock_unlock(remoteModuleLock);
        
        for (id<HeimdallrModule> module in remoteArray) {
            if(![latestActiveModulesMap objectForKey:[module moduleName]]) {
                [stopedModules addObject:module];
            }
        }
        
        for (id<HeimdallrModule> module in stopedModules) {
            NSString *configKey = [module.config.class configKey];
            if (![self needManualControl:configKey]) {
                [self stopModule:module manually:NO];
            }
            if ([module respondsToSelector:@selector(needSyncStart)] && [module needSyncStart]) {
                [self unregisterSyncStartModule:module];
            }
        }
        
#if !SIMPLIFYEXTENSION
        [modules sortUsingComparator:^NSComparisonResult(id<HeimdallrModule> obj1, id<HeimdallrModule> obj2) {
            HMDModuleConfig *config1 = obj1.config;
            HMDModuleConfig *config2 = obj2.config;
            return [config1 compareStartWeight:config2];
        }];
#endif
        
        for (id<HeimdallrModule> module in modules) {
            NSString *configKey = [module.config.class configKey];
            if (![self needManualControl:configKey]) {
                [self setupModule:module];
            }
            if ([module respondsToSelector:@selector(needSyncStart)]) {
                if ([module needSyncStart]) {
                    [self registerSyncStartModule:module];
                }
                else {
                    [self unregisterSyncStartModule:module];
                }

            }
        }
        
        NSDictionary *allModulesMap = config.allModulesMap;
        NSArray *allModuleConfigs = allModulesMap.allValues;
        for (HMDModuleConfig *moduleConfig in allModuleConfigs) {
            if ([moduleConfig canStartTaskIndependentOfStart]) {
                id<HeimdallrModule> module = [self moduleWithConfig:moduleConfig];
                if (module) {
                    [self setupModuleIndependentOfStart:module];
                }
            }
        }
        
        self.isRemoteReady = !self.configManager.configFromDefaultDictionary;
    });
}

- (void)stopModule:(id<HeimdallrModule>)module manually:(BOOL)isManually
{
    if (module && module.isRunning) {
        [module stop];
        
        if (!hermas_enabled()) {
            if ([module respondsToSelector:@selector(performanceDataSource)] && [module performanceDataSource]) {
                [[HMDPerformanceReporterManager sharedInstance] removeReportModule:(id)module withAppID:self.userInfo.appID];
            }
            if ([module respondsToSelector:@selector(exceptionDataSource)] && [module exceptionDataSource]) {
                [[HMDExceptionReporter sharedInstance] removeReportModule:(id)module];
            }
        }
        if (!isManually) {
            pthread_rwlock_wrlock(&_remoteModuleLock);
            NSString *stopModuleName = [module moduleName];
            if (stopModuleName) {
                [self.remoteModules removeObjectForKey:stopModuleName];
            }
            pthread_rwlock_unlock(&_remoteModuleLock);
        }
        [self module:module name:[module moduleName] didChangeState:NO];
    }
}

- (void)startModule:(id<HeimdallrModule>)module manually:(BOOL)isManually {
    NSTimeInterval moduleStart = 0;
    if (hmd_log_enable()) {
        moduleStart = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    
    if([module respondsToSelector:@selector(setupWithHeimdallr:)]) {
        [module setupWithHeimdallr:self];
    }
    
    if ([module respondsToSelector:@selector(performanceDataSource)] && [module performanceDataSource]) {
        [[HMDPerformanceReporterManager sharedInstance] addReportModule:(id)module withAppID:self.userInfo.appID];
    }
    
    if ([module respondsToSelector:@selector(exceptionDataSource)] && [module exceptionDataSource]) {
        [[HMDExceptionReporter sharedInstance] addReportModule:(id)module];
    }
    
    BOOL shouldStartAsDefaultModule = [self.userInfo.defaultSetupModules containsObject:[[module.config class] configKey]] && self.configManager.configFromDefaultDictionary;
    if (!module.isRunning && ([module.config canStart] || shouldStartAsDefaultModule || isManually)) {
        [module start];
        [self module:module name:[module moduleName] didChangeState:YES];
    }
    
    if (hmd_log_enable()) {
        NSTimeInterval moduleEnd = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *duration = [NSString stringWithFormat:@"Heimdallr module %@ load time:%f ms",NSStringFromClass([module class]), moduleEnd - moduleStart];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@", duration);
    }
}

- (void)setupModule:(id<HeimdallrModule>)module
{
    pthread_rwlock_rdlock(&_remoteModuleLock);
    BOOL hasModule = [self.remoteModules objectForKey:[module moduleName]] != nil;
    pthread_rwlock_unlock(&_remoteModuleLock);
    if (!hasModule) {
        [self startModule:module manually:NO];
        pthread_rwlock_wrlock(&_remoteModuleLock);
        [self.remoteModules setValue:module forKey:[module moduleName]];
        pthread_rwlock_unlock(&_remoteModuleLock);
    }
}

- (void)setupModuleIndependentOfStart:(id<HeimdallrModule>)module {
    if (!module.hasExecutedTaskIndependentOfStart) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [module runTaskIndependentOfStart];
        });
    }
}

- (void)setupLocalModuesAsync {
    dispatch_on_heimdallr_queue(YES, ^{
        NSArray<HeimdallrLocalModule> *classes = [HMDModuleConfig allLocalModuleClasses];
        for (id<HeimdallrLocalModule> clazz in classes) {
            if ([clazz conformsToProtocol:@protocol(HeimdallrLocalModule)] && [clazz respondsToSelector:@selector(getInstance)]) {
                id<HeimdallrLocalModule> instance = [clazz getInstance];
                if (instance && [instance respondsToSelector:@selector(start)]) {
                    [instance start];
                    if (![self.localModules containsObject:instance]) {
                        [self.localModules addObject:instance];
                    }
                }
            }
        }
    });
}

- (void)reportCachedDataDelayAsync {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HMDStartUploadDelayTime * NSEC_PER_SEC)), hmd_get_heimdallr_queue(), ^{
        [[HMDPerformanceReporterManager sharedInstance] reportPerformanceDataAfterInitializeWithAppID:self.userInfo.appID block:NULL];
        [[HMDExceptionReporter sharedInstance] reportAllExceptionData];
    });
}

- (void)registerSyncStartModule:(id<HeimdallrModule>)module
{
    HMDModuleConfig *config = [module config];
    NSDictionary *data = [config hmd_dataDictionary];
    if (data) {
        NSDictionary *settings = [[self class] syncStartModuleSettings];
        NSMutableDictionary *newSettings = [NSMutableDictionary dictionaryWithDictionary:settings];
        [newSettings setObject:data forKey:NSStringFromClass([config class])];
        [[HMDUserDefaults standardUserDefaults] setObject:newSettings forKey:kHMDSyncModulesKey];
    }
}

- (void)unregisterSyncStartModule:(id<HeimdallrModule>)module
{
    HMDModuleConfig *config = [module config];
    NSDictionary *settings = [[self class] syncStartModuleSettings];
    if ([settings objectForKey:NSStringFromClass([config class])]) {
        NSMutableDictionary *newSettings = [NSMutableDictionary dictionaryWithDictionary:settings];
        [newSettings removeObjectForKey:NSStringFromClass([config class])];
        [[HMDUserDefaults standardUserDefaults] setObject:newSettings forKey:kHMDSyncModulesKey];
    }
}

+ (NSDictionary *)syncStartModuleSettings{
    return [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDSyncModulesKey];
}

- (void)updateTTMonitorExchangeSwitchIfNeeded {
    NSNumber *needHook = [NSNumber numberWithBool:self.config.needHookTTMonitor];
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hookTTMonitorInterfaceIfNeeded:needHook];
}

- (void)updateNetQualityTrackerStatus {
    BOOL enableNetQualityMonitor = self.config.enableNetQualityReport;
    dispatch_on_heimdallr_queue(YES, ^{
        DC_OB(DC_CL(HMDNetQualityTracker, sharedTracker), switchNetQualityTrackerStatus:, enableNetQualityMonitor);
    });
}

- (BOOL)isModuleWorkingForName:(NSString *)moduleName {
    pthread_rwlock_rdlock(&_remoteModuleLock);
    BOOL working = [self.remoteModules objectForKey:moduleName] != nil;
    pthread_rwlock_unlock(&_remoteModuleLock);
    
    if (!working) {
        pthread_rwlock_rdlock(&_manualStartedModuleLock);
        BOOL manualModuleWorking = [self.manualStartedModules objectForKey:moduleName] != nil;
        pthread_rwlock_unlock(&_manualStartedModuleLock);
        return manualModuleWorking;
    }
    return working;
}

- (NSString *)sessionID {
    return [HMDSessionTracker currentSession].sessionID;
}

// for external cleanup in Heimdallr+ExternalClean.h
- (void)cleanupWithCleanConfig:(HMDCleanupConfig*)cleanupConfig {
    NSArray<id<HeimdallrModule>> *cleanModules = [self copyAllRemoteModules];
    for (id<HeimdallrModule> module in cleanModules) {
        [module cleanupWithConfig:cleanupConfig];
    }
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
    [[HMDSessionTracker sharedInstance] cleanupWithAndConditions:cleanupConfig.andConditions];
CLANG_DIAGNOSTIC_POP
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
 cleanup
{
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:@"com.heimdallr.backgroundTask.cleanup"
                                                     task:^(void (^ _Nonnull completeHandle)(void)) {
        dispatch_async_on_cleanup_queue(^{
            [self cleanupWithCleanConfig:self.config.cleanupConfig];
//            [self.database vacuumIfNeeded];
            if(completeHandle) completeHandle();
#ifdef DEBUG
            else
            NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                         " and contact Heimdallr developer ASAP");
#endif
        });
    }];
}

- (void)devastateDatabase {
    [self.store devastateDatabase];
}

- (void)recordDatabaseSizeAndDevastateIfNeeded
{
    if (hmd_log_enable()) {
        long long fileSize = [self.store dbFileSize];
        NSString *fileSizeLog = [NSString stringWithFormat:@"APM DB size:%lldbyte",fileSize];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"%@",fileSizeLog);
        NSUInteger devastateThreshold = self.config.cleanupConfig.devastateDBSize;
        NSUInteger expectedSize = self.config.cleanupConfig.expectedDBSize;
        //db文件删除阈值不低于50MB
        if (devastateThreshold >= 50 && devastateThreshold > expectedSize && fileSize > devastateThreshold * HMD_MB) {
            [self.store devastateDatabase];
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Heimdallr devastate because database too large, threshold:%lu MB", (unsigned long)devastateThreshold);
        }
    }
}

#pragma mark - Notification
- (void)configDidUpdate:(NSNotification *)notification
{
    [self safeModeCleanDueToTimeout:NO];
    
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && [appIDs containsObject:self.userInfo.appID]) {
            if (updatedConfigManager == self.configManager) {
                [self updateConfig:[self.configManager remoteConfigWithAppID:self.userInfo.appID]];
            }
        }
    }
}

- (void)performanceReportSuccessed:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSArray.class]) {
        NSArray *reporterArray = (NSArray *)notification.object;
        if ([reporterArray containsObject:self.reporter]) {
            [self.configManager asyncFetchRemoteConfig:NO];
        }
    }
}

- (void)didEnterBackground:(NSNotification *)notification {
    if (hermas_enabled()) {
        
    } else {
        [self cleanup];
    }
}

- (void)handleBecomeActiveNotification:(NSNotification *)notification {
    if (hermas_enabled()) {
        
    } else {
        dispatch_on_heimdallr_queue(YES, ^{
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
            [[self class] uploadDebugRealDataWithLocalConfig];
CLANG_DIAGNOSTIC_POP
        });
    }

}

- (void)updateRecordCount:(NSInteger)count
{
    [[HMDPerformanceReporterManager sharedInstance] updateRecordCount:count withAppID:self.userInfo.appID];
}

#pragma mark - Registed Callback

- (id<NSObject>)addObserverForModule:(NSString *)moduleName usingBlock:(HMDModuleCallback)callback {
    NSAssert(moduleName != nil && callback != nil,
             @"- [Heimdallr addObserverForModule:usingBlock:] nil moduleName or block");
    if(moduleName != nil && callback != nil) {
        pthread_rwlock_wrlock(&_callbackLock);
        NSMutableArray *currentArray = [_callbackDictionary objectForKey:moduleName];
        if(currentArray == nil)
            [_callbackDictionary setObject:(currentArray = [NSMutableArray array]) forKey:moduleName];
        HMDModuleCallbackPair *pair = [[HMDModuleCallbackPair alloc] initWithModuleName:moduleName callback:callback];
        if([currentArray containsObject:pair]) {
            NSAssert(NO, @"- [Heimdallr addObserverForModule:usingBlock:] add callback twice");
            pthread_rwlock_unlock(&_callbackLock);
            return nil;
        }
        [currentArray addObject:pair];
        pthread_rwlock_unlock(&_callbackLock);
        
        pthread_rwlock_rdlock(&_remoteModuleLock);
        id<HeimdallrModule>module = [self.remoteModules objectForKey:moduleName];
        pthread_rwlock_unlock(&_remoteModuleLock);
        [pair invokeCallbackWithModule:module isWorking:module != nil];
        return pair;
    }
    return nil;
}

- (void)removeObserver:(id<NSObject>)blockIdentifier {
    NSAssert(blockIdentifier != nil && [blockIdentifier isKindOfClass:HMDModuleCallbackPair.class],
             @"- [Heimdallr removeObserver:] nil blockIdentifier");
    if(blockIdentifier != nil  && [blockIdentifier isKindOfClass:HMDModuleCallbackPair.class]) {
        pthread_rwlock_wrlock(&_callbackLock);
        NSMutableArray *currentArray;
        if((currentArray = [_callbackDictionary objectForKey:((HMDModuleCallbackPair *)blockIdentifier).moduleName]) != nil &&
           [currentArray containsObject:blockIdentifier]) {
            [currentArray removeObject:blockIdentifier];
        }
        pthread_rwlock_unlock(&_callbackLock);
    }
}

- (void)module:(id<HeimdallrModule>)module name:(NSString *)moduleName didChangeState:(BOOL)isWorking {
    NSAssert(moduleName != nil, @"- [Heimdallr module:didChangeState:] ");
    NSMutableArray *currentArray;
    pthread_rwlock_rdlock(&_callbackLock);
    if((currentArray = [_callbackDictionary objectForKey:moduleName]) != nil) {
        NSArray<HMDModuleCallbackPair *> *list = [currentArray copy];
        pthread_rwlock_unlock(&_callbackLock);
        for(HMDModuleCallbackPair *eachPair in list) {
            [eachPair invokeCallbackWithModule:module isWorking:isWorking];
        }
    }
    else pthread_rwlock_unlock(&_callbackLock);
}

// Used Internally
- (NSArray<id<HeimdallrModule>> *)copyAllRemoteModules {
    pthread_rwlock_rdlock(&_remoteModuleLock);
    NSSet<id<HeimdallrModule>> *copied = [NSSet setWithArray:[_remoteModules allValues]];
    pthread_rwlock_unlock(&_remoteModuleLock);
    // add manual started modules
    pthread_rwlock_rdlock(&_manualStartedModuleLock);
    NSArray<id<HeimdallrModule>> *manualStartedModules = [self.manualStartedModules allValues];
    pthread_rwlock_unlock(&_manualStartedModuleLock);
    if (manualStartedModules.count > 0) {
        copied = [copied setByAddingObjectsFromArray:manualStartedModules];
    }
    return copied.allObjects;
}

#pragma mark - manual control
- (void)markAsManualControl:(NSArray <NSString*>*)moduleNames {
    if(moduleNames.count > 0 ) {
        pthread_rwlock_wrlock(&_manualControlModuleLock);
        if (_manualControlModuleSet == nil) {
            _manualControlModuleSet = [NSSet setWithArray:moduleNames];
        }else {
            _manualControlModuleSet = [_manualControlModuleSet setByAddingObjectsFromArray:moduleNames];
        }
        pthread_rwlock_unlock(&_manualControlModuleLock);
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"mark module %@ as manual control", moduleNames);
    }
}

- (void)manualStart:(NSString *)moduleName {
    if (![self needManualControl:moduleName]) {
        DEBUG_ERROR("module %s is not marked as manual control", moduleName.UTF8String);
        return;
    }
    dispatch_on_heimdallr_queue(YES, ^{
        id<HeimdallrModule> module = [self moduleWithConfig:[self.config.allModulesMap objectForKey:moduleName]];
        if (module == nil) return;
        if ([module respondsToSelector:@selector(needSyncStart)] && [module needSyncStart]) {
            DEBUG_ERROR("Sync start module %s cann't be started manually", moduleName.UTF8String);
        }else {
            [self startModule:module manually:YES];
            pthread_rwlock_wrlock(&self->_manualStartedModuleLock);
            [self.manualStartedModules hmd_setObject:module forKey:moduleName];
            pthread_rwlock_unlock(&self->_manualStartedModuleLock);
            
            pthread_rwlock_wrlock(&self->_remoteModuleLock);
            [self.remoteModules removeObjectForKey:moduleName];
            pthread_rwlock_unlock(&self->_remoteModuleLock);
            
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"module %@ start manually", moduleName);
        }
    });
}

- (void)manualStop:(NSString*)moduleName {
    if (![self needManualControl:moduleName]) {
        DEBUG_ERROR("module %s is not marked as manual control", moduleName.UTF8String);
        return;
    }
    dispatch_on_heimdallr_queue(YES, ^{
        id<HeimdallrModule> module = [self moduleWithConfig:[self.config.allModulesMap objectForKey:moduleName]];
        if (module == nil) {
            DEBUG_ERROR("Manual stop befor HMDSDK init, check invoke timing");
        }else {
            [self stopModule:module manually:YES];
            pthread_rwlock_wrlock(&self->_manualStartedModuleLock);
            [self.manualStartedModules removeObjectForKey:moduleName];
            pthread_rwlock_unlock(&self->_manualStartedModuleLock);
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"module %@ stop manually", moduleName);
        }
    });
}

- (BOOL)needManualControl:(NSString *)moduleName {
    pthread_rwlock_rdlock(&_manualControlModuleLock);
    if (_manualControlModuleSet == nil) {
        pthread_rwlock_unlock(&_manualControlModuleLock);
        return NO;
    }
    BOOL res = [_manualControlModuleSet containsObject:moduleName];
    pthread_rwlock_unlock(&_manualControlModuleLock);
    return res;
}

#pragma mark - lazy load
- (NSMutableDictionary<NSString *,id<HeimdallrModule>> *)manualStartedModules {
    if (!_manualStartedModules) {
        _manualStartedModules = [NSMutableDictionary dictionary];
    }
    return _manualStartedModules;
}
@end

