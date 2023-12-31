//
//  BDBDQuaterback.m
//  AWECloudCommand
//
//  Created by hopo on 2019/11/17.
//

#import <pthread/pthread.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <Brady/BDBrady.h>

#import "BDBDQuaterback.h"
#import "BDDYCMacros.h"
#import "BDDYCSecurity.h"
#import "BDDYCModuleModel.h"
#import "BDDYCDownloader.h"
#import "BDDYCModuleManager.h"
#import "BDDYCURL.h"
#import "BDDYCMonitor.h"
#import "BDDYCUtils.h"
#import "BDBDModule.h"
#import "BDDYCURL.h"
#import "BDDYCErrCode.h"
#import "BDDYCEngineHeader.h"
#import "BDBDQuaterback+Internal.h"

NSString * const BDDYCErrorDomain = @"com.dyc_module.error.domain";
extern NSString *const kBDQuaterbackLastReportListTimeKey;
NSString *const kCurrentAppName = @"kCurrentAppName";
extern NSString *const kCurrentChannel;
extern NSString *const kCurrentAppVersion;
extern NSString *const kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName;
extern NSString *const kBDDQuaterbackDidFetchList;
extern NSString *const kBDDYQuaterbackListDownloadStatusMonitorServiceName;
extern NSString *const kBDDQuaterbackFetchListKey;
extern NSString *const kBDDYCQuaterbackDAU;
extern NSString *const kBDDYCQuaterbackInjectedInfoKey;
/**
 国内服务域名
 */
NSString * const kBDDYCDefaultCNDomain = @"security.snssdk.com";
//static NSString * const kBDDYCDefaultCNDomain = @"10.224.10.61:45639";
/**
 阿里新加坡服务域名
 */
NSString * const kBDDYCDefaultSGDomain = @"moss-sg.snssdk.com";
/**
 阿里美东服务域名
 */
NSString * const kBDDYCDefaultVADomain = @"moss-va.snssdk.com";


static NSString *const kAWEZephyrLoadedKey = @"better_info";
static NSString *const kAWEZephyrLoadedVersionKey = @"better_ver";

using namespace bdlli;

//#define BDBDModuleLoadManager AWECFLoadManager
#if BDAweme
__attribute__((objc_runtime_name("AWECFLoadManager")))
#endif
@interface BDBDModuleLoadManager : NSObject

+ (instancetype)shared;
- (void)add:(NSString*)version;
- (NSString*)current;

@end

@implementation BDBDModuleLoadManager {
    NSMutableArray * _versions;
}

+ (instancetype)shared {
    static BDBDModuleLoadManager *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[BDBDModuleLoadManager alloc] init];
    });
    return obj;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _versions = [[NSMutableArray alloc] initWithCapacity:2];
    }
    return self;
}

- (void)add:(NSString*)version {
    @synchronized (self) {
        [_versions addObject:version];
        [_versions sortUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1,NSString*  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
    }
}

- (NSString*)current {
    NSMutableString *str = [[NSMutableString alloc] init];
    @synchronized (self) {
        for (NSString * version in _versions) {
            [str appendString:version];
            [str appendString:@","];
        }
    }
    return str;
}

@end



#pragma mark - BDBDConfiguration

@interface BDQBConfiguration ()
@property (nonatomic, copy, readwrite) NSString *deviceId;
@property (nonatomic, copy, readwrite) NSString *installId;
@end

@implementation BDQBConfiguration

- (instancetype)init
{
    if ((self = [super init])) {
        _distArea = kBDDYCDeployAreaCN;
        _enableEnterForegroundRequest = YES;
        _requestType = kBDQBRequestTypeTTNet;
    }
    return self;
}

#pragma mark -

- (NSString *)aid
{
    return _aid ? : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SSAppID"];
}

- (NSString *)deviceId
{
    return (_deviceId ? : (_getDeviceIdBlock ? (_deviceId = _getDeviceIdBlock()) : nil));
}

- (NSString *)installId
{
    return (_installId ? : (_getInstallIdBlock ? (_installId = _getInstallIdBlock()) : nil));
}

- (NSString *)channel
{
    return _channel ? : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CHANNEL_NAME"];
}

- (NSString *)appVersion
{
    return _appVersion ? : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)appBuildVersion
{
//    if (_appBuildVersion) return _appBuildVersion;
//    NSString *buildVersionCode = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
//    if ([buildVersionCode rangeOfString:@"."].location == NSNotFound) {
//        buildVersionCode = [NSString stringWithFormat:@"%@.%@", self.appVersion, buildVersionCode];
//    }
    return _appBuildVersion ? : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)domainName
{
    if (_domainName) return _domainName;
    switch (_distArea) {
        case kBDDYCDeployAreaSG: {
            _domainName = kBDDYCDefaultSGDomain;
        } break;
        case kBDDYCDeployAreaVA: {
            _domainName = kBDDYCDefaultVADomain;
        } break;
        case kBDDYCDeployAreaCN:
        default: {
            _domainName = kBDDYCDefaultCNDomain;
        } break;
    }
    return _domainName;
}

- (NSDictionary *)commonParams
{
    return _commonNetworkParamsBlock ? [_commonNetworkParamsBlock() copy] : nil;
}

- (BOOL)isWifiReachable
{
    return _isWifiNetworkBlock ? _isWifiNetworkBlock() : NO;
}

@end

//
//@implementation BDBDQuaterback
//
//@end

#pragma mark - BDDYCMain

@interface BDBDQuaterback ()
{
    NSInteger _usingEngine;
    pthread_mutex_t _vmLock;
    pthread_mutex_t _initialLock;
    pthread_mutex_t _loadSuccessLock;
    pthread_mutex_t _loadedlazyModulesLock;
    pthread_mutex_t _taskSetLock;
}
@property (nonatomic, strong) dispatch_queue_t fetchListQueue;
@property (nonatomic, assign) BOOL willStartFetchList;
@property (nonatomic, assign) BOOL didStartSDK;
@property (nonatomic, strong) NSMutableDictionary *betterInfo;
@property (nonatomic, strong) NSMutableArray *loadedlazyModules;
@property (nonatomic, strong) NSMutableArray *loadedlazyDylibs;
@property (nonatomic, strong) NSMutableSet *taskSet;
@end

@implementation BDBDQuaterback

+ (instancetype)sharedMain
{
    static BDBDQuaterback *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
    });
    return sharedInst;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _usingEngine = BDDYCEngineUsingUndefined;
        __weak typeof(BDBDQuaterback *) weakSelf = self;
        _refreshStrategy = [[BDDYCUpdateStrategy alloc] initWithUpdateNotifier:^{
            __strong typeof(BDBDQuaterback *) strongSelf = weakSelf;
            if (strongSelf.conf.enableEnterForegroundRequest) {
                [BDBDQuaterback fetchServerData];
            }
        }];
        _fetchListQueue = dispatch_queue_create("come.bd.better.fetch.list", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishFetchQuaterbackList:) name:kBDDQuaterbackDidFetchList object:nil];
        self.willStartFetchList = NO;
        pthread_mutex_init(&_vmLock, NULL);
        pthread_mutex_init(&_initialLock, NULL);
        pthread_mutex_init(&_loadSuccessLock, NULL);
        pthread_mutex_init(&_loadedlazyModulesLock, NULL);
        pthread_mutex_init(&_taskSetLock, NULL);
//        _taskSetLock
//        _loadedlazyModulesLock
//        [[BDBradyEngine defaultEngine] setDelegate:self];

        _betterInfo = [NSMutableDictionary dictionary];
        _loadedlazyModules = [NSMutableArray array];
        _loadedlazyDylibs = [NSMutableArray array];
        _taskSet = [NSMutableSet set];

    }
    return self;
}

- (void)dealloc
{
    _refreshStrategy = nil;
}

- (void)lockVM {
    pthread_mutex_lock(&_vmLock);
}

- (void)unlockVM {
    pthread_mutex_unlock(&_vmLock);
}

- (void)lockInitial {
    pthread_mutex_lock(&_initialLock);
}

- (void)unlockInitial {
    pthread_mutex_unlock(&_initialLock);
}

- (void)lockLazyModules {
    pthread_mutex_lock(&_loadedlazyModulesLock);
}

- (void)unlockLazyModules {
    pthread_mutex_unlock(&_loadedlazyModulesLock);
}

- (void)lockTaskSet {
    pthread_mutex_lock(&_taskSetLock);
}

- (void)unlockTaskSet {
    pthread_mutex_unlock(&_taskSetLock);
}


- (void)didFinishFetchQuaterbackList:(NSNotification *)notification {
    [self lockInitial];
    self.willStartFetchList = NO;
    [self unlockInitial];
}

+ (void)startBrady
{
    [self handleOpenURL:[[BDDYCURL startDYCURL] toNSURL]];
}

+ (void)closeBrady
{
    [self handleOpenURL:[[BDDYCURL closeDYCURL] toNSURL]];
}

+ (void)fetchQuaterbacks
{
    [self handleOpenURL:[[BDDYCURL fetchDYCURL] toNSURL]];
}

#pragma mark -

+ (void)startWithConfiguration:(BDQBConfiguration *)conf
                      delegate:(id<BDQBDelegate>)delegate
{
    [BDBDQuaterback sharedMain].conf = conf;
    [BDBDQuaterback sharedMain].delegate = delegate;
    [[BDBDQuaterback sharedMain] startEngine:BDDYCEngineUsingBrady];
}

#pragma mark - start firstly

- (void)startEngine:(NSInteger)engineType
{
    BDDYCAssert(engineType != BDDYCEngineUsingUndefined &&
                "Please use BDDYCEngineUsingJSContext or BDDYCEngineUsingBrady to run");

    if ([self needLoadLocalQuaterbacks]) {
        // 2. load and execute local modules
        [self loadLocalAllModules];
    } else {
        [BDDYCModuleManager clearAllLocalQuaterback];
//        kBDDYCQuaterbackDidClearOldVersionQuaterbacksMonitorServiceName
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
        NSArray *patchs = [[BDDYCModuleManager sharedManager] allToLogModules];
        NSDictionary *data = @{@"betters":patchs?:@[],
                               @"timestamp":[NSNumber numberWithDouble:interval],
                               };
        [BDDYCMonitorGet() trackService:kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName status:kBDQuaterbackWillClearPatchsStatusUpgradeAppVersion  extra:data];
    }
    [self lockInitial];
    self.didStartSDK = YES;
    [self unlockInitial];

    // 3. fetch new modules and execute
    [self.class fetchServerData];

    //
    [BDDYCUtils updateAppInfoWithAppVersion:self.conf.appVersion channel:self.conf.channel];

    // log
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    long long milloSecondsInterval = [[NSNumber numberWithDouble:interval] longLongValue];
    NSNumber *timestamp = [NSNumber numberWithLongLong:milloSecondsInterval];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *patchs = [[BDDYCModuleManager sharedManager] allToLogModules];
        NSDictionary *data = @{@"timestamp":timestamp,
                               @"betters":patchs,
                               };
        [BDDYCMonitorGet() trackData:data];

        [[NSUserDefaults standardUserDefaults] setObject:timestamp forKey:kBDQuaterbackLastReportListTimeKey];
    });

}

- (BOOL)needLoadLocalQuaterbacks {
    NSDictionary *appInfo = [BDDYCUtils appInfo];
    NSString *appVersion = [appInfo objectForKey:kCurrentAppVersion];
    NSString *channel = [appInfo objectForKey:kCurrentChannel];

    if ([appVersion isEqualToString:self.conf.appVersion] && [channel isEqualToString:self.conf.channel]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)runBrady
{
    if ([self isBradyRunning]) return YES;

    [self lockVM];

    BOOL success = YES;
    
    Engine::instance().initialize();
    __weak typeof(self) weakSelf = self;
    Engine::instance().LogCallback = ^(const char *log) {
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf engineLog:log];
    };
    Engine::instance().ExceptionHandler = ^(NSError *error) {
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf engineExceptionHandler:error];
    };
    Engine::instance().LoadModuleErrorCallback = ^(NSError *error,
                                                   const char *moduleName,
                                                   int moduleVersion,
                                                   long long duration) {
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf engineLoadModuleError:error
                               moduleName:[NSString stringWithUTF8String:moduleName]
                            moduleVersion:moduleVersion
                                 duration:duration];
    };

    NSError *error;
    if (success) {
        _usingEngine |= BDDYCEngineUsingBrady;
    } else {
        error = [NSError errorWithDomain:BDDYCErrorDomain
            code:BDDYCErrCodeBradyInitFail
        userInfo:@{NSLocalizedDescriptionKey: @"Create Brady fails"}];
    }
    [self unlockVM];

    if ([self.delegate respondsToSelector:@selector(engineDidInitWithError:type:)]) {
        [self.delegate engineDidInitWithError:error
                                         type:BDDYCEngineUsingBrady];
    }
    return success;
}

- (void)closeBrady
{
    if (![self isBradyRunning]) return;

    [self lockVM];
    _usingEngine &= ~(BDDYCEngineUsingBrady);
    Engine::instance().shutdown();
    [self unlockVM];
}

#pragma mark -

+ (void)loadLazyModuleWithName:(NSString *)name {
    if (!name || name.length <= 0) {
        BDALOG_PROTOCOL_INFO_TAG(@"better", @"dlib name is nil");
        return;
    }
    
    [[BDBDQuaterback sharedMain] lockLazyModules];
    [[BDBDQuaterback sharedMain].loadedlazyDylibs addObject:name];
    [[BDBDQuaterback sharedMain] unlockLazyModules];
    
    NSArray *localAlphaMdls = kBDDYCGetLocalQuaterbackModules;
    [[BDDYCModuleManager sharedManager] addModules:localAlphaMdls];

    BDALOG_PROTOCOL_INFO_TAG(@"better", @"load dylib better : %@",name);
    __block BOOL bError = NO;
    [localAlphaMdls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if ([obj isKindOfClass:[BDBDModule class]]) {
            BDBDModule *module = (BDBDModule *)obj;
             
            [[module.config.lazyLoadDlibList copy] enumerateObjectsUsingBlock:^(id  _Nonnull dylibName, NSUInteger idx, BOOL * _Nonnull stop) {
                //1、懒加载动态库热修包还没有加载
//                2、加载指定懒加载动态库热修包（name 匹配）
                if (![[BDBDQuaterback loadedlazyModules] containsObject:module.name]
                    && [module.config.lazyLoadDlibList containsObject:name]) {
                    BDALOG_PROTOCOL_INFO_TAG(@"better", @"dlib name : %@",name);
                    [[BDBDQuaterback sharedMain] lockLazyModules];
                    [[BDBDQuaterback sharedMain].loadedlazyModules addObject:module.name];
                    [[BDBDQuaterback sharedMain] unlockLazyModules];
   //                 loadLazyLoadDylibAndReturnError
                    [[BDBDQuaterback sharedMain] loadDYCLazyDylibModule:obj errorBlock:^(NSError *error) {
                        if (error) bError = YES;
                    }];
                    *stop = YES;
                }
            }];
         }
    }];

    // update module list in local file, when failure
    if (bError) [[BDDYCModuleManager sharedManager] saveToFile];
}

+ (NSArray *)loadedlazyModules {
    [[BDBDQuaterback sharedMain] lockLazyModules];
    NSArray *modules = [[BDBDQuaterback sharedMain].loadedlazyModules copy];
    [[BDBDQuaterback sharedMain] unlockLazyModules];
    return modules;
}

+ (NSArray *)loadedlazydylibs {
    [[BDBDQuaterback sharedMain] lockLazyModules];
    NSArray *modules = [[BDBDQuaterback sharedMain].loadedlazyDylibs copy];
    [[BDBDQuaterback sharedMain] unlockLazyModules];
    return modules;
}

- (void)loadLocalAllModules
{
    NSArray *localAlphaMdls = kBDDYCGetLocalQuaterbackModules;
    [[BDDYCModuleManager sharedManager] addModules:localAlphaMdls];

    __block BOOL bError = NO;
    [localAlphaMdls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        //只加载一个bitcode
//        if (idx == 0) {
            [self loadDYCModule:obj errorBlock:^(NSError *error) {
                if (error) bError = YES;
            }];
//        }
    }];

    // update module list in local file, when failure
    if (bError) [[BDDYCModuleManager sharedManager] saveToFile];
}
/*
 *加载懒加载动态库热修包
 */
- (void)loadDYCLazyDylibModule:(BDBDModule *)aDYCModule
                    errorBlock:(void (^_Nullable)(NSError *error))errorBlock {
    [self _loadDYCModule:aDYCModule errorBlock:errorBlock];
    NSError *loadError;
    [aDYCModule loadAndReturnError:&loadError];
}

/*
 1、初始化SDK加载本地热修包
 2、加载刚下载热修包
 */

- (void)loadDYCModule:(BDBDModule *)aDYCModule errorBlock:(void (^)(NSError *error))errorBlock{
//    loadedlazydylibs
    if (aDYCModule.config.lazyLoadDlibList.count > 0) {
//        加载刚下载热修包
        __block bool loadPatch = [BDBDQuaterback loadedlazydylibs].count > 0;
        [aDYCModule.config.lazyLoadDlibList enumerateObjectsUsingBlock:^(id  _Nonnull dylibName, NSUInteger idx, BOOL * _Nonnull stop) {
            //热修包依赖的动态库必须已加载
            if (![[BDBDQuaterback loadedlazydylibs] containsObject:dylibName]) {
                loadPatch = NO;
                *stop = YES;
            }
        }];
        
        if (loadPatch) {
            [self _loadDYCModule:aDYCModule errorBlock:errorBlock];
            NSError *loadError;
            [aDYCModule loadAndReturnError:&loadError];
        } else {
            BDALOG_PROTOCOL_ERROR_TAG(@"better", @"Lazy dylib did not load：%@ --- loaded Dlib: %@",aDYCModule.config.lazyLoadDlibList,[BDBDQuaterback loadedlazyModules]);
        }
    } else {
//初始化SDK加载本地热修包
        [self _loadDYCModule:aDYCModule errorBlock:errorBlock];
        NSError *loadError;
        [aDYCModule loadAndReturnError:&loadError];
    }


}

- (void)_loadDYCModule:(BDBDModule *)aDYCModule errorBlock:(void (^)(NSError *error))errorBlock
{
    if (!aDYCModule) return;

    // Get old module
    BDBDModule *oldDYCModule = [[BDDYCModuleManager sharedManager] didLoadModuleWithName:aDYCModule.name];
    if (oldDYCModule != aDYCModule) {
        [[BDDYCModuleManager sharedManager] removeModule:oldDYCModule];
        [[BDDYCModuleManager sharedManager] addModule:aDYCModule];
    }


#ifdef DEBUG
    NSLog(@"module name: %@, files = %@", aDYCModule.name, aDYCModule.files);
#endif

    // Load new module
    [self runBrady];

    [self moduleData:aDYCModule willLoadWithError:nil];
    if ([self.delegate respondsToSelector:@selector(moduleData:willLoadWithError:)]) {
        [self.delegate moduleData:aDYCModule willLoadWithError:nil];
    }
}

+ (void)clearAllLocalQuaterback {
    [BDDYCModuleManager clearAllLocalQuaterback];
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    //NSArray *patchs = [[BDDYCModuleManager sharedManager] allToLogModules];
    NSDictionary *data = @{@"betters":@[],
                           @"timestamp":[NSNumber numberWithDouble:interval],
                           };
    [BDDYCMonitorGet() trackService:kBDDYCQuaterbackWillClearQuaterbacksMonitorServiceName status:kBDQuaterbackWillClearPatchsStatusByCustomer extra:data];
}


#pragma mark -

- (BOOL)isEngineRunning
{
    return (BDDYCEngineUsingUndefined != _usingEngine);
}

- (BOOL)isJSContextRunning
{
    return (BDDYCEngineUsingJSContext & _usingEngine);
}

- (BOOL)isBradyRunning
{
    [self lockVM];
    BOOL isBradyRunning = (BDDYCEngineUsingBrady & _usingEngine);
    [self unlockVM];
    return isBradyRunning;
}

#pragma mark - fetch from server
+ (void)fetchServerData
{
    dispatch_async([BDBDQuaterback sharedMain].fetchListQueue, ^{
        if ([self fetchServerDataIfNeed]) {
            [[BDBDQuaterback sharedMain] lockInitial];
            [BDBDQuaterback sharedMain].willStartFetchList = YES;
            [[BDBDQuaterback sharedMain] unlockInitial];
            __block __weak id weakTask = nil;
            __weak NSMutableSet *weakTaskSet = [BDBDQuaterback sharedMain].taskSet;
            id task = weakTask = [self fetchModuleDataWithCompletion:^(NSArray * _Nonnull modules, NSError * _Nonnull error) {
                __strong id strongTask = weakTask;
                [[BDBDQuaterback sharedMain] lockTaskSet];
                if (strongTask) {
                    [weakTaskSet removeObject:strongTask];
                }
                [[BDBDQuaterback sharedMain] unlockTaskSet];
            }];
            
            [[BDBDQuaterback sharedMain] lockTaskSet];
            [[BDBDQuaterback sharedMain].taskSet addObject:task];
            [[BDBDQuaterback sharedMain] unlockTaskSet];

        }
    });
}

+ (BOOL)fetchServerDataIfNeed {
    [[BDBDQuaterback sharedMain] lockInitial];
    if (![BDBDQuaterback sharedMain].didStartSDK) {
        [[BDBDQuaterback sharedMain] unlockInitial];
        return NO;
    }

    if ([BDBDQuaterback sharedMain].willStartFetchList) {
        [[BDBDQuaterback sharedMain] unlockInitial];
        return NO;
    }
    [[BDBDQuaterback sharedMain] unlockInitial];
    return YES;
}

#pragma mark - BDDLLIEngineDelegate

- (void)engineLog:(const char *)msg
{
//    BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@",msg);
}

- (void)engineExceptionHandler:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(engineDidRunWithError:type:)]) {
        [self.delegate engineDidRunWithError:error type:BDDYCEngineUsingBrady];
    }
}

- (void)engineLoadModuleError:(NSError *)error
                   moduleName:(NSString *)moduleName
                moduleVersion:(int)moduleVersion
                     duration:(long long)duration {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    long long milloSecondsInterval = [[NSNumber numberWithDouble:interval] longLongValue];
    NSNumber *timestamp = [NSNumber numberWithLongLong:milloSecondsInterval];
    pthread_mutex_lock(&_loadSuccessLock);
    NSDictionary *data = @{@"timestamp":timestamp,
                           @"better_name":moduleName?:@"",
                           @"version_code":[NSNumber numberWithInt:moduleVersion],
                           @"status":[[self class] statusMap:error],
                           @"duration":[NSNumber numberWithLongLong:duration],
                           };
    [BDDYCMonitorGet() trackData:data];

    BDBDModule *module = [[BDDYCModuleManager sharedManager] moduleForName:moduleName];
    if (error) {
        switch (error.code) {
            case BDLLIEngineLoadErrCodeFileHasLoad:
            case BDLLIEngineLoadErrCodeOverflow:
            {
                BDALOG_PROTOCOL_INFO(@"better did load : %@",data);
            }
                break;
            default:
            {
                [module unloadAndRemove];
                [[BDDYCModuleManager sharedManager] removeModule:module];
            }
                break;
        }

    } else {
        [BDDYCMonitorGet() trackService:kBDDYCQuaterbackDAU metric:@{@"duration":[NSNumber numberWithLongLong:duration]} category:data extra:nil];

        if (moduleName && data) {
            [_betterInfo removeObjectsForKeys:@[moduleName]];
            [_betterInfo setObject:data forKey:moduleName];
        }
        [BDDYCMonitorGet() setCustomFilterValue:[_betterInfo copy] forKey:kBDDYCQuaterbackInjectedInfoKey];
    }
    if ([self.delegate respondsToSelector:@selector(moduleData:didLoadWithError:)]) {
        [self.delegate moduleData:module didLoadWithError:error];
    }
    pthread_mutex_unlock(&_loadSuccessLock);
}

/**
 Will load
 */
- (void)moduleData:(BDBDModule *)aModule willLoadWithError:(NSError *)error {
    NSString *moduleVersion = [self queryVersionFromData:aModule];

    if (error) {
        NSString *info = [NSString stringWithFormat:@"better will parse item error: %@, moduleVersion=%@", error, moduleVersion];
        BDALOG_PROTOCOL_INFO_TAG(@"better"  @"willparse %@", info);
        return;
    }
    BDALOG_PROTOCOL_INFO_TAG(@"better", @"will parse item : moduleVersion:%@", moduleVersion);

    if (aModule == nil) {
        return;
    }

    [BDDYCMonitorGet() setCustomContextValue:@"1" forKey:kAWEZephyrLoadedKey];
    [BDDYCMonitorGet() setCustomFilterValue:@"1" forKey:kAWEZephyrLoadedKey];

    [[BDBDModuleLoadManager shared] add:moduleVersion];
    NSString *versionInfo = [[BDBDModuleLoadManager shared] current];

    [BDDYCMonitorGet() setCustomContextValue:versionInfo forKey:kAWEZephyrLoadedVersionKey];
    [BDDYCMonitorGet() setCustomFilterValue:versionInfo forKey:kAWEZephyrLoadedVersionKey];
}


- (NSString*)queryVersionFromData:(BDBDModule *)aModule {
    if (aModule == nil) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@#%@", aModule.moduleModel.name, aModule.moduleModel.version];
}


+ (NSNumber *)statusMap:(NSError *)err {
    if (!err) {
        return [NSNumber numberWithInteger:21000];
    }
    NSInteger statusCode = 22000;
    switch (err.code) {
        case BDLLIEngineLoadErrCodeUnknow:
            statusCode = 22000;
            break;
        case BDLLIEngineLoadErrFileNameInvalid:
            statusCode = 22001;
            break;
        case BDLLIEngineLoadErrCodeFilePathNotExist:
            statusCode = 22002;
            break;
        case BDLLIEngineLoadErrCodeFileHasLoad:
        case BDLLIEngineLoadErrCodeOverflow:
            statusCode = 21000;
            break;
        case BDLLIEngineLoadErrCodeVMCreationFail:
            statusCode = 22003;
            break;
        case BDLLIEngineLoadErrCodeBitcodeParseFail:
            statusCode = 22004;
            [self clearAllLocalQuaterback];
            break;
        case BDLLIEngineLoadErrCodeBitcodeLoadFail:
            statusCode = 22005;
            break;
        case BDLLIEngineLoadErrCodeBitcodeExecError:
            statusCode = 22006;
            break;
        case BDLLIEngineLoadErrCodeUnloadFail:
            statusCode = 22007;
            break;

        default:
            statusCode = 22000;
            break;
    }
    return [NSNumber numberWithInteger:statusCode];
}

#pragma mark - Setter/Getter

- (NSArray *)allLoadedQuaterbacks {
    return [[BDDYCModuleManager sharedManager] allLoadedQuaterbacks];
}

/// 测试本地补丁
/// @param path 本地补丁路径，必须是.bc文件
+ (void)_loadModuleAtPath:(NSString *)path
{
    Engine::instance().initialize();
    auto MC = std::make_unique<ModuleConfiguration>();
    MC->path = path.UTF8String;
    MC->name = path.UTF8String;
    MC->async = false;
    Engine::instance().loadModule(std::move(MC));
}

+ (void *)lookupFunctionByName:(NSString *)functionName
                 inModuleNamed:(NSString *)moduleName
                 moduleVersion:(int)moduleVersion{
    return Engine::instance().lookupFunction(functionName.UTF8String,
                                             moduleName.UTF8String,
                                             moduleVersion);
}

@end
