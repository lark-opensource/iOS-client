//
//  HMEngine.m
//  Hermas
//
//  Created by 崔晓兵 on 19/1/2022.
//

#import "HMEngine.h"
#import <libkern/OSAtomic.h>
#import "HMInstance.h"
#import "HMConfig.h"
#import "HMUploader.h"
#import "HMTools.h"
#import "UserDefault_iOS.h"

#include "hermas.hpp"
#include "env.h"
#include "weak_handler.h"
#include "upload_service.h"
#include "cache_service.h"
#include "session_service.h"
#include "migrate_service.h"
#include "user_default.h"
#include <map>

#define SAFE_UTF8_STRING(x) (x != nil ?  x.UTF8String : "")

static NSString *plistSuiteName = nil;

BOOL hermas_enabled() {
    return [HMEngine isEnabled];
}

BOOL hermas_drop_data(NSString * _Nonnull moduleId) {
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:[HMEngine sharedEngine].globalConfig.hostAid];
    return [instance isDropData];
}

BOOL hermas_is_server_available(NSString * _Nonnull moduleId) {
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:[HMEngine sharedEngine].globalConfig.hostAid];
    return [instance isServerAvailable];
}

BOOL hermas_drop_data_sdk(NSString *_Nonnull moduleId, NSString* _Nullable aid) {
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:aid];
    return [instance isDropData];
}

BOOL hermas_is_server_available_sdk(NSString *_Nonnull moduleId,   NSString* _Nullable aid) {
    HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:aid];
    return [instance isServerAvailable];
}

void hermas_set_plist_suite_name_only_once(NSString *_Nonnull suiteName) {
    if (nil == suiteName || 0 == suiteName.length) {
        logw("HMEngine", "hermas set an illegal suite name. suite name = %s.", SAFE_UTF8_STRING(suiteName));
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        plistSuiteName = [suiteName copy];
    });
    
    if (![plistSuiteName isEqualToString:suiteName]) {
        logw("HMEngine", "hermas suite name just set only once. current suite name = %s, new suite name = %s.", SAFE_UTF8_STRING(plistSuiteName), SAFE_UTF8_STRING(suiteName));
    }
}

NSString * hermas_plist_suite_name() {
    if (nil != plistSuiteName && 0 != plistSuiteName.length) {
        return plistSuiteName;
    }
    
    logi("HMEngine", "hermas use default suite name.");
    
    return @"hermas";
}

using namespace hermas;

static void *queue_key = &queue_key;
static void *queue_context = &queue_context;
char const * kEnableHermasRefactorFromSDK = "enable_hermas_refactor_from_sdk";
char const * kEnableHermasRefactorFromApp = "enable_hermas_refactor_from_app";

dispatch_queue_t hermas_queue(void) {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("hermas.execute.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(queue, queue_key, queue_context, 0);
    });
    return queue;
}

void dispatch_on_hermas_queue(dispatch_block_t block) {
    if (!block) return;
    if (dispatch_get_specific(queue_key) == queue_context) {
        @autoreleasepool {
            block();
        }
    } else {
        dispatch_async(hermas_queue(), ^{
            @autoreleasepool {
                block();
            }
        });
    }
}

static BOOL globalEnabled = NO;


@interface HMInstance ()
- (instancetype)initWithConfig:(HMInstanceConfig *)config;
@end

@interface HMEngine ()
@property (nonatomic, strong) NSMutableDictionary *moduleStateDic;
@property (nonatomic, strong) NSMutableDictionary *container;
@property (nonatomic, assign) HMFlowControlStrategy flowControlStrategy;
@property (nonatomic, strong) NSDictionary<NSString *, id<HMModuleConfig>> *config;
@property (nonatomic, strong) dispatch_queue_t searchQueue;
@property (nonatomic, strong) NSMutableDictionary *pendingCloudCommand;
@property (nonatomic, strong) NSDictionary *maxUploadSizeWeights;
@end

@implementation HMEngine {
    pthread_rwlock_t _moduleStateDicLock;
    pthread_rwlock_t _containerLock;
}



+ (void)initialize {
    if (self == [HMEngine class]) {
        UserDefault::RegisterInstance(std::make_unique<hermas::UserDefault_iOS>());
        BOOL enableRefactor = [self enableHermasRefactor];
        [HMEngine setEnabled:enableRefactor];
    }
}

+ (void)setEnableHermasRefactor:(BOOL)enableHermasRefactor {
    dispatch_on_hermas_queue(^{
        UserDefault::Write(kEnableHermasRefactorFromApp, enableHermasRefactor ? "true" : "false");
    });
}

+ (void)setEnableHermasRefactorFromSDK:(BOOL)enableHermasRefactor {
    UserDefault::Write(kEnableHermasRefactorFromSDK, enableHermasRefactor ? "true" : "false");
}


+ (BOOL)enableHermasRefactor {
    static bool enableRefactor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 优先使用业务侧的settings，如果业务侧没有设置settings，则使用SDK的settings
        std::string enableRefactorNumber = UserDefault::Read(kEnableHermasRefactorFromApp);
        if (enableRefactorNumber.length() == 0) {
            enableRefactorNumber = UserDefault::Read(kEnableHermasRefactorFromSDK);
        }
        enableRefactor = enableRefactorNumber == "true" ? YES : NO;
    });
    return enableRefactor;
}


+ (void)setEnabled:(BOOL)enabled {
    globalEnabled = enabled;
}

+ (BOOL)isEnabled {
    return globalEnabled;
}

+ (instancetype)sharedEngine {
    static HMEngine *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[HMEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupContainer];
        _searchQueue = dispatch_queue_create("hermas.search.queue", DISPATCH_QUEUE_SERIAL);
        _pendingCloudCommand = [NSMutableDictionary dictionary];
        
    }
    return self;
}


- (void)setupContainer {
    pthread_rwlock_init(&_containerLock, NULL);
    _container = [[NSMutableDictionary alloc] init];
    
    pthread_rwlock_init(&_moduleStateDicLock, NULL);
    _moduleStateDic = [[NSMutableDictionary alloc] init];
}

- (void)registerNetworkManager:(id<HMNetworkProtocol>)networkManager {
    if (!networkManager) return;
    HMUploader::RegisterCustomNetworkManager(networkManager);
}

- (void)setIsDebug:(BOOL)isDebug {
    hermas::SetDebug(isDebug ? true : false);
}

- (void)setupGlobalConfig:(HMGlobalConfig *)config {
    NSAssert(config != nil, @"config can't be nil");
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "set up global config: host aid = %s, root dir = %s, need encrypt = %s", SAFE_UTF8_STRING(config.hostAid), SAFE_UTF8_STRING(config.rootDir), (config.encryptBlock ? "true" : "false"));
        self.globalConfig = config;
        hermas::GlobalEnv& globalEnv = GlobalEnv::GetInstance();
        globalEnv.SetHeimdallrAid(SAFE_UTF8_STRING(self.globalConfig.heimdallrAid));
        globalEnv.SetHostAid(SAFE_UTF8_STRING(self.globalConfig.hostAid));
        globalEnv.SetRootPathName(hermas::FilePath(SAFE_UTF8_STRING(self.globalConfig.rootDir)));
        globalEnv.SetQueryParams(queryStringWithConfig(config));
        globalEnv.SetReportHeaderLowLevelParams(SAFE_UTF8_STRING(hermas::stringWithDictionary(config.reportHeaderLowLevelParams)));
        globalEnv.SetReportHeaderConstantParams(SAFE_UTF8_STRING(hermas::stringWithDictionary(config.reportHeaderConstantParams)));
        globalEnv.SetZstdDictPath(SAFE_UTF8_STRING(config.zstdDictPath));
        globalEnv.SetMaxFileSize((int)config.maxFileSize);
        globalEnv.SetMaxLogNumber((int)config.maxLogNumber);
        globalEnv.SetMaxReportSize((int)config.maxReportSize);
        globalEnv.SetMaxReportSizeLimited((int)config.limitReportSize);
        globalEnv.SetReportInterval((int)config.reportInterval);
        globalEnv.SetReportIntervalLimited((int)config.limitReportInterval);
        globalEnv.SetCleanupInterval((int)config.reportInterval * 5);
        globalEnv.SetQuotaPath(SAFE_UTF8_STRING(config.quotaDictPath));
        globalEnv.SetDevicePerformance(SAFE_UTF8_STRING(config.devicePerformance));
        
        __weak __typeof(self) wself = self;
        // query params block
        if (config.reportCommonParamsBlock) {
            globalEnv.SetQueryParamsBlock([wself]() -> std::string {
                return (queryStringWithConfig(wself.globalConfig));
            });
        }
        
        // encrypt block
        if (config.encryptBlock) {
            globalEnv.SetEncryptHandler([wself](const std::string& originData) -> std::string {
                @autoreleasepool {
                    NSData *data = [NSData dataWithBytes:originData.c_str() length:originData.length()];
                    NSData *encryptData = wself.globalConfig.encryptBlock(data);
                    char *bytes = (char *)encryptData.bytes;
                    return std::string(bytes, encryptData.length);
                }
            });
        }
        
        // memory block
        if (config.memoryBlock) {
            globalEnv.SetMemoryHandler([wself]() -> int64_t {
                @autoreleasepool {
                    return wself.globalConfig.memoryBlock();
                }
            });
        }
        
        if (config.memoryLimitBlock) {
            globalEnv.SetMemoryLimitHandler([wself]() -> int64_t {
                @autoreleasepool {
                    return wself.globalConfig.memoryLimitBlock();
                }
            });
        }
        
        if (config.virtualMemoryBlock) {
            globalEnv.SetVirtualMemoryHandler([wself]() -> int64_t {
                @autoreleasepool {
                    return wself.globalConfig.virtualMemoryBlock();
                }
            });
        }
        
        if (config.totalVirtualMemoryBlock) {
            globalEnv.SetTotalVirtualMemoryHandler([wself]() -> int64_t {
                @autoreleasepool {
                    return wself.globalConfig.totalVirtualMemoryBlock();
                }
            });
        }
        
        if (config.sequenceCodeGenerator) {
            globalEnv.SetSequenceCodeGenerator([wself](const std::string& className) -> int64_t {
                @autoreleasepool {
                    NSString *str = [NSString stringWithCString:className.c_str() encoding:NSUTF8StringEncoding];
                    return wself.globalConfig.sequenceCodeGenerator(str);
                }
            });
        }
        
        if (config.deviceIdRequestBlock) {
            globalEnv.SetDeviceIdRequestHandler([wself]() -> std::string {
                @autoreleasepool {
                    NSString *ret = wself.globalConfig.deviceIdRequestBlock() ?: @"";
                    return std::string(ret.UTF8String);
                }
            });
        }
        
        if (config.useURLSessionUploadBlock) {
            globalEnv.SetUseURLSessionUploadBlock([wself]() -> BOOL {
                @autoreleasepool {
                    BOOL ret = wself.globalConfig.useURLSessionUploadBlock();
                    return ret;
                }
                
            });
        }
        
        if (config.stopWriteToDiskWhenUnhitBlock) {
            globalEnv.SetStopWriteToDiskWhenUnhitBlock([wself]() -> BOOL {
                @autoreleasepool {
                    BOOL ret = wself.globalConfig.stopWriteToDiskWhenUnhitBlock();
                    return ret;
                }
            });
        }
    });
}

- (void)addModuleWithConfig:(HMModuleConfig *)moduleConfig {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "build module env, name = %s, max store size = %d", SAFE_UTF8_STRING(moduleConfig.name) , moduleConfig.maxStoreSize);
        std::shared_ptr<ModuleEnv> module_env = std::make_shared<ModuleEnv>();
        module_env->SetPath(SAFE_UTF8_STRING(moduleConfig.path));
        module_env->SetModuleId(SAFE_UTF8_STRING(moduleConfig.name));
        module_env->SetMaxStoreSize((int)moduleConfig.maxStoreSize);
        module_env->SetMaxLocalStoreSize((int)moduleConfig.maxLocalStoreSize);
        module_env->SetUploader(std::make_unique<hermas::HMUploader>());
        module_env->SetZstdDictType("monitor");
        module_env->SetForwardEnabled(moduleConfig.forwardEnabled ? true : false);
        module_env->SetForwardUrl(std::string(SAFE_UTF8_STRING(moduleConfig.forwardUrl) ?: ""));
        module_env->SetForbidSplitReportFile(moduleConfig.isForbidSplitReportFile ? true : false);
        module_env->SetAggreFileSize((int)moduleConfig.aggregateParam.fileSize);
        module_env->SetAggreFileConfig(convertNSDictionayToIntTypeMap(moduleConfig.aggregateParam.fileConfig));
        module_env->SetAggreIntoMax(mapWithNSDictionary(moduleConfig.aggregateParam.aggreIntoMax));
        module_env->SetEnableRawUpload(moduleConfig.enableRawUpload ? true : false);
        module_env->SetEncryptEnabled(false);
        module_env->SetUploadTimerEnabled(true);
        module_env->SetShareRecordThread(moduleConfig.shareRecordThread ? true : false);
        
        __weak __typeof(moduleConfig) weakModuleConfig = moduleConfig;
        if (moduleConfig.cloudCommandBlock != nil) {
            module_env->SetCloudCommandHandler([weakModuleConfig](const std::string& base64_string, const std::string& ran) -> void {
                @autoreleasepool {
                    NSString *base64String = [NSString stringWithUTF8String:base64_string.c_str()];
                    NSString *ranString = [NSString stringWithUTF8String:ran.c_str()];
                    NSData *encyptedData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                    weakModuleConfig.cloudCommandBlock(encyptedData, ranString);
                }
            });
        }
        
        if (moduleConfig.downgradeRuleUpdateBlock != nil && moduleConfig.downgradeBlock != nil) {
            module_env->SetDowngradeRuleUpdator([weakModuleConfig](const std::string& data) -> void {
                @autoreleasepool {
                    NSString *jsonString = [NSString stringWithUTF8String:data.c_str()];
                    NSDictionary *info = dictionaryWithJsonString(jsonString);
                    weakModuleConfig.downgradeRuleUpdateBlock(info);
                }
            });
            module_env->SetDowngradeHanlder([weakModuleConfig] (const std::string& log_type, const std::string& service_name, const std::string& aid, double current_time) -> bool {
                @autoreleasepool {
                    NSString *logType = [NSString stringWithUTF8String:log_type.c_str()];
                    NSString *serviceName = [NSString stringWithUTF8String:service_name.c_str()];
                    NSString *appId = [NSString stringWithUTF8String:aid.c_str()];
                    BOOL ret = weakModuleConfig.downgradeBlock(logType, serviceName, appId, current_time);
                    return ret ? true : false;
                }
            });
        }
        
        if (moduleConfig.tagVerifyBlock != nil) {
            module_env->SetTagVerifyHanlder([weakModuleConfig](long tag) -> bool {
                @autoreleasepool {
                    BOOL ret = weakModuleConfig.tagVerifyBlock(tag);
                    return ret ? true : false;
                }
            });
        }
        
        
        hermas::ModuleEnv::RegisterModuleEnv(module_env);
        
    });
}

- (void)heimdallrInitDidCompleted {
    // 如果module初始化就开启上报，此时可能ttnet还没有初始化完成导致crash，因此等到Heimdallr初始化完成后再上报
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "heimdallr did init completed.");
        WeakPtr<WeakModuleEnvMap> map_weak_ptr = ModuleEnv::GetModuleEnvMap();
        auto module_env_map = map_weak_ptr.Lock()->GetItem();
        for (auto& iter : module_env_map) {
            std::shared_ptr<ModuleEnv>& module_env = iter.second;
            [self processLaunchLogic:module_env];
        }
    });
}

- (void)processLaunchLogic:(std::shared_ptr<ModuleEnv>)module_env {
    // move prepare data to ready or local at launch time asynchronously
    dispatch_async(hermas_queue(), ^{
        auto& storage_monitor = StorageMonitor::GetInstance(module_env);
        storage_monitor->OnMoveFinished = [self, module_env]() -> void {
            dispatch_async(self.searchQueue, ^{
                NSString *moduleName = [NSString stringWithCString:module_env->GetModuleId().c_str() encoding:NSUTF8StringEncoding];
                dispatch_block_t block = [self.pendingCloudCommand objectForKey:moduleName];
                if (block) block();
                [self.pendingCloudCommand removeObjectForKey:moduleName];
                
                // launch module if needed
                if ([self.class isEnabled]) {
                    [self launchUploadWithModuleId:moduleName];
                }
            });
        };
        storage_monitor->MovePrepareToReadyAndLocal();
    });
}

- (void)launchUploadWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        auto& service = UploadService::GetInstance(module_env);
        if (module_env->GetUploadTimerEnabled() && !service->IsCycleStart()) {
            service->StartCycle();
        }
    });
}

- (void)startUploadTimerWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        module_env->SetUploadTimerEnabled(true);
        auto& service = UploadService::GetInstance(module_env);
        service->StartCycle();
    });
}

- (void)stopUploadTimerWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        module_env->SetUploadTimerEnabled(false);
        auto& service = UploadService::GetInstance(module_env);
        service->StopCycle();
    });
}

- (void)triggerUploadManuallyWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        auto& service = UploadService::GetInstance(module_env);
        service->TriggerUpload();
    });
}

- (void)triggerFlushAndUploadManuallyWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:[HMEngine sharedEngine].globalConfig.hostAid];
        [instance UploadWithFlushImmediately];
    });
}

- (void)cleanAllCacheManuallyWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        HMInstance *instance = [[HMEngine sharedEngine] instanceWithModuleId:moduleId aid:[HMEngine sharedEngine].globalConfig.hostAid];
        [instance cleanAllCache];
    });
}

- (void)cleanAllCacheManuallyBeforeTime:(int)time {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "clean all cache manually before time: %d", time);
        WeakPtr<WeakModuleEnvMap> map_weak_ptr = ModuleEnv::GetModuleEnvMap();
        auto module_env_map = map_weak_ptr.Lock()->GetItem();
        for (auto& iter : module_env_map) {
            std::shared_ptr<ModuleEnv>& module_env = iter.second;
            auto& service = StorageMonitor::GetInstance(module_env);
            service->RemoveFilesWithMaxRemainSeconds(time);
        }
    });
}

- (void)uploadLocalDataWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        pthread_rwlock_rdlock(&self->_containerLock);
        [self.container enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, HMInstance * _Nonnull instance, BOOL * _Nonnull stop) {
            if ([instance.config.moduleId isEqualToString:moduleId]) {
                [instance UploadLocalData];
            }
        }];
        pthread_rwlock_unlock(&self->_containerLock);
    });
}

- (HMInstance *)instanceWithModuleId:(NSString *)moduleId aid:(NSString *)aid {
    HMInstanceConfig *config = [[HMInstanceConfig alloc] initWithModuleId:moduleId aid:aid];
    return [self instanceWithConfig:config];
}

- (HMInstance *)instanceWithConfig:(HMInstanceConfig *)config {
    __block HMInstance *instance = nil;
    NSString *key = [NSString stringWithFormat:@"%@_%@", config.moduleId, config.aid];
    
    pthread_rwlock_rdlock(&_containerLock);
    instance = [_container objectForKey:key];
    pthread_rwlock_unlock(&_containerLock);
    if (instance) return instance;
    
    auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(config.moduleId));
    if (module_env) {
        pthread_rwlock_wrlock(&_containerLock);
        instance = [_container objectForKey:key];
        if (!instance) {
            instance = [[HMInstance alloc] initWithConfig:config];
            [_container setObject:instance forKey:key];
        }
        pthread_rwlock_unlock(&_containerLock);
    } else {
        logi("HMEngine", "The module_env has not been initilized and should get the instance with hermas queue, moduleId = %s", SAFE_UTF8_STRING(config.moduleId));
        dispatch_sync(hermas_queue(), ^{
            pthread_rwlock_wrlock(&_containerLock);
            instance = [_container objectForKey:key];
            if (!instance) {
                instance = [[HMInstance alloc] initWithConfig:config];
                [_container setObject:instance forKey:key];
            }
            pthread_rwlock_unlock(&_containerLock);
        });
    }
    
    // 没有实际上报操作，只是将aggre/semi中的数据迁移到prepare/ready文件夹中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), hermas_queue(), ^{
        // launch report for semi
        [instance launchReportForSemi];
        
        // stop aggregation
        [instance stopAggregate:YES];
    });
    
    return instance;
}

- (void)updateReportHeader:(NSDictionary *)reportHeader {
    dispatch_on_hermas_queue(^{
        const char *newHeader = stringWithDictionary(reportHeader).UTF8String;
        logi("HMEngine", "updateReportHeader, new header = %s", newHeader);
        bool ret = GlobalEnv::GetInstance().SetReportHeaderLowLevelParams(newHeader);
        if (!ret) return;
        pthread_rwlock_rdlock(&self->_containerLock);
        [self.container enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull instance, BOOL * _Nonnull stop) {
            [instance updateReportHeader:reportHeader];
        }];
        pthread_rwlock_unlock(&self->_containerLock);
    });
}


/// 已有采样率，停止缓存
- (void)stopCache {
    dispatch_on_hermas_queue(^{
        pthread_rwlock_rdlock(&self->_containerLock);
        [self.container enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, HMInstance * _Nonnull instance, BOOL * _Nonnull stop) {
            [instance stopCache];
        }];
        pthread_rwlock_unlock(&self->_containerLock);
    });
}

- (void)updateFlowControlStrategy:(HMFlowControlStrategy)flowControlStrategy {
    dispatch_on_hermas_queue(^{
        self.flowControlStrategy = flowControlStrategy;
        logi("HMEngine", "update flow control strategy: %s", (flowControlStrategy == HMFlowControlStrategyNormal ? "normal" : "limited"));
        WeakPtr<WeakModuleEnvMap> map_weak_ptr = ModuleEnv::GetModuleEnvMap();
        auto module_env_map = map_weak_ptr.Lock()->GetItem();
        for (auto& iter : module_env_map) {
            std::shared_ptr<ModuleEnv>& module_env = iter.second;
            auto& service = UploadService::GetInstance(module_env);
            service->UpdateFlowControlStrategy((FlowControlStrategyType)flowControlStrategy);
        }
    });
}

- (void)updateReportDegradeState:(BOOL)needDegrade moduleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "update report degrade state: %s", (needDegrade ? "true" : "false"));
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        if (module_env) {
            module_env->SetNeedReportDegrade(needDegrade ? true : false);
        }
    });
}

- (void)updateHeimdallrInitCompleted:(BOOL)heimdallrInitCompleted {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "update heimdallr init completed: %s.", (heimdallrInitCompleted ? "true" : "false"));
        auto& global_env = GlobalEnv::GetInstance();
        BOOL originalFlag = global_env.GetHeimdallrInitCompleted();
        if (!originalFlag && heimdallrInitCompleted) {
            global_env.SetHeimdallrInitCompleted(heimdallrInitCompleted);
            [self heimdallrInitDidCompleted];
        }
    });
}

- (void)updateGlobalConfig:(id<HMGlobalConfig>)globalConfig {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "update global config");
        auto& global_env = GlobalEnv::GetInstance();
        global_env.SetMaxStoreTime((int)globalConfig.maxStoreTime);
        global_env.SetMaxFileSize((int)globalConfig.maxFileSize);
        global_env.SetMaxLogNumber((int)globalConfig.maxLogNumber);
        global_env.SetMaxReportSize((int)globalConfig.maxReportSize);
        global_env.SetMaxReportSizeLimited((int)globalConfig.limitReportSize);
        global_env.SetReportInterval((int)globalConfig.reportInterval);
        global_env.SetReportIntervalLimited((int)globalConfig.limitReportInterval);
        global_env.SetCleanupInterval((int)globalConfig.reportInterval * 5);
    });
}


- (void)updateModuleConfig:(id<HMModuleConfig>)moduleConfig {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "update module config: module id = %s", SAFE_UTF8_STRING(moduleConfig.name));
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleConfig.name));
        if (!module_env) return;
        // only update the mutable field
        module_env->SetDomain(SAFE_UTF8_STRING(moduleConfig.domain));
        module_env->SetMaxStoreSize((int)moduleConfig.maxStoreSize);
        module_env->SetForwardEnabled(moduleConfig.forwardEnabled ? true : false);
        module_env->SetEncryptEnabled(moduleConfig.enableEncrypt ? true : false);
        module_env->SetMaxLocalStoreSize((int)moduleConfig.maxLocalStoreSize);
        if (moduleConfig.forwardUrl.length > 0) {
            module_env->SetForwardUrl(std::string(SAFE_UTF8_STRING(moduleConfig.forwardUrl)));
        }
    });
}

- (void)searchWithParam:(HMSearchParam *)param callback:(void(^)(NSArray<NSString *> *, FinishBlock finishBlock))callback {
    dispatch_block_t block = ^{
        logi("HMEngine", "start search, moduleid = %s, aid = %s", SAFE_UTF8_STRING(param.moduleId), SAFE_UTF8_STRING(param.aid));
        HMInstance *instance = [self instanceWithModuleId:param.moduleId aid:param.aid];
        NSAssert(instance != nil, @"the instance must be existing");
        NSDictionary<NSString*, NSArray*> *ret = [instance searchWithCondition:param.condition];
        logi("HMEngine", "end search, moduleid = %s, aid = %s", SAFE_UTF8_STRING(param.moduleId), SAFE_UTF8_STRING(param.aid));
        
        if (ret.count > 0) {
            // delete callback
            FinishBlock finishBlock = ^(BOOL success) {
                if (!success) return;
                for (NSString *fileName in ret.allKeys) {
                    RemoveFile(SAFE_UTF8_STRING(fileName));
                }
            };
            
            // result
            NSMutableArray *result = @[].mutableCopy;
            for (NSArray *records in ret.allValues) {
                [result addObjectsFromArray:records];
            }
            
            if (callback) callback(result, [finishBlock copy]);
            
        } else {
            
            if (!self.searchDataSource) {
                if (callback) callback(nil, nil);
                return;
            }
            NSArray *records = [self.searchDataSource getDataWithParam:param];
            __weak __typeof(self) wself = self;
            FinishBlock finishBlock = ^(BOOL success) {
                __strong __typeof(wself) sself = wself;
                dispatch_async(sself.searchQueue, ^{
                    if (!success) return;
                    [sself.searchDataSource removeDataWithParam:param];
                });
            };
            if (callback) callback(records, [finishBlock copy]);
        }
    };
    
    auto& moduleEnv = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(param.moduleId));
    auto& monitor_storagte = StorageMonitor::GetInstance(moduleEnv);
    if (monitor_storagte->IsMoveFinished()) {
        dispatch_async(self.searchQueue, block);
    } else {
        dispatch_async(self.searchQueue, ^{
            [self.pendingCloudCommand setObject:block forKey:param.moduleId];
        });
    }
}

// session
- (NSDictionary *)getLatestSession:(NSString *)rootDir {
    if (rootDir.length == 0) return nil;
    __block NSString *session = nil;
    dispatch_sync(hermas_queue(), ^{
        auto& session_service = SessionService::GetInstance(SAFE_UTF8_STRING(rootDir));
        session = [NSString stringWithCString:session_service->GetLatestSession().c_str() encoding:[NSString defaultCStringEncoding]];
        logi("HMEngine", "get latest session at last launch, %s", SAFE_UTF8_STRING(session));
    });
    return dictionaryWithJsonString(session);
}

- (void)updateSessionRecordWith:(NSDictionary *)newSessionRecord {
    NSString *rootDir = self.globalConfig.rootDir;
    NSString *record = stringWithDictionary(newSessionRecord);
    if (rootDir.length == 0) {
        logi("HMEngine", "update session record failed because of nil rootDir. session = %s", SAFE_UTF8_STRING(record));
        return;
    }
    auto& session_service = SessionService::GetInstance(SAFE_UTF8_STRING(rootDir));;
    logi("HMEngine", "update session record: %s", SAFE_UTF8_STRING(record));
    session_service->UpdateSessionRecord(SAFE_UTF8_STRING(record));
}

- (void)updateMaxReportSizeWeights:(NSDictionary *)weights {
    dispatch_on_hermas_queue(^{
        logi("HMEngine", "update max report size weight");
        self.maxUploadSizeWeights = weights;
        auto& global_env = GlobalEnv::GetInstance();
        global_env.SetMaxReportSizeWeights(mapWithDoubleNSDictionary(weights));
    });
}

- (NSDictionary *)getUpdateMaxReportSizeWeights {
    return self.maxUploadSizeWeights;
}

- (void)migrateDataWithModuleId:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        if (module_env) {
            auto migrate_service = std::make_unique<MigrateService>(module_env);
            migrate_service->Migrate();
        }
    });
}

- (void)cleanRollbackMigrateMark:(NSString *)moduleId {
    dispatch_on_hermas_queue(^{
        auto& module_env = ModuleEnv::GetModuleEnv(SAFE_UTF8_STRING(moduleId));
        auto migrate_service = std::make_unique<MigrateService>(module_env);
        migrate_service->CleanMigrateMark();
    });
}

#pragma mark - Private

std::string queryStringWithDict(NSDictionary *dic) {
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //避免一些嵌套结构拼接到query里
        if(![obj isKindOfClass:[NSDictionary class]]) {
            NSString *value = [[obj description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        } else {
            
        }
    }];
    NSString *strWithDict = [keyValuePairs componentsJoinedByString:@"&"];
    std::string str_with_dict = strWithDict.UTF8String;
    return str_with_dict;
}

std::string queryStringWithConfig(HMGlobalConfig *globalConfig) {
    @autoreleasepool {
        NSMutableDictionary *commonParams;
        if (globalConfig.reportCommonParamsBlock) {
            commonParams = [NSMutableDictionary dictionaryWithDictionary:globalConfig.reportCommonParamsBlock()];
        } else {
            commonParams = [NSMutableDictionary dictionaryWithDictionary:globalConfig.reportCommonParams];
        }
        
        NSMutableDictionary *headerInfo = [NSMutableDictionary dictionaryWithDictionary:globalConfig.reportHeaderConstantParams];
        [headerInfo addEntriesFromDictionary:globalConfig.reportHeaderLowLevelParams];
        
        if (isDictionaryEmpty(commonParams)) {
            commonParams = headerInfo;
        } else {
            // add necessary params for quota
            if (![commonParams valueForKey:@"update_version_code"]) {
                [commonParams setValue:headerInfo[@"update_version_code"] forKey:@"update_version_code"];
            }
            if (![commonParams valueForKey:@"os"]) {
                [commonParams setValue:headerInfo[@"os"] forKey:@"os"];
            }
            if (![commonParams valueForKey:@"aid"]) {
                [commonParams setValue:headerInfo[@"aid"] forKey:@"aid"];
            }
        }
        
        // add necessary params for downgrade
        if (![commonParams valueForKey:@"host_aid"]) {
            [commonParams setValue:globalConfig.hostAid forKey:@"host_aid"];
        }
        std::string query_str = queryStringWithDict(commonParams);
        return query_str;
    }
}

@end
