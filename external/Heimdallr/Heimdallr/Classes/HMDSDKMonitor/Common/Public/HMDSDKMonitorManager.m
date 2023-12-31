//
//  HMDSDKInjected.m
//  Heimdallr-iOS13.0
//
//  Created by zhangxiao on 2019/10/31.
//

#import "HMDSDKMonitorManager.h"
#import "pthread_extended.h"
#import "HMDHeimdallrConfig.h"
#import "HMDInjectedInfo.h"
#import "HMDTTMonitor.h"
#import "HMDSDKMonitorDataManager.h"

static HMDSDKMonitorManager *instance = nil;

@interface HMDSDKMonitorManager ()

@property (nonatomic, strong) NSMutableDictionary *sdkInfoDict;

@end

@implementation HMDSDKMonitorManager {
    pthread_rwlock_t _rwLock;
}

#pragma mark --- init
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDSDKMonitorManager alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sdkInfoDict = [NSMutableDictionary dictionary];
        rwlock_init_private(_rwLock);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark --- setup monitor
- (void)setupSDKMonitorWithSDKAid:(NSString *)sdkAid monitorUserInfo:(HMDTTMonitorUserInfo *)userInfo productions:(void(^)(HMDTTMonitor * _Nullable))products {
    NSAssert(sdkAid.length > 0, @"Heimdallr sdkMomitor error:[setupSDKSDKMonitorWithSDKAid: monitorUserInfo:] You cannot initialize SDKAid to nil!");
    NSAssert(userInfo != nil, @"heimdallr sdkMonitor error: [setupSDKSDKMonitorWithSDKAid: monitorUserInfo:] You cannot initialize monitorUserInfo to nil!");
    if (!sdkAid || sdkAid.length == 0 || !userInfo) {
        if (products) {
            products(nil);
        }
        return;
    }
    HMDSDKMonitorDataManager *sdkDataManager = [[HMDSDKMonitorDataManager alloc] initSDKMonitorDataManagerWithSDKAid:sdkAid injectedInfo:userInfo];
    pthread_rwlock_wrlock(&_rwLock);
    [self.sdkInfoDict setValue:sdkDataManager forKey:sdkAid];
    pthread_rwlock_unlock(&_rwLock);
    if (products) {
        products(sdkDataManager.ttMonitor);
    }
}

#pragma mark --- category(privated) method

- (NSString * _Nullable)sdkHostAidWithSDKAid:(NSString * _Nonnull)sdkAid {
    if (!sdkAid || sdkAid.length == 0) { return nil; }
    pthread_rwlock_rdlock(&_rwLock);
    HMDSDKMonitorDataManager *sdkInfo = [self.sdkInfoDict valueForKey:sdkAid];
    pthread_rwlock_unlock(&_rwLock);
    return sdkInfo.hostAid;
}

- (HMDTTMonitorUserInfo *_Nullable)ttMonitorUserInfoWithSDKAid:(NSString *)sdkAid {
    if (!sdkAid || sdkAid.length == 0) { return nil; }
    pthread_rwlock_rdlock(&_rwLock);
    HMDSDKMonitorDataManager *sdkInfo = [self.sdkInfoDict valueForKey:sdkAid];
    pthread_rwlock_unlock(&_rwLock);
    return sdkInfo.ttMonitorUserInfo;
}

@end
