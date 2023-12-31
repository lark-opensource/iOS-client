//
//  HMDConfigStore.m
//  Heimdallr
//
//  Created by Nickyo on 2023/5/25.
//

#import "HMDConfigStore.h"
#import "HMDInjectedInfo.h"
#import "HMDNetworkProvider.h"
#import "HMDMacro.h"
#import "HMDALogProtocol.h"
#import "pthread_extended.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDUserDefaults.h"
#import "HMDWeakProxy.h"
#import "HMDHeimdallrConfig.h"

@interface HMDConfigStore ()

@property (nullable, nonatomic, copy) NSString *appID;

@property (nonatomic, strong) NSMutableDictionary *lastTimestamp;

@property (nullable, nonatomic, strong) HMDHeimdallrConfig *hostConfig;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HMDHeimdallrConfig *> *configList;

@property (nullable, nonatomic, strong) id<HMDNetworkProvider> hostProvider;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<HMDNetworkProvider>> *providerList;

@property (nonatomic, strong) NSMutableSet<NSString *> *sdkAppIDList;

@end

@implementation HMDConfigStore

- (instancetype)init {
    self = [super init];
    if (self) {
        rwlock_init_private(_rwlock);
        pthread_mutex_init(&_mutexlock, NULL);
        
        self.configList = [NSMutableDictionary dictionaryWithCapacity:5];
        self.providerList = [NSMutableDictionary dictionaryWithCapacity:5];
        self.sdkAppIDList = [self.class loadSDKAppIDList];
    }
    return self;
}

- (BOOL)isHostAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID)) {
        return NO;
    }
    return [self.hostAppID isEqualToString:appID];
}

#pragma mark - Status

static NSString * const kHMDSDKLastTimeStamp = @"HMDSDKLastTimeStamp";

- (NSString *)lastTimestampForAppID:(NSString *)appID {
    return [self.lastTimestamp hmd_objectForKey:appID class:NSString.class];
}

- (void)setLastTimestamp:(NSString *)timestamp forAppIDList:(NSArray<NSString *> *)appIDList {
    for (NSString *appID in appIDList) {
        [self.lastTimestamp hmd_setObject:timestamp forKey:appID];
    }
    [[HMDUserDefaults standardUserDefaults] setObject:self.lastTimestamp.copy forKey:kHMDSDKLastTimeStamp];
}

- (NSMutableDictionary *)lastTimestamp {
    if (_lastTimestamp == nil) {
        NSDictionary *lastTimestamp = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDSDKLastTimeStamp];
        _lastTimestamp = lastTimestamp ? [NSMutableDictionary dictionaryWithDictionary:lastTimestamp] : [NSMutableDictionary new];
    }
    return _lastTimestamp;
}

#pragma mark - Config

- (HMDHeimdallrConfig *)majorConfig {
    pthread_rwlock_rdlock(&_rwlock);
    HMDHeimdallrConfig *config = self.hostConfig ?: self.configList.allValues.firstObject;
    pthread_rwlock_unlock(&_rwlock);
    return config;
}

- (BOOL)setDefaultConfig:(HMDHeimdallrConfig *)config forAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID)) {
        return NO;
    }
    if (config == nil || ![config isKindOfClass:HMDHeimdallrConfig.class]) {
        return NO;
    }
    pthread_rwlock_wrlock(&_rwlock);
    [self.configList hmd_setObject:config forKey:appID];
    
    BOOL isHost = [self isHostAppID:appID];
    if (isHost) {
        self.hostConfig = config;
    }
    pthread_rwlock_unlock(&_rwlock);
    return YES;
}

- (BOOL)setRemoteConfigs:(NSDictionary<NSString *,HMDHeimdallrConfig *> *)configs {
    pthread_rwlock_wrlock(&_rwlock);
    [self.configList hmd_addEntriesFromDict:configs];
    
    HMDHeimdallrConfig *hostConfig = [configs hmd_objectForKey:self.hostAppID class:HMDHeimdallrConfig.class];
    if (hostConfig != nil) {
        self.hostConfig = hostConfig;
    }
    pthread_rwlock_unlock(&_rwlock);
    return YES;
}

- (HMDHeimdallrConfig *)configForAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID)) {
        return nil;
    }
    pthread_rwlock_rdlock(&_rwlock);
    HMDHeimdallrConfig *config = [self.configList hmd_objectForKey:appID class:HMDHeimdallrConfig.class];
    pthread_rwlock_unlock(&_rwlock);
    return config;
}

- (void)enumerateAppIDsAndConfigsUsingBlock:(void (NS_NOESCAPE ^)(NSString * _Nonnull, HMDHeimdallrConfig * _Nullable, BOOL * _Nonnull))block {
    pthread_rwlock_rdlock(&_rwlock);
    NSDictionary<NSString *, HMDHeimdallrConfig *> *configList = [self.configList copy];
    pthread_rwlock_unlock(&_rwlock);
    
    [configList enumerateKeysAndObjectsUsingBlock:block];
}

#pragma mark - Provider

- (BOOL)addProvider:(id<HMDNetworkProvider>)provider forAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID)) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"HMDConfigManager", @"[addProvider:forAppID:] App ID is nil");
        }
        return NO;
    }
    if (provider == nil || ![provider conformsToProtocol:@protocol(HMDNetworkProvider)]) {
        return NO;
    }
    
    pthread_mutex_lock(&_mutexlock);
    [self.providerList hmd_setObject:provider forKey:appID];
    
    BOOL isHost = [self isHostAppID:appID];
    if (isHost) {
        self.hostProvider = provider;
    } else {
        [self.sdkAppIDList addObject:appID];
        [self.class saveSDKAppIDList:self.sdkAppIDList];
    }
    pthread_mutex_unlock(&_mutexlock);
    
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDConfigManager", @"[addProvider:forAppID:] App ID is %@, isHost: %d", appID, isHost);
    }
    return YES;
}

- (BOOL)removeProvider:(void *)providerPtr forAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID) || !providerPtr) {
        return NO;
    }
    pthread_mutex_lock(&_mutexlock);
    void *currentProviderPtr = (__bridge void *)[self.providerList hmd_objectForKey:appID class:NSObject.class];
    if (providerPtr == currentProviderPtr) {
        [self.providerList removeObjectForKey:appID];
    }
    pthread_mutex_unlock(&_mutexlock);
    return YES;
}

- (id<HMDNetworkProvider>)providerForAppID:(NSString *)appID {
    if (HMDIsEmptyString(appID)) {
        return nil;
    }
    pthread_mutex_lock(&_mutexlock);
    id<HMDNetworkProvider> provider = [self.providerList hmd_objectForKey:appID class:NSObject.class];
    pthread_mutex_unlock(&_mutexlock);
    return provider;
}

- (void)enumerateAppIDsAndProvidersUsingBlock:(void (NS_NOESCAPE ^)(NSString * _Nonnull, id<HMDNetworkProvider> _Nullable, BOOL * _Nonnull))block {
    pthread_mutex_lock(&_mutexlock);
    NSMutableArray *appIDList = [NSMutableArray arrayWithArray:self.sdkAppIDList.allObjects];
    NSString *hostAppID = [self hostAppID];
    if (hostAppID != nil) {
        [appIDList addObject:hostAppID];
    }
    NSDictionary<NSString *, id<HMDNetworkProvider>> *providerList = [self.providerList copy];
    pthread_mutex_unlock(&_mutexlock);
    
    BOOL stop = NO;
    for (NSString *appID in appIDList) {
        @autoreleasepool {
            id<HMDNetworkProvider> provider = [providerList hmd_objectForKey:appID class:NSObject.class];
            block(appID, provider, &stop);
            if (stop) {
                break;
            }
        }
    }
}

#pragma mark - SDK AppID Store

static NSString * const kHMDSDKRealAidList = @"HMDSDKRealAidList";

+ (NSMutableSet<NSString *> *)loadSDKAppIDList {
    NSArray *appIDArr = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDSDKRealAidList];
    if (HMDIsEmptyArray(appIDArr)) {
        return [NSMutableSet setWithCapacity:3];
    }
    return [NSMutableSet setWithArray:appIDArr];
}

+ (void)saveSDKAppIDList:(NSMutableSet<NSString *> *)sdkAppIDList {
    [[HMDUserDefaults standardUserDefaults] setObject:sdkAppIDList.allObjects forKey:kHMDSDKRealAidList];
}

#pragma mark - Getter & Setter

- (NSString *)hostAppID {
    return self.appID ?: [HMDInjectedInfo defaultInfo].appID;
}

@end
