//
//  BDTracker.m
//  Applog
//
//  Created by bob on 2019/1/20.
//

#import "BDAutoTrack+Private.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMainBundle.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackLocalConfigService.h"
#import "RangersLog.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackBatchService.h"

#import "BDAutoTrackRegisterRequest.h"
#import "BDAutoTrackActivateRequest.h"
#import "BDAutoTrackSettingsRequest.h"
#import "BDAutoTrackDataCenter.h"

#import "BDAutoTrackMacro.h"
#import "BDAutoTrackReachability.h"
#import "BDAutoTrackBatchTimer.h"

#import "BDAutoTrackEventCheck.h"

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackH5Bridge.h"
#import "BDAutoTrackALinkActivityContinuation.h"
#import "BDAutoTrackNotifications.h"
#import "BDCommonDefine.h"

#if __has_include("WKWebView+AutoTrack.h")
#import "WKWebView+AutoTrack.h"
#endif

#import "BDAutoTrackEncryptionDelegate.h"
#import "RangersLog.h"
#import "RangersLogManager.h"

#import "BDAutoTrackApplication.h"
#import "BDAutoTrackDurationEvent.h"

#import "RangersLogManager.h"
#import "BDroneMonitorAgent.h"
#import "RangersConsoleLogger.h"

#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrackEventGenerator.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDAutoTrackSchemeHandler.h"
#import "BDAutoTrackIdentifier.h"
#import "BDTrackerErrorBuilder.h"

@interface BDAutoTrack ()<BDAutoTrackService> {
    dispatch_queue_t eventQueue;
    void* onEventQueueTag;
    
}

@property (nonatomic, strong) NSLock *syncLocker;

@property (nonatomic, strong) BDAutoTrackConfig *config;

@property (nonatomic, strong) BDAutoTrackEventGenerator *eventGenerator;

@property (nonatomic, strong) BDAutoTrackNetworkManager *networkManager;

@property (nonatomic, strong) BDroneMonitorAgent *monitorAgent;
@property (nonatomic, strong) RangersLogManager *logger;
@property (nonatomic, strong) BDAutoTrackABConfig *abTester;

@property (nonatomic, strong) BDAutoTrackRemoteSettingService *remoteConfig;


@property (class, nonatomic, strong) id<BDAutoTrackEncryptionDelegate> bdEncryptor;

@property (nonatomic, strong) NSMutableSet *ignoredPageClasses;
@property (nonatomic, strong) NSMutableSet *ignoredClickViewClasses;

@property (nonatomic, copy) NSString* appID;
@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, assign) BOOL showDebugLog;
@property (nonatomic, assign) BOOL gameModeEnable;
@property (nonatomic) BOOL clearABCacheOnUserChange;
@property (nonatomic, strong) BDAutoTrackDataCenter *dataCenter;
@property (atomic, strong) BDAutoTrackRegisterRequest *registerRequest;
@property (atomic, strong) BDAutoTrackActivateRequest *activateRequest;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL servicesRegistered;

@property (nonatomic, strong) BDAutoTrackLocalConfigService *localConfig;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, copy) BDAutoTrackEventPolicy (^eventHandler)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties);
@property (nonatomic, assign) NSUInteger eventHandlerTypes;

@property (nonatomic, copy) void(^eventBlock)(BDAutoTrackEventStatus eventStatus, BDAutoTrackEventAllType eventType, NSString *eventName, NSDictionary<NSString *, id> *properties);

/// ALink Owner
@property (nonatomic, strong) BDAutoTrackALinkActivityContinuation *alinkActivityContinuation API_UNAVAILABLE(macos);

/* 是否开启ALink的延迟场景。初始化时从 config 上同步。 */
@property (nonatomic, assign) BOOL enableDeferredALink;

@property (nonatomic, strong) BDAutoTrackDurationEventManager *durationEventManager;

/*! @abstract Define custom encryption method (or custom encryption key)
 @discussion SDK不持有该对象。传入前须确保该对象在SDK使用期间不被释放，请勿传入临时对象。
 SDK will not hold the delegate. Please ensure the delegate's liveness during SDK's usage. Do not pass temporary object.
 */
@property (nonatomic, weak) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

@property (nonatomic, strong) BDAutoTrackIdentifier *identifier;

@property (nonatomic, strong) id registerRequestObserver;

@end

@implementation BDAutoTrack

+ (NSString *)SDKVersion {
    NSString *SDKVersion = [NSString stringWithFormat:@"%zd.%zd.%zd", BDAutoTrackerSDKMajorVersion, BDAutoTrackerSDKMinorVersion, BDAutoTrackerSDKPatchVersion];
    return SDKVersion;
}

+ (void)initialize
{
    Class encryptorCls = NSClassFromString(@"BDAutoTrackEncryptor");
    if (encryptorCls) {
        self.bdEncryptor = [[encryptorCls alloc] init];
    }
}

static id<BDAutoTrackEncryptionDelegate> gEncryptor;
+ (void)setBdEncryptor:(id<BDAutoTrackEncryptionDelegate>)encryptor
{
    gEncryptor = encryptor;
}

+ (id<BDAutoTrackEncryptionDelegate>)bdEncryptor
{
    return gEncryptor;
}

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config {

    CFTimeInterval current = CFAbsoluteTimeGetCurrent();  // 初始化计时开始
    
    self = [self initWithAppID:config.appID];
    if (self) {
    
        self.config = config;
        
        if (config.devToolsEnabled) {
            Class devTools = NSClassFromString(@"BDAutoTrackDevTools");
            if (devTools) {
                SEL installSEL =   NSSelectorFromString(@"install:");
                IMP installIMP = [devTools methodForSelector:installSEL];
                if (installIMP) {
                    id (*devToolsInstall)(id, SEL, id) = (void *)installIMP;
                    devToolsInstall(devTools, installSEL, self);
                }
            }
        }
        
        self.logger = [RangersLogManager new];
        self.logger.tracker = self;
        if (config.showDebugLog) {
            self.logger.logLevel = VETLOG_LEVEL_DEBUG;
        }
        NSArray<Class> *loggerCls = [RangersLogManager registerLoggerClasses];
        [loggerCls enumerateObjectsUsingBlock:^(Class  _Nonnull logger, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.logger addLogger:[[logger alloc] init]];
        }];
        RL_DEBUG(self,@"Tracker",@"BDAutoTrack initWithConfig");
        
        
        self.identifier = [[BDAutoTrackIdentifier alloc] initWithTracker:self];
        self.identifier.serviceVendor = config.serviceVendor;
        if (config.newUserMode) {
            self.identifier.mockEnabled = YES;
            [self.identifier clearIDs];
        }
        
        self.networkManager = [BDAutoTrackNetworkManager managerWithTracker:self];
        
        BDAutoTrackNetworkEncryptor *encryptor = [BDAutoTrackNetworkEncryptor new];
        encryptor.encryptionType = config.encryptionType;
        if (config.logNeedEncrypt) {
            encryptor.encryption = YES;
        }
        if (config.encryptionDelegate) {
            encryptor.customDelegate = config.encryptionDelegate;
        }
        self.networkManager.encryptor = encryptor;
        
        
        if (config.serviceVendor == BDAutoTrackServiceVendorPrivate) {
            config.monitorEnabled = NO;
        }
        if (config.monitorEnabled) {
            self.monitorAgent = [BDroneMonitorAgent agentWithTracker:self];
            [self.monitorAgent presetAggregation];
        }
        
        self.syncLocker = [NSLock new];
        self.ignoredPageClasses = [NSMutableSet new];
        self.ignoredClickViewClasses = [NSMutableSet new];
        self.started = NO;  // 初始化为NO, startTrack中置为YES。 从而保证同一个BDAutoTrack实例不会startTrack两次。
        self.gameModeEnable = config.gameModeEnable;
        
        // 创建队列
        NSString *appID = config.appID;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.track_%@", appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        // 创建时长统计管理
        self.durationEventManager = [BDAutoTrackDurationEventManager createByAppId:appID];
        
        // 设置 Debug Log
        self.showDebugLog = config.showDebugLog;

        
        
        // 设置H5 Bridge
        if (config.enableH5Bridge) {
            [[BDAutoTrackH5Bridge sharedInstance] swizzleWKWebViewMethodForJSBridge];
        }
        
        self.clearABCacheOnUserChange = config.clearABCacheOnUserChange;
        
        if (config.H5AutoTrackEnabled) {
            if ([WKWebView respondsToSelector:@selector(swizzleForH5AutoTrack)]) {
                [WKWebView performSelector:@selector(swizzleForH5AutoTrack)];
            }
        }
        
        // 先初始化dataCenter，避免startTrack之前用户调用 eventV3
        BDAutoTrackDataCenter *dataCenter = [[BDAutoTrackDataCenter alloc] initWithAppID:appID associatedTrack:self];
        dataCenter.showDebugLog = config.showDebugLog;
        self.dataCenter = dataCenter;
        
        // BDAutoTrack实例是一个service
        self.serviceName = BDAutoTrackServiceNameTracker;
        // 注册到服务中心，以后可以通过服务中心获取到BDAutoTrack实例
        [[BDAutoTrackServiceCenter defaultCenter] registerService:self];
        
        // 启动环境状态变化检测｜网络
        
        BDAutoTrackEventGenerator *generator = [BDAutoTrackEventGenerator generatorForTrack:self];
        self.eventGenerator = generator;

#if TARGET_OS_IOS
        
        // 初始化 Alink（之前是延迟初始化，由于在子线程上报中会读取alink参数，存在并发问题，所以这里提前初始化）
        self.alinkActivityContinuation = [[BDAutoTrackALinkActivityContinuation alloc] initWithAppID:self.appID];
        self.enableDeferredALink = config.enableDeferredALink;
        /* 当是应用生命周期首次启动，且是直接点击按钮启动时，执行延迟深度链接 */
        
        //曝光
        Class clz = NSClassFromString(@"BDAutoTrackExposureManager");
        SEL instanceSEL =   NSSelectorFromString(@"sharedInstance");
        IMP instanceIMP = [clz methodForSelector:instanceSEL];
        if (instanceIMP) {
            id (*sharedInstance)(id, SEL) = (void *)instanceIMP;
            id manager = sharedInstance(clz,instanceSEL);
            SEL startSEL = NSSelectorFromString(@"startWithTracker:");
            IMP startIMP = [manager methodForSelector:startSEL];
            if (startIMP) {
                void (*startWithTracker)(id, SEL, id) = (void *)startIMP;
                startWithTracker(manager,startSEL,self);
            }
        }
        
#endif
        
        self.encryptionDelegate = config.encryptionDelegate;
        
        /*
         *  LocalSetting processed synchronously in the initialization thread
         *  fengchengqi @ 2022-01-11
         */
        BDAutoTrackLocalConfigService *localSettings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
        [localSettings registerService];
        localSettings.enableH5Bridge = config.enableH5Bridge;
        localSettings.H5BridgeDomainAllowAll = config.H5BridgeDomainAllowAll;
        localSettings.H5BridgeAllowedDomainPatterns = config.H5BridgeAllowedDomainPatterns;
        if ([[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch] && localSettings.syncUserUniqueID == nil) {
//            localSettings.userUniqueID = config.initialUserUniqueID;
            [localSettings updateUser:config.initialUserUniqueID type:config.initialUserUniqueIDType ssid:nil];
        }
        
        self.localConfig = localSettings;
        
        BDAutoTrackRemoteSettingService *remote = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:appID];
        [remote registerService];
        self.remoteConfig = remote;
         
        BDAutoTrackABConfig *abTester = [[BDAutoTrackABConfig alloc] initWithAppID:appID];
        abTester.tracker = self;
        [abTester registerService];
        abTester.localTesterEnabled = config.abEnable;
        abTester.remoteTesterEnabled = remote.abTestEnabled;
        abTester.fetchInterval = remote.abFetchInterval;
        self.abTester = abTester;
        
        // 采集 exception
        if (config.trackCrashEnabled) {
            Class clz = NSClassFromString(@"BDAutoTrackExceptionTracer");
            if (clz) {
                SEL instanceSEL =   NSSelectorFromString(@"shared");
                IMP instanceIMP = [clz methodForSelector:instanceSEL];
                if (instanceIMP) {
                    id (*shared)(id, SEL) = (void *)instanceIMP;
                    id exceptionTracer = shared(clz,instanceSEL);
                    SEL startSEL = NSSelectorFromString(@"start");
                    IMP startIMP = [exceptionTracer methodForSelector:startSEL];
                    if (startIMP) {
                        void (*start)(id, SEL) = (void *)startIMP;
                        start(exceptionTracer,startSEL);
                    }
                }
            }
        }
        
    } // if (self)
    
    CFTimeInterval sdkInitDuration = CFAbsoluteTimeGetCurrent() - current;  // 初始化计时结束
    [self.monitorAgent trackMetrics:BDroneUsageInitialization value:@(sdkInitDuration*1000) category:BDroneUsageCategory dimensions:@{}];
    return self;
}

#pragma mark - service 协议

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = [appID mutableCopy];
        bd_run_in_main_thread(^{
            [BDAutoTrackSessionHandler sharedHandler];
            [BDAutoTrackApplication shared];
        });
        
        Class cls_BDAutoTrackASA = NSClassFromString(@"BDAutoTrackASA");
        if (cls_BDAutoTrackASA && [cls_BDAutoTrackASA respondsToSelector:@selector(start)] &&
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch]) {
            [cls_BDAutoTrackASA performSelector:@selector(start)]; // RegisterRequest expects we get ASA attribution as soon as possible
        }
    }
    return self;
}

- (void)registerService {
}

- (BOOL)serviceAvailable {
    return YES;
}

- (void)unregisterService {
}

#pragma mark - 启动SDK

+ (instancetype)trackWithConfig:(BDAutoTrackConfig *)config {
    
    
    NSString *appID = config.appID;
    if (![appID isKindOfClass:[NSString class]] || appID.length < 1) {
        return nil;
    }
    
    BDAutoTrack *tracker = [self trackWithAppID:appID];
    if (tracker == nil || ![tracker isKindOfClass:[BDAutoTrack class]]) {
        tracker = [[BDAutoTrack alloc] initWithConfig:config];
    }
    return tracker;
}

/// 从缓存获取已有的tracker实例
+ (instancetype)trackWithAppID:(NSString *)appID {
    return [[BDAutoTrackServiceCenter defaultCenter] serviceForName:BDAutoTrackServiceNameTracker appID:appID];
}

- (void)startTrack {
    if (self.started) {
        return;
    }
    RL_DEBUG(self,@"Tracker",@"BDAutoTrack startTrack");
    self.started = YES;
    
    [[BDAutoTrackEnviroment sharedEnviroment] startTrack];
    [self.abTester start];
    
    if (self.config.monitorEnabled) {
        [self.monitorAgent upload];
    }

    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *appID = self.appID;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:) name:BDAutoTrackNotificationRegisterSuccess object:nil];
    
    
    BDAutoTrackWeakSelf;
    
    self.registerRequestObserver = [NSNotificationCenter.defaultCenter addObserverForName:BDAutoTrackNotificationRegisterSuccess object:nil queue:nil usingBlock:^(NSNotification * _Nonnull noti) {
        /* 延迟归因请求依赖设备注册服务。首启无缓存，需阻塞等待设备注册完成。 */
        NSString *appId = self.appID;
        NSString *notiAppId = noti.userInfo[@"AppID"];
        if (![appId isEqualToString:notiAppId]) {
            return;
        }
        
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
        //ALink
        if (tracker.config.enableDeferredALink &&
            tracker.config.launchOptions == nil &&
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch]) {
            if ([noti.userInfo[kBDAutoTrackNotificationDataSource] isEqualToString:BDAutoTrackNotificationDataSourceServer]) {
                [self.alinkActivityContinuation continueDeferredALinkActivityWithRegisterUserInfo:noti.userInfo];

            }
        }

        if (tracker.config.launchOptions) {
            NSURL* url = [tracker.config.launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
            if ([url.scheme hasPrefix:@"rangersapplog"]) {
                RL_INFO(tracker, @"OPEN_URL", @"handle LaunchOptions URL %@", url.absoluteString);
                [[BDAutoTrackSchemeHandler sharedHandler] handleURL:url appID:tracker.config.appID scene:nil];
            }
        }
        
        if (self.registerRequestObserver) {
            [NSNotificationCenter.defaultCenter removeObserver:self.registerRequestObserver name:BDAutoTrackNotificationRegisterSuccess object:nil];
            self.registerRequestObserver = nil;
        }
    }];

    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        
        wself.registerRequest = [[BDAutoTrackRegisterRequest alloc] initWithAppID:appID
                                                                            next:wself.config.autoFetchSettings ? [[BDAutoTrackSettingsRequest alloc] initWithAppID:appID next:nil] : nil];
        wself.activateRequest = [[BDAutoTrackActivateRequest alloc] initWithAppID:appID next:nil];
        
        BDAutoTrackRegisterService *registerServ = [[BDAutoTrackRegisterService alloc] initWithAppID:appID];
        [registerServ registerService];
        
        
        wself.servicesRegistered = YES;
        
        // 冷启动上报一次Profile事件
        [wself.profileReporter sendProfileTrack];
        
        // 开始session。launch和terminate埋点入库。
        dispatch_async(dispatch_get_main_queue(), ^{
            [[BDAutoTrackSessionHandler sharedHandler] checkAndStartSession];
        });
        
        // 初始化埋点上报服务
        BDAutoTrackBatchService *batchService = [[BDAutoTrackBatchService alloc] initWithAppID:appID];
        [batchService registerService];
        
        // 发送注册请求
        [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
        
        
        
        
    });
    CFTimeInterval duration = CFAbsoluteTimeGetCurrent() - startTime;  // 初始化计时结束
    [self.monitorAgent trackMetrics:BDroneUsageStartup value:@(duration*1000) category:BDroneUsageCategory dimensions:@{}];
    
}

- (void)onRegisterSuccess:(NSNotification *)noti
{
    NSString *appId = noti.userInfo[@"AppID"];
    
    if ([self.appID isEqualToString:appId]) {
        BDAutoTrackWeakSelf;
        dispatch_async(self.serialQueue, ^{
            BDAutoTrackStrongSelf;
            [self.profileReporter sendProfileTrack];
        });
        
    }
}

- (void)setUserAgent:(NSString *)userAgent {
    dispatch_async(self.serialQueue, ^{
        [self.localConfig saveUserAgent:[userAgent mutableCopy]];
    });
}

- (BOOL)setCurrentUserUniqueID:(NSString *)uniqueID {
    
    return [self setCurrentUserUniqueID:uniqueID withType:nil];
}

- (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID withType:(nullable NSString *)type
{
    NSString *oldUniqueID = self.localConfig.syncUserUniqueID;
    NSString *oldUniqueIDType = self.localConfig.syncUserUniqueIDType;
    
    BOOL isUniqueIDChange = YES;
    BOOL isUniqueIDTypeChange = YES;
    if ((uniqueID.length == 0 && oldUniqueID.length == 0) || [oldUniqueID isEqualToString:uniqueID]) {
        isUniqueIDChange = NO;
    }
    if ((type.length == 0 && oldUniqueIDType.length == 0) || [oldUniqueIDType isEqualToString:type]) {
        isUniqueIDTypeChange = NO;
    }
    if (!isUniqueIDChange && !isUniqueIDTypeChange) {
        return NO;
    }
    
    
    if (self.started) { //未启动不会
        [[BDAutoTrackSessionHandler sharedHandler] onUUIDChanged];
    }
    [self.localConfig updateUser:uniqueID type:type ssid:@""];
    bd_registerServiceForAppID(self.appID).ssID = @"";
    BOOL isAnonymousUser = oldUniqueID == nil;
    
    if (self.clearABCacheOnUserChange && !isAnonymousUser) {
        [self.abTester clearAll];
    }
    
    if (self.started) {
        [[BDAutoTrackSessionHandler sharedHandler] createUUIDChangeSession];
    }

//    NSLog(@"[ABTesting] -> %@", uniqueID );
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        [self impl_setUserUniqueID:uniqueID oldUserUniqueID:oldUniqueID];
        /* 重置首次启动判断状态机。下一次launch事件将携带 "$is_first_time": "true" 事件参数上报 */
        if (uniqueID.length > 0) {
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] refreshIsUserFirstLaunch];
        }
    });
    
    return YES;
}

- (void)clearUserUniqueID {
    
    [self setCurrentUserUniqueID:nil withType:nil];
    
}

/// 注册操作的请求链
/// register -> settings -> nil
/// activate -> nil
/// activate请求在初始化时会观察BDAutoTrackNotificationRegisterSuccess, 在观察的回调中发起激活请求。
/// @param registeringUserUniqueID 要注册的UserUniqueID。若为nil，则使用LocalConfig中的UserUniqueID。
- (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(NSString *)registeringUserUniqueID {
    // 没有启动的状态下，什么也不做。
    if (!self.started) {
        return NO;
    }
    
    if (!registeringUserUniqueID) {
        registeringUserUniqueID = self.localConfig.syncUserUniqueID;
    }
    self.registerRequest.registeringUserUniqueID = [registeringUserUniqueID copy];
    
    CFTimeInterval current = CFAbsoluteTimeGetCurrent();
    self.registerRequest.startTime = current;
    self.activateRequest.startTime = current;
    
    [self.registerRequest startRequestWithRetry:3];
    
    return YES;
}

- (BOOL)sendRegisterRequest {
    return [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
}

- (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor {
    NSString *appID = self.appID;
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        BDAutoTrackLocalConfigService *settings = self.localConfig;
        BDAutoTrackServiceVendor old = settings.serviceVendor;
        if (old != serviceVendor) {
            RL_DEBUG(self.appID, @"update service vendoer. (%@ -> %@)", old, serviceVendor);
            settings.serviceVendor = serviceVendor;
            bd_registerReloadParameters(appID);
            [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
        }
    });
}

#pragma mark - set Blocks
- (void)setRequestURLBlock:(BDAutoTrackRequestURLBlock)requestURLBlock {
    BDAutoTrackRequestURLBlock block = [requestURLBlock copy];
    dispatch_async(self.serialQueue, ^{
        self.localConfig.requestURLBlock = block;
    });
}

- (void)setRequestHostBlock:(BDAutoTrackRequestHostBlock)requestHostBlock {
    BDAutoTrackRequestHostBlock block = [requestHostBlock copy];
    dispatch_async(self.serialQueue, ^{
        self.localConfig.requestHostBlock = block;
    });
}

- (void)setCommonParamtersBlock:(nullable BDAutoTrackCommonParamtersBlock)commonParamtersBlock {
    BDAutoTrackCommonParamtersBlock block = [commonParamtersBlock copy];
    dispatch_async(self.serialQueue, ^{
        self.localConfig.commonParamtersBlock = block;
    });
}

- (void)setCustomHeaderValue:(nullable id)value forKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{

        if (self.showDebugLog) {
            bd_checkCustomHeader(self, key, value);
        }
        BDAutoTrackLocalConfigService *s = self.localConfig;
        [s setCustomHeaderValue:value forKey:key];
    });
}

- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    dispatch_async(self.serialQueue, ^{

        if (self.showDebugLog) {
            bd_checkCustomDictionary(self, dictionary);
        }
        BDAutoTrackLocalConfigService *s = self.localConfig;
        [s setCustomHeaderWithDictionary:dictionary];
    });
}

- (void)removeCustomHeaderValueForKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{
        if (self.showDebugLog) {
            bd_checkCustomHeaderKey(self, key);
        }
        BDAutoTrackLocalConfigService *s = self.localConfig;
        [s removeCustomHeaderValueForKey:key];
    });
}

- (void)setCustomHeaderBlock:(BDAutoTrackCustomHeaderBlock)customHeaderBlock {
    BDAutoTrackCustomHeaderBlock block = [customHeaderBlock copy];
    dispatch_async(self.serialQueue, ^{
        self.localConfig.customHeaderBlock = block;
    });
}

- (void)setActiveCustomParamsBlock:(NSDictionary<NSString *,id> * (^)(void))customParamsBlock;
{
    self.localConfig.activeCustomParamsBlock = customParamsBlock;
}

#pragma mark - 埋点上报
- (BOOL)eventV3:(NSString *)event {
    return [self eventV3:event params:nil];
}

- (BOOL)eventV3:(NSString *)event params:(NSDictionary *)params {

    NSString *appID = self.appID;
    if (self.showDebugLog) {
        bd_checkEvent(self, event, params);
    }
    NSDictionary *trackData = @{kBDAutoTrackEventType:[event mutableCopy],
                                kBDAutoTrackEventData:[[NSDictionary alloc] initWithDictionary:params copyItems:YES]};
    
    if (self.config.rollback) {
        [self.dataCenter trackUserEventWithData:trackData];
    } else {
        [self.eventGenerator trackEvent:event parameter:params options:nil];
    }
    
    
    return YES;
}





#pragma mark - setEventHandler

- (void)setEventHandler:(BDAutoTrackEventPolicy (^)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties))handler
               forTypes:(BDAutoTrackDataType)types
{
    if (!handler) {
        return;
    }
    self.eventHandlerTypes = types;
    self.eventHandler = [handler copy];
    
}


#pragma mark - App

- (void)setAppRegion:(NSString *)appRegion {
    NSString *region = [appRegion copy];
    dispatch_async(self.serialQueue, ^{
        [self.localConfig saveAppRegion:region];
    });
}

- (void)setAppLauguage:(NSString *)appLauguage {
    NSString *language = [appLauguage copy];
    dispatch_async(self.serialQueue, ^{
        [self.localConfig saveAppLauguage:language];
    });
}

#pragma mark - ABTest

- (id)ABTestConfigValueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return [self.abTester getConfig:key defaultValue:defaultValue];
}
- (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue {
    return [self ABTestConfigValueForKey:key defaultValue:defaultValue];
}

- (void)setExternalABVersion:(NSString *)versions {
    
    [self.abTester setExternalVersions:versions];
}

- (NSString *)abVids {
    return [self.abTester allABVersions];
}
- (NSString *)abVidsSync {
    return [self abVids];
}

- (NSString *)allAbVids {
    return [self.abTester allABVersions];
}
- (NSString *)allAbVidsSync {
    return [self allAbVids];
}

- (nullable NSString *)abExposedVids {
    return [self.abTester testerABVersions];
}

- (NSDictionary *)allABTestConfigs {
    return [self.abTester allABTestConfigs];
}
- (NSDictionary *)allABTestConfigsSync {
    return [self allABTestConfigs];
}

- (NSDictionary *)allABTestConfigs2 {
    NSDictionary *_ = [self.abTester allABTestConfigs2];
    return _;
}

/// 手动触发拉取 ABConfig 更新
/// 频控，默认10s内最多调用一次
- (void)pullABTestConfigs {
    [self.abTester fetchABTestingManually:10.0f completion:^(BOOL success, NSError * _Nullable error) {
    }];
}

- (void)pullABTestConfigs:(NSTimeInterval)timeout
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
{
    if (!self.abTester) {
        completion(NO, [NSError errorWithDomain:@"VOLC_ENGINE_ERROR" code:0 userInfo:@{NSLocalizedDescriptionKey:@"initialization not completed."}]);
        return;
    }
    [self.abTester fetchABTestingManually:timeout completion:completion];
}

#pragma mark - ALink

#if TARGET_OS_IOS
- (BDAutoTrackALinkActivityContinuation *)alinkActivityContinuation {
    if (!_alinkActivityContinuation) {
        _alinkActivityContinuation = [[BDAutoTrackALinkActivityContinuation alloc] initWithAppID:self.appID];
    }
    return _alinkActivityContinuation;
}

- (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate {
    if (!self.enableDeferredALink && [ALinkRoutingDelegate respondsToSelector:@selector(onAttributionData:error:)]) {
        RL_WARN(self,@"[ALink]",@"please impl @selector(onAttributionData:error:");
    }
    [self.alinkActivityContinuation setRoutingDelegate:ALinkRoutingDelegate];
}

- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    return [self.alinkActivityContinuation continueALinkActivityWithURL:ALinkURL];
}

#endif


#pragma mark - Location

+ (void)setGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude {
    [[BDAutoTrackApplication shared] updateGPSLocation:geoCoordinateSystem longitude:longitude latitude:latitude];
}


#pragma mark - DurationEvent

- (void)startDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager startDurationEvent:eventName startTimeMS:nowTimeMS];
    });
}

- (void)pauseDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager pauseDurationEvent:eventName pauseTimeMS:nowTimeMS];
    });
}

- (void)resumeDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager resumeDurationEvent:eventName resumeTimeMS:nowTimeMS];
    });
}

- (void)stopDurationEvent:(NSString *)eventName properties:(NSDictionary *)properties {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackDurationEvent *durationEvent = [self.durationEventManager stopDurationEvent:eventName stopTimeMS:nowTimeMS];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data addEntriesFromDictionary:properties];
        [data setValue:@(durationEvent.duration) forKey:kBDAutoTrackEventDuration];
        NSDictionary *trackData = @{
            kBDAutoTrackEventType: eventName,
            kBDAutoTrackEventData: data,
        };
        if (self.config.rollback) {
            [self.dataCenter trackUserEventWithData:trackData];
        } else {
            [self.eventGenerator trackEvent:eventName parameter:data options:nil];
        }
        
    });
}


#pragma mark - 获取设备注册信息
- (NSString *)rangersDeviceID {
    return [bd_registerRangersDeviceID(self.appID) mutableCopy];
}

- (NSString *)installID {
    return [bd_registerinstallID(self.appID) mutableCopy];
}

- (NSString *)ssID {
    return bd_registerSSID(self.appID);
}

/* 获取LocalConfig服务信息 */
- (NSString *)userUniqueID {
    return self.localConfig.syncUserUniqueID;
}


#pragma mark - Flush

- (void)flush
{
    [self flushWithTimeInterval:10.0f];
}

#pragma mark - clearAllEvent
- (void)clearAllEvent
{
    [self.dataCenter clearDatabase];
}

#pragma mark - private API

- (void)activeUser {
    self.activateRequest.needActiveUser = YES;
    [self.activateRequest startRequestWithRetry:1];
}

/// 设置UserUniqueID的实现。需要重新发送注册、激活、Settings请求。
/// @param uniqueID user unique ID
- (void)impl_setUserUniqueID:(NSString *)uniqueID oldUserUniqueID:(NSString *)oldUniqueID {
    BOOL isAnonymousUser = oldUniqueID == nil;
    
    if (self.clearABCacheOnUserChange && !isAnonymousUser) {
        [self.abTester clearAll];
    }
    
    /* clear $tr_web_ssid */
    BDAutoTrackLocalConfigService *localConfigService = self.localConfig;
    [localConfigService removeCustomHeaderValueForKey:kBDAutoTrack__tr_web_ssid];
    
    /* 4.2 Send register reuqest using the new UserUniqueID
     * 在注册请求返回前，存在一个窗口，窗口时间为注册请求的TTL。这个窗口中的事件为旧SSID/新UUID；且AB Versions也是旧用户的AB。
     */
    [self sendRegisterRequestWithRegisteringUserUniqueID:uniqueID];
}


- (NSString *)applicationId
{
    return self.appID;
}

- (BOOL)registerAvalible
{
    return bd_registerServiceAvailableForAppID(self.appID);
}

@end
