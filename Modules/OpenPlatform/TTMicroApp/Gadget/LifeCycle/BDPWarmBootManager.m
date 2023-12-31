//
//  BDPWarmBootManager.m
//  Timor
//
//  Created by liubo on 2018/11/22.
//

#import "BDPWarmBootManager.h"
#import "BDPAPIInterruptionManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPLog.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPTaskManager.h"
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPUniqueID.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPGadgetLog.h"
#import <LarkMonitor/BDPowerLogManager.h>
#import <ECOInfra/EMAFeatureGating.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOConfig.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

#define BDP_WARMBOOT_CACHE_MAX_COUNT       5
#define BDP_WARMBOOT_CACHE_MIN_COUNT       1

#if DEBUG
#define BDP_WARMBOOT_CACHE_RESIDENT_TIME   30
#else
#define BDP_WARMBOOT_CACHE_RESIDENT_TIME   300
#endif

@interface BDPWarmBootManager ()

@property (nonatomic, assign) int maxCacheCount;

//用于热启动的缓存cache
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSMutableArray<BDPUniqueID *> *idCache; //这里拆分出单独的idCache，是为了不依赖于task.commom.model.ID，希望后期BDPTask能进一步减负解耦。
@property (nonatomic, strong) NSMapTable<BDPUniqueID *, BDPWarmBootCleaner> *cleanerTable;  /** 弱引用Cleaner的Table */
@property (nonatomic, strong) NSMutableDictionary<BDPUniqueID *, NSDictionary<NSString *, id> *> *dataCache;  //Key:@"tt00a0000bc0000def"; Value:自定义的字典;

@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *appIdsTimeoutConfig;

/// settings 配置的最大缓存个数
@property (nonatomic, assign) int configCacheMaxCount;

/// 是否热缓存配置对所有app生效
@property (nonatomic, assign) BOOL enableAllAppIds;
/// 所有app生效时，最大缓存时间
@property (nonatomic, strong) NSNumber *allAppClearnTimeout;

@end

#pragma mark - BDPWarmBootManager

@implementation BDPWarmBootManager

#pragma mark - Init

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPWarmBootManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self buildWarmBootManager];
    }
    return self;
}


/// 更新小程序清理超时配置
- (void)updateGadgetCleanConfig {
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString*, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:@"gadget_warm_boot_config"]);
    // -1 表示settings无配置或者配置值小于等于5
    int resultCacheCount = -1;
    NSDictionary<NSString *, NSNumber *> *resultAppIdsConfig = nil;
    
    BOOL resultEnableAllAppIds = NO;
    NSNumber *resultAllAppClearnTimeout = nil;
    
    if (config) {
        
        NSNumber *configAllAppIds = config[@"enableAllAppIds"];
        if([configAllAppIds isKindOfClass:[NSNumber class]]) {
            resultEnableAllAppIds = [configAllAppIds boolValue];
        }
        
        NSNumber *configAllAppClearnTimeout = config[@"allAppClearnTimeout"];
        if([configAllAppClearnTimeout isKindOfClass:[NSNumber class]] && configAllAppClearnTimeout.doubleValue > 0) {
            resultAllAppClearnTimeout = configAllAppClearnTimeout;
        }
        
        NSNumber *cacheCountNum = config[@"maxCacheCount"];
        // 最大缓存个数
        if([cacheCountNum isKindOfClass:[NSNumber class]] && cacheCountNum.intValue > BDP_WARMBOOT_CACHE_MAX_COUNT) {
            resultCacheCount = cacheCountNum.intValue;
        }
        NSArray<NSDictionary<NSString *, NSNumber *> *> *appIdsConfig = BDPSafeArray(config[@"whiteAppIds"]);
        if(appIdsConfig.count > 0) {
            NSDictionary<NSString *, NSNumber *> *clearnConfig = [NSMutableDictionary dictionaryWithCapacity:appIdsConfig.count];
            for (NSDictionary *timeoutConfig in appIdsConfig) {
                if([timeoutConfig isKindOfClass:[NSDictionary class]]) {
                    NSString *appId = BDPSafeString(timeoutConfig[@"appId"]);
                    NSNumber *clearnTimeout = timeoutConfig[@"clearnTimeout"];
                    if(appId.length > 0  && [clearnTimeout isKindOfClass:[NSNumber class]] && clearnTimeout.doubleValue > 0) {
                        [clearnConfig setValue:clearnTimeout forKey:appId];
                    }
                }
            }
            // 缓存应用超时配置
            if(clearnConfig.count > 0) {
                resultAppIdsConfig = clearnConfig;
            }
        }
    }
    self.configCacheMaxCount = resultCacheCount;
    self.appIdsTimeoutConfig = resultAppIdsConfig;
    self.enableAllAppIds = resultEnableAllAppIds;
    self.allAppClearnTimeout = resultAllAppClearnTimeout;
}


/// 没有配置就走默认时间，BDP_WARMBOOT_CACHE_RESIDENT_TIME
/// - Parameter uniqueId: appId
- (NSTimeInterval)timeoutForUniqueId:(BDPUniqueID *)uniqueId {
    NSString *appId = BDPSafeString(uniqueId.appID);
    if(appId.length > 0  && self.appIdsTimeoutConfig) {
        NSNumber *configTimeout = self.appIdsTimeoutConfig[appId];
        if(configTimeout != nil) {
            return [configTimeout doubleValue];
        }
    }
    
    if(self.enableAllAppIds && self.allAppClearnTimeout != nil) {
        return [self.allAppClearnTimeout doubleValue];
    }
    
    return BDP_WARMBOOT_CACHE_RESIDENT_TIME;
}

- (BOOL)isWhiteForUniqueId:(BDPUniqueID *)uniqueId {
    
    NSString *appIdStr = BDPSafeString(uniqueId.appID);
    if(self.appIdsTimeoutConfig && self.appIdsTimeoutConfig[appIdStr]) {
        return YES;
    }
    
    if(self.enableAllAppIds && self.allAppClearnTimeout != nil) {
        return YES;
    }
    
    return NO;
}


/// 最终生效的缓存个数上限， 如果有配置，采用配置中的值，否则使用宏BDP_WARMBOOT_CACHE_MAX_COUNT
- (int)finalMaxCacheCount {
    // settings无配置或值小于等于5，configCacheMaxCount值为-1；判断大于0，是为了校验setting配置是否有效
    // setting 配置有效，MaxCacheCount的上限取配置，否则使用宏的值（5）
    return self.configCacheMaxCount > 0 ? self.configCacheMaxCount : BDP_WARMBOOT_CACHE_MAX_COUNT;
}

- (void)buildWarmBootManager {
    self.maxCacheCount = BDP_WARMBOOT_CACHE_MAX_COUNT;
    
    [self updateGadgetCleanConfig];
    // settings无配置或值小于等于5，configCacheMaxCount值为-1；判断大于0，是为了校验setting配置是否有效
    // setting 配置有效，maxCacheCount改为配置值
    if(self.configCacheMaxCount > 0) {
        self.maxCacheCount = self.configCacheMaxCount;
    }
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = @"com.bytedance.warmBootManager.lock";
    
    self.idCache = [[NSMutableArray alloc] initWithCapacity:self.maxCacheCount];
    self.dataCache = [[NSMutableDictionary alloc] initWithCapacity:self.maxCacheCount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reciveMemoryWarningNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)dealloc {
    [self clearAllWarmBootCache];
}

#pragma mark - getter
- (NSArray<BDPUniqueID *> *)uniqueIdInFront {
    NSMutableSet<BDPUniqueID *> *uniqueIdCache = [NSMutableSet set];
    // iPad 多 Scene 下会有多个 window，需要遍历所有 window
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        NSArray<BDPUniqueID *> *uniqueIds = [self uniqueIdInFront:window];
        [uniqueIdCache addObjectsFromArray:uniqueIds];
    }
    return [uniqueIdCache allObjects];
}

- (NSArray<BDPUniqueID *> *)uniqueIdInFront:(UIWindow *)window {
    NSMutableArray<BDPUniqueID *> *uniqueIdCache = [NSMutableArray array];
    [self.dataCache.copy enumerateKeysAndObjectsUsingBlock:^(BDPUniqueID * _Nonnull uniqueID, id  _Nonnull data, BOOL * _Nonnull stop) {
        UIViewController *topVC = [[BDPResponderHelper topNavigationControllerFor:[BDPResponderHelper topmostView:window]] topViewController] ?: [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView:window]];
        BDPNavigationController *subNavi = [self subNaviWithUniqueID:uniqueID];
        UIViewController *bdpVC = [subNavi parentViewController];
        BOOL isBDPFront = NO;
        //如果置顶vc为小程序vc则证明小程序在前台
        if (bdpVC == topVC) {
            isBDPFront = YES;
        }
        //如果置顶vc的navigationController和小程序vc的navigationController是一个，且小程序不在栈顶
        else if ([bdpVC navigationController] && [[bdpVC navigationController] topViewController] != bdpVC && [bdpVC navigationController] == [topVC navigationController])
        {
            isBDPFront = YES;
        }
        //如果小程序vc的navigationController的栈顶就是小程序vc，则先寻找present的vc是否是topvc，再寻找小程序vc自身栈顶是否为topvc
        else if ([bdpVC navigationController] && [[bdpVC navigationController] topViewController] == bdpVC && [bdpVC presentedViewController])
        {
            while ([bdpVC presentedViewController]) {
                bdpVC = [bdpVC presentedViewController];
            }
            if ([bdpVC isKindOfClass:[UINavigationController class]]) {
                if ([(UINavigationController*)bdpVC topViewController] == topVC) {
                    isBDPFront = YES;
                }
            }else if ([bdpVC isKindOfClass:[UIViewController class]])
            {
                if (bdpVC == topVC) {
                    isBDPFront = YES;
                }
            }
        }
        
        if([OPTemporaryContainerService isGadgetTemporaryEnabled] && [OPTemporaryContainerService isTemporayWithContainer:bdpVC]) {
            BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"TemporayWithContainer front : %@", uniqueID);
            isBDPFront = YES;
        }
        
        //配置为 enableAutoDestroy false的也保留，当前Tab小程序配置为false
        if (isBDPFront || ![self isAutoDestroyEnableWithUniqueID:uniqueID]) {
            [uniqueIdCache addObject:uniqueID];
        }
    }];
    
    return [uniqueIdCache copy];
}

- (NSSet<BDPUniqueID *> *)aliveAppUniqueIdSet {
    [self.lock lock];
    NSArray<BDPUniqueID *> *copyIdCache = [self.idCache copy];
    [self.lock unlock];
    return copyIdCache.count ? [NSSet setWithArray:copyIdCache] : [NSSet set];
}

#pragma mark - Memory Warning Notification

- (void)reciveMemoryWarningNotification:(NSNotification *)aNotification {
    BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Recive memory warning");
    [self removeBackgroundCacheWithMaxCount:BDP_WARMBOOT_CACHE_MIN_COUNT];
}

#pragma mark - Utilities

- (void)updateMaxWarmBootCacheCount:(int)maxCount {
    //限制取值范围: [1, 5]
    int warmBootCacheMaxCount = [self finalMaxCacheCount];
    int formattedCount = MAX(BDP_WARMBOOT_CACHE_MIN_COUNT, MIN(warmBootCacheMaxCount, maxCount));
    if (self.maxCacheCount == formattedCount) {
        return;
    }
    self.maxCacheCount = formattedCount;
    [self removeBackgroundCacheWithMaxCount:self.maxCacheCount];
}

- (void)removeBackgroundCacheWithMaxCount:(int)maxCount {
    int warmBootCacheMaxCount = [self finalMaxCacheCount];
    if (maxCount > warmBootCacheMaxCount || maxCount < BDP_WARMBOOT_CACHE_MIN_COUNT) {
        return;
    }
    
    BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Remove background cache: %d", maxCount);
    
    [self.lock lock];
    int currentCount = (int)[self.idCache count];
    if (maxCount < currentCount) {
        int removeCount = currentCount - maxCount;
        __block BDPUniqueID *bgAudioUniqueID = nil;
        [self.idCache enumerateObjectsUsingBlock:^(BDPUniqueID * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(isBackgroundAudioWorking)] && [obj performSelector:@selector(isBackgroundAudioWorking)]) {
                bgAudioUniqueID = obj;
                *stop = YES;
            }
        }];
        
        if (bgAudioUniqueID) {
            [self.idCache removeObject:bgAudioUniqueID];
            [self.idCache addObject:bgAudioUniqueID];
        }
        
        NSArray<BDPUniqueID *> *allUniqueIds = [self.idCache copy];
        
        for (int i = 0; i < currentCount && removeCount > 0; i++) {
            BDPUniqueID *uniqueID = allUniqueIds[i];
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
            
            BOOL isBackground = NO;

            // 新容器的判断逻辑, 应用在后台 && 应用已被 unmount。Q: 如何保障嵌入式小程序不被强制回收？A: 嵌入式小程序 enableAutoDestroy = false
            OPContainerContext *context = [OPApplicationService.current getContainerWithUniuqeID:uniqueID].containerContext;
            isBackground = context.containerConfig.enableAutoDestroy
                            && (context && context.activeState == OPContainerActiveStateInactive)
                            && (context && context.mountState == OPContainerMountStateUnmount);

            if (isBackground) {
                [self cleanCacheNoLockWithUniqueID:uniqueID];
                removeCount--;
                BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Background cache clean: %@", uniqueID);
            }
        }
    }
    [self.lock unlock];
}

-(BOOL)isAutoDestroyEnableWithUniqueID:(BDPUniqueID *)uniqueID{
    OPContainerContext *context = [OPApplicationService.current getContainerWithUniuqeID:uniqueID].containerContext;
    if (!context || !context.containerConfig) {
        return true;
    }
    return context.containerConfig.enableAutoDestroy;
}

#pragma mark - Interface
- (void)cacheWithUniqueID:(BDPUniqueID *)uniqueID data:(NSDictionary<NSString *, id>*)data cleaner:(BDPWarmBootCleaner)cleaner {
    if (uniqueID == nil || data == nil) {
        return;
    }
    
    [self.lock lock];
    [self.idCache addObject:uniqueID];
    [self.dataCache setObject:data forKey:uniqueID];
    [self.cleanerTable setObject:cleaner forKey:uniqueID];
    
    BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Cache new: %@", uniqueID);
    if ([self.idCache count] > self.maxCacheCount) {
        [self removeBackgroundCacheWithMaxCount:self.maxCacheCount];
    }
    [self.lock unlock];
}

- (void)cleanCacheWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        return;
    }
    
    [self.lock lock];
    [self cleanCacheNoLockWithUniqueID:uniqueID];
    BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Cache clean: %@", uniqueID);
    [self.lock unlock];
}

- (void)cleanCacheWithoutappIDs:(nullable NSArray<NSString *> *)appIDs result:(void(^)(int beforeNum, int afterNum))result{
    [self.lock lock];
    int beforeCacheNum = (int)self.idCache.count;
    for (BDPUniqueID *uniqueID in [self.idCache copy]) {
        if ([appIDs containsObject:uniqueID.appID] || [self.uniqueIdInFront containsObject:uniqueID]) {
            BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Cache not clean: %@", uniqueID);
        } else {
            [self cleanCacheNoLockWithUniqueID:uniqueID];
        }
    }
    int afterCacheNum = (int)self.idCache.count;
    if(result){
        result(beforeCacheNum,afterCacheNum);
    }
    [self.lock unlock];
}

- (void)cleanCacheNoLockWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        BDPGadgetLogWarn(@"cleanCacheNoLockWithUniqueID uniqueID is nil");
        return;
    }
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    BDPWarmBootCleaner cleaner = [self.cleanerTable objectForKey:uniqueID];
    // 告知cleaner开始清理
    if ([cleaner respondsToSelector:@selector(warmBootManagerWillEvictCache)]) {
        BDPGadgetLogInfo(@"start warmBootManagerWillEvictCache clean is %@,uniqueID is %@", cleaner, uniqueID);
        [cleaner warmBootManagerWillEvictCache];
    } else {
        BDPGadgetLogInfo(@"cleaner responder failed clean is %@, uniqueID is %@", cleaner, uniqueID);
    }
    
    [self stopTimerToReleaseViewWithUniqueID:uniqueID];
    [self.idCache removeObject:uniqueID];
    [self.dataCache removeObjectForKey:uniqueID];
    [self.cleanerTable removeObjectForKey:uniqueID];
    
    [[BDPAPIInterruptionManager sharedManager] clearInterruptionStatusForApp:uniqueID];
    [[BDPTracker sharedInstance] removeLifecycleIdWithUniqueId:uniqueID];
    [BDPTracker removeCommomParamsForUniqueID:uniqueID];
    
    // 热缓存释放时, 删除临时文件目录
    NSString *tmpPath = common.sandbox.tmpPath;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if (tmpPath) {
            [[LSFileSystem main] removeItemAtPath:tmpPath error:nil];
        }
    });
    
    BDPTask *task = BDPTaskFromUniqueID(uniqueID);
    UIViewController *containerVC = task.containerVC;
#if ALPHA
    [self manuCheckLeaks:containerVC];
    [self manuCheckLeaks:task.context];
#endif

    if(![EMAFeatureGating boolValueForKey:@"openplatform.gadget.disable.powerlog"] && task){
        //小程序回收 且 FG未关闭的情况下，记录小程序 功耗终点，背景见： https://bytedance.feishu.cn/wiki/wikcnCmvpVZJfCdnlRa5MzVtN7f
        [BDPowerLogManager endEvent:@"op_gadget_run" params:@{@"app_id":uniqueID.appID}];
    }
    // --- 这两个放最后, 确保上述清理操作若要用的Common跟Task, 还能取到 ---
    [[BDPCommonManager sharedManager] removeCommonWithUniqueID:uniqueID];
    [[BDPTaskManager sharedManager] removeTaskWithUniqueID:uniqueID];
    
    if ([PageKeeperManagerOCBridge larkKeepAliveEnable]) {
        [PageKeeperManagerOCBridge removePageWithUniqueId:uniqueID];
    }

    id<OPContainerProtocol> container = [OPApplicationService.current getContainerWithUniuqeID:uniqueID];
    if (!container.containerContext.isReloading) {
        // 只有在非 reloading 状态下才会自动回收
        [OPApplicationService.current removeContainerWithUniuqeID:uniqueID];
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:containerVC];
    }
}

- (NSDictionary <NSString *, id>*)getDataWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        return nil;
    }
    
    [self.lock lock];
    NSDictionary *result = [self.dataCache objectForKey:uniqueID];
    [self.lock unlock];
    return result;
}

- (void)setDataWithUniqueID:(BDPUniqueID *)uniqueID data:(NSDictionary<NSString *, id>*)data {
    if (!uniqueID) {
        return;
    }
    
    [self.lock lock];
    if (data != nil) {
        [self.dataCache setObject:data forKey:uniqueID];
    } else {
        [self.idCache removeObject:uniqueID];
        [self.dataCache removeObjectForKey:uniqueID];
        [[BDPCommonManager sharedManager] removeCommonWithUniqueID:uniqueID];
        [[BDPTaskManager sharedManager] removeTaskWithUniqueID:uniqueID];
    }
    [self.lock unlock];
}

- (BOOL)hasCacheDataWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        return NO;
    }
    
    [self.lock lock];
    BOOL idCache = [self.idCache containsObject:uniqueID];
    [self.lock unlock];
    
    return idCache;
}

- (BOOL)hasCacheData {
    [self.lock lock];
    NSUInteger idCacheCnt = [self.idCache count];
    [self.lock unlock];
    
    return idCacheCnt > 0;
}

// TODO: 即将删除的代码
- (void)clearAllWarmBootCache {
    [self.lock lock];
    for (BDPUniqueID *uniqueID in [self.idCache copy]) {

        OPContainerContext *context = [OPApplicationService.current getContainerWithUniuqeID:uniqueID].containerContext;
        if (context && !context.containerConfig.enableAutoDestroy) {
            // 不允许自动回收的小程序
            continue;
        }

        [self cleanCacheNoLockWithUniqueID:uniqueID];
    }
    [self.lock unlock];

    BDPGadgetLogTagInfo(kBDPWarmBootManagerLogTag, @"Cache clean all");
}

#pragma mark - Convenience Methods

- (BDPNavigationController *)subNaviWithUniqueID:(BDPUniqueID *)uniqueID {
    NSDictionary<NSString *, id> *data = [self getDataWithUniqueID:uniqueID];
    if (!BDPIsEmptyDictionary(data)) {
        return [data bdp_objectForKey:BDP_WARMBOOT_DIC_RESIDENT ofClass:[BDPNavigationController class]];
    }
    return nil;
}

- (void)cacheSubNavi:(BDPNavigationController *)subNavi uniqueID:(BDPUniqueID *)uniqueID cleaner:(BDPWarmBootCleaner)cleaner {
    if (!uniqueID || !subNavi) {
        return;
    }
    
    // 有缓存则不再缓存
    if ([self subNaviWithUniqueID:uniqueID]) {
        return;
    }
    
    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    [dataDic setValue:uniqueID forKey:BDP_WARMBOOT_DIC_UNIQUEID];
    [dataDic setValue:nil forKey:BDP_WARMBOOT_DIC_TIMER];
    [dataDic setValue:subNavi forKey:BDP_WARMBOOT_DIC_RESIDENT];
    
    [self cacheWithUniqueID:uniqueID data:[dataDic copy] cleaner:cleaner];
}

#pragma mark - Resident Timer

- (BOOL)startTimerToReleaseViewWithUniqueID:(BDPUniqueID *)uniqueID {
    BDPGadgetLogInfo(@"startTimerToReleaseViewWithUniqueID, id=%@", uniqueID);
    if (!uniqueID) {
        return NO;
    }

    OPContainerContext *context = [OPApplicationService.current getContainerWithUniuqeID:uniqueID].containerContext;
    if (context && !context.containerConfig.enableAutoDestroy) {
        // 不允许自动回收的小程序
        return NO;
    }
    
    NSDictionary<NSString *, id> *data = [[BDPWarmBootManager sharedManager] getDataWithUniqueID:uniqueID];
    if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
        id residentObject = [data bdp_objectForKey:BDP_WARMBOOT_DIC_RESIDENT];
        if (residentObject != nil) {
            NSTimer *timer = [data bdp_objectForKey:BDP_WARMBOOT_DIC_TIMER];
            [timer invalidate];
            
            NSTimeInterval releaseTimeout = [self timeoutForUniqueId:uniqueID];
            BOOL isWhiteList = [self isWhiteForUniqueId:uniqueID];
            BDPGadgetLogInfo(@"scheduled release Timer, startTimerToRelease gadget, appID:%@, releaseTimeout(s):%@", BDPSafeString(uniqueID.appID), @(releaseTimeout));
            timer = [NSTimer scheduledTimerWithTimeInterval:releaseTimeout
                                                     target:self
                                                   selector:@selector(releaseResidentObject:)
                                                   userInfo:@{BDP_WARMBOOT_DIC_UNIQUEID : uniqueID,
                                                              BDP_WARMBOOT_DIC_CONFIG_WHITE : @(isWhiteList)}
                                                    repeats:NO];
            
            NSMutableDictionary *newDic = [data mutableCopy];
            [newDic setValue:timer forKey:BDP_WARMBOOT_DIC_TIMER];
            newDic[BDP_WARMBOOT_DIC_TIMER_TIME] = @(NSDate.date.timeIntervalSince1970);    // 记录timer开始的时间
            
            [[BDPWarmBootManager sharedManager] setDataWithUniqueID:uniqueID data:[newDic copy]];
            return YES;
        }
    }
    return NO;
}

- (BOOL)stopTimerToReleaseViewWithUniqueID:(BDPUniqueID *)uniqueID {
    BDPGadgetLogInfo(@"stopTimerToReleaseViewWithUniqueID, id=%@", uniqueID);
    if (!uniqueID) {
        return NO;
    }
    
    NSDictionary<NSString *, id> *data = [[BDPWarmBootManager sharedManager] getDataWithUniqueID:uniqueID];
    if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
        id residentObject = [data bdp_objectForKey:BDP_WARMBOOT_DIC_RESIDENT];
        if (residentObject != nil) {
            BDPGadgetLogInfo(@"invalidate timer");

            NSTimer *timer = [data bdp_objectForKey:BDP_WARMBOOT_DIC_TIMER];
            [timer invalidate];
            timer = nil;
            
            NSMutableDictionary *newDic = [data mutableCopy];
            [newDic setValue:timer forKey:BDP_WARMBOOT_DIC_TIMER];
            newDic[BDP_WARMBOOT_DIC_TIMER_TIME] = nil;
            
            [[BDPWarmBootManager sharedManager] setDataWithUniqueID:uniqueID data:[newDic copy]];
            return YES;
        }
    }
    return NO;
}

- (void)applicationWillEnterForeground
{
    [self.dataCache.copy enumerateKeysAndObjectsUsingBlock:^(BDPUniqueID * _Nonnull uniqueID, id  _Nonnull data, BOOL * _Nonnull stop) {
            if (data && [data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *tmgViewDic = (NSDictionary *)data;
                NSTimeInterval timerTime = [tmgViewDic bdp_doubleValueForKey:BDP_WARMBOOT_DIC_TIMER_TIME];
                // 清理不活跃且后台时间超过 BDP_WARMBOOT_CACHE_RESIDENT_TIME 的小程序
                NSTimeInterval releaseTimeout = [self timeoutForUniqueId:uniqueID];
                if (timerTime > 0 && NSDate.date.timeIntervalSince1970 - timerTime > releaseTimeout) {
                    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
                    if (common && !common.isActive && !([uniqueID respondsToSelector:@selector(isBackgroundAudioWorking)] && [uniqueID performSelector:@selector(isBackgroundAudioWorking)])) {
                        BDPGadgetLogInfo(@"clearTaskCacheWithAppID when applicationWillEnterForeground %@", BDPParamStr(uniqueID, timerTime));
                        [self cleanCacheWithUniqueID:uniqueID];
                    }
                }
            }
    }];
}

-(void)applicationDidEnterBackground
{
    //由于切前台卡死的问题，暂时需要在切后台5秒后杀掉所有的小程序热缓存，由于isActive在切后台不管用，所以这里采用直接寻找vc栈顶判断
    if ([BDPWarmBootManager isBackGroundKillEnable]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([BDPWarmBootManager backGroundAliveTime] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground || [UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
                [self.dataCache.copy enumerateKeysAndObjectsUsingBlock:^(BDPUniqueID * _Nonnull uniqueID, id  _Nonnull data, BOOL * _Nonnull stop) {
                    BOOL isBackgroundAudioWorking = NO;
                    if ([uniqueID respondsToSelector:@selector(isBackgroundAudioWorking)] ) {
                        if ([uniqueID performSelector:@selector(isBackgroundAudioWorking)]) {
                            isBackgroundAudioWorking = YES;
                        }
                    }
                    // 如果清理配置逻辑配置了白名单，切后台就不应清理
                    BOOL isWhiteConfig = [self isWhiteForUniqueId:uniqueID];
                    NSString *appIdStr = BDPSafeString(uniqueID.appID);
                    if(isWhiteConfig) {
                        BDPGadgetLogInfo(@"applicationEnterBackground appId:%@, isAudioWorking:%@, isWhiteConfig:%@",appIdStr, @(isBackgroundAudioWorking), @(isWhiteConfig));
                    }
                    
                    //配置为 enableAutoDestroy false的也不能清理，当前Tab小程序配置为false
                    if (![self.uniqueIdInFront containsObject:uniqueID] && !isBackgroundAudioWorking && [self isAutoDestroyEnableWithUniqueID:uniqueID] && !isWhiteConfig) {
                        [self cleanCacheWithUniqueID:uniqueID];
                    }
                }];
            }
        });
    }
}

+ (BOOL)isBackGroundKillEnable
{
    return [BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSABTestBackGroundKillEnable];
}

+ (NSInteger)backGroundAliveTime
{
    NSInteger aliveTime = [BDPSettingsManager.sharedManager s_integerValueForKey:kBDPSABTestBackGroundAliveTime];
    return aliveTime>0?aliveTime:5;
}

- (void)releaseResidentObject:(NSTimer *)timer {
    if (timer == nil) {
        return;
    }
    
    NSDictionary *dic = [timer userInfo];
    BDPUniqueID *uniqueID = [dic bdp_objectForKey:BDP_WARMBOOT_DIC_UNIQUEID ofClass:[BDPUniqueID class]];
    if ([uniqueID respondsToSelector:@selector(isBackgroundAudioWorking)] && [uniqueID performSelector:@selector(isBackgroundAudioWorking)]) {
        return;
    }
    // 当配置了保活,那么就需要以小程序的配置为准,直接开始回收
    if ([PageKeeperManagerOCBridge larkKeepAliveEnable]) {
        BOOL configedWhite = [dic bdp_boolValueForKey2:BDP_WARMBOOT_DIC_CONFIG_WHITE];
        if (!configedWhite && [PageKeeperManagerOCBridge isPageCachedWithUniqueId:uniqueID]) {
            // 当主端保活队列里包含应用的保活信息，那么由主端触发回收
            BDPGadgetLogInfo(@"releaseResidentObject rejected for lark keep alive %@",uniqueID.appID);
            return;
        }
    }
    
    [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:uniqueID];
}

#if ALPHA
///额外增加手动触发，是因为TTLeaksFinder的检查机制不会在 容器置空的时候触发，没有swizzle该方法，一般pop 等可触发
///手动触发TTLeaksFinder的内存检查，pod引入在lark主工程，因此想调试只能在主工程进行
///if alpha 指代debug和in-house环境，debug下TTLeaksFinder 默认不启用，因此只有in-house包会进行检查，结果查看链接： https://t.wtturl.cn/dcdx6Vf/
-(void)manuCheckLeaks:(NSObject *)obj{
    if (!obj) {
        return ;
    }
    
    //[TTMLeaksFinder manualCheckRootObject:obj];
    Class ttleaksFinderClass = NSClassFromString(@"TTMLeaksFinder");
    if ([ttleaksFinderClass respondsToSelector:@selector(manualCheckRootObject:)]) {
        [ttleaksFinderClass performSelector:@selector(manualCheckRootObject:) withObject:obj];
    }
}
#endif


#pragma mark - LazyLoading

- (NSMapTable<BDPUniqueID *, BDPWarmBootCleaner> *)cleanerTable {
    if (!_cleanerTable) {
        _cleanerTable = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _cleanerTable;
}

@end


@implementation BDPWarmBootManager (Running)
- (BOOL)appIsRunning:(OPAppUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return NO;
    }

    BOOL isRunning = NO;
    for (OPAppUniqueID *aliveAppID in [BDPWarmBootManager sharedManager].aliveAppUniqueIdSet) {
        if ([aliveAppID.appID isEqualToString:uniqueID.appID] && (aliveAppID.appType == uniqueID.appType)) {
            isRunning = YES;
            break;
        }
    }

    return isRunning;
}
@end

@implementation BDPWarmBootManager (LarkKeepAlive)

- (BDPKeepAliveReason)shouldKeepAlive:(OPAppUniqueID *)uniqueID {
    // 后台播放 保留保活
    if ([uniqueID respondsToSelector:@selector(isBackgroundAudioWorking)] ) {
        if ([uniqueID performSelector:@selector(isBackgroundAudioWorking)]) {
            return BDPKeepAliveReasonBackgroundAudio;
        }
    }
    // 配置了白名单，保留保活
    BOOL isWhiteConfig = [self isWhiteForUniqueId:uniqueID];
    if (isWhiteConfig) {
        return BDPKeepAliveReasonWhiteList;
    }
    
    
    //配置为 enableAutoDestroy false的也不能清理，当前Tab小程序配置为false
    if ([self isAutoDestroyEnableWithUniqueID:uniqueID]) {
        return BDPKeepAliveReasonLaunchConfig;
    }
    return BDPKeepAliveReasonNone;
}
@end
