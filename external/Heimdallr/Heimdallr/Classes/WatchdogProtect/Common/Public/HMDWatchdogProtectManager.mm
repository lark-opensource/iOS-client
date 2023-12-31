//
//  HMDWatchdogProtectManager.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDWatchdogProtectManager.h"
#import "HMDWatchdogProtectManager+Private.h"
#import <atomic>
#import "HMDWPUIPasteboard.h"
#import "UIApplication+HMDWatchdogProtect.h"
#import "HMDWPDynamicProtect.h"
#import "HMDWatchdogProtectDetectProtocol.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDTimeSepc.h"
#import "HMDSessionTracker.h"
#import "HMDGCD.h"
#import "HMDWPYYCache.h"
#import "HMDWPNSUserDefault.h"
#import "HMDMacro.h"
#import "pthread_extended.h"
#import "HMDInjectedInfo.h"
#import "HMDWatchdogProtectConfig.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "HMDServiceContext.h"

static NSString * const HMDCustomWatchdogProtectMonitorKey = @"slardar_custom_watchdog_protect";

static NSTimeInterval HMDWPTimeoutIntervalMin = 0.1;
static NSTimeInterval HMDWPTimeoutIntervalMax = 5.0;

bool HMDWPDispatchWorkItemEnabled = false;

#ifdef DEBUG
NSTimeInterval HMDWPDefaultTimeoutInterval = 0.5;
NSTimeInterval HMDWPDefaultLaunchThreshold = 5.0;
BOOL HMDWPDefaultUIPasteboardProtect = YES;
BOOL HMDWPDefaultUIApplicationProtect =YES;
BOOL HMDWPDefaultYYCacheProtect = YES;
BOOL HMDWPDefaultNSUserDefaultProtect = YES;
#else
NSTimeInterval HMDWPDefaultTimeoutInterval = 1.0;
NSTimeInterval HMDWPDefaultLaunchThreshold = 5.0;
BOOL HMDWPDefaultUIPasteboardProtect = NO;
BOOL HMDWPDefaultUIApplicationProtect = NO;
BOOL HMDWPDefaultYYCacheProtect = NO;
BOOL HMDWPDefaultNSUserDefaultProtect = NO;
#endif

@interface HMDWatchdogProtectManager ()
{
    dispatch_queue_t _serialQueue;
    std::atomic<NSTimeInterval> _timeoutInterval;
    std::atomic<NSTimeInterval> _launchThreshold;
    std::atomic<BOOL> _UIPasteboardProtect;
    std::atomic<BOOL> _UIApplicationProtect;
    std::atomic<BOOL> _YYCacheProtect;
    std::atomic<BOOL> _NSUserDefaultProtect;
    pthread_rwlock_t _rwLock;
    NSArray<NSString *> * _mainThreadProtectionCollection;
    NSArray<NSString *> * _anyThreadProtectCollection;
}

@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *localTypeList;

@property(atomic, weak)id<HMDWatchdogProtectDetectProtocol> delegate;

@end

@implementation HMDWatchdogProtectManager

+ (instancetype)sharedInstance {
    static HMDWatchdogProtectManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HMDWatchdogProtectManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSTimeInterval timeoutInterval = HMDWPDefaultTimeoutInterval;
        if (timeoutInterval < HMDWPTimeoutIntervalMin) {
            timeoutInterval = HMDWPTimeoutIntervalMin;
        }
        
        if (timeoutInterval > HMDWPTimeoutIntervalMax) {
            timeoutInterval = HMDWPTimeoutIntervalMax;
        }
        
        std::atomic_store_explicit(&_timeoutInterval, timeoutInterval, std::memory_order_release);
        std::atomic_store_explicit(&_launchThreshold, HMDWPDefaultLaunchThreshold, std::memory_order_release);
        std::atomic_store_explicit(&_UIPasteboardProtect, HMDWPDefaultUIPasteboardProtect, std::memory_order_release);
        std::atomic_store_explicit(&_UIApplicationProtect, HMDWPDefaultUIApplicationProtect, std::memory_order_release);
        std::atomic_store_explicit(&_YYCacheProtect, HMDWPDefaultYYCacheProtect, std::memory_order_release);
        std::atomic_store_explicit(&_NSUserDefaultProtect, HMDWPDefaultNSUserDefaultProtect, std::memory_order_release);
        _serialQueue = dispatch_queue_create("com.heimdallr.watchdog.protect", DISPATCH_QUEUE_SERIAL);
        
        _localTypeList = [NSMutableDictionary dictionaryWithCapacity:3];
        pthread_rwlock_init(&_rwLock, NULL);
    }
    
    return self;
}

- (NSTimeInterval)timeoutInterval {
    return std::atomic_load_explicit(&_timeoutInterval, std::memory_order_acquire);
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    if (timeoutInterval < HMDWPTimeoutIntervalMin) {
        timeoutInterval = HMDWPTimeoutIntervalMin;
    }
    
    if (timeoutInterval > HMDWPTimeoutIntervalMax) {
        timeoutInterval = HMDWPTimeoutIntervalMax;
    }
    
    std::atomic_store_explicit(&_timeoutInterval, timeoutInterval, std::memory_order_release);
}

- (NSTimeInterval)launchThreshold {
    return std::atomic_load_explicit(&_launchThreshold, std::memory_order_acquire);
}

- (void)setLaunchThreshold:(NSTimeInterval)launchThreshold {
    std::atomic_store_explicit(&_launchThreshold, launchThreshold, std::memory_order_release);
}

- (BOOL)UIPasteboardProtect {
    return std::atomic_load_explicit(&_UIPasteboardProtect, std::memory_order_acquire);
}

- (void)setUIPasteboardProtect:(BOOL)UIPasteboardProtect {
    std::atomic_store_explicit(&_UIPasteboardProtect, UIPasteboardProtect, std::memory_order_release);
    if (UIPasteboardProtect) {
        hmd_wp_toggle_pasteboard_protection(^(HMDWPCapture *capture) {
            [self processCapture:capture type:HMDWPTypeUIPasteboard];
        });
    }
    else {
        hmd_wp_toggle_pasteboard_protection(nil);
    }
}

- (BOOL)UIApplicationProtect {
    return std::atomic_load_explicit(&_UIApplicationProtect, std::memory_order_acquire);
}

- (void)setUIApplicationProtect:(BOOL)UIApplicationProtect {
    std::atomic_store_explicit(&_UIApplicationProtect, UIApplicationProtect, std::memory_order_release);
    if (UIApplicationProtect) {
        hmd_wp_toggle_application_protection(^(HMDWPCapture *capture) {
            [self processCapture:capture type:HMDWPTypeUIApplication];
        });
    }
    else {
        hmd_wp_toggle_application_protection(nil);
    }
}

- (BOOL)YYCacheProtect {
    return std::atomic_load_explicit(&_YYCacheProtect, std::memory_order_acquire);
}

- (void)setYYCacheProtect:(BOOL)YYCacheProtect {
    std::atomic_store_explicit(&_YYCacheProtect, YYCacheProtect, std::memory_order_release);
    if (YYCacheProtect) {
        hmd_wp_toggle_yycache_protection(^(HMDWPCapture *capture) {
            [self processCapture:capture type:HMDWPTypeYYCache];
        });
    }
    else {
        hmd_wp_toggle_yycache_protection(nil);
    }
}

- (BOOL)NSUserDefaultProtect {
    return std::atomic_load_explicit(&_NSUserDefaultProtect, std::memory_order_acquire);
}

- (void)setNSUserDefaultProtect:(BOOL)NSUserDefaultProtect {
    std::atomic_store_explicit(&_NSUserDefaultProtect, NSUserDefaultProtect, std::memory_order_release);
    if (NSUserDefaultProtect) {
        hmd_wp_toggle_nsuserdefault_protection(^(HMDWPCapture *capture) {
            [self processCapture:capture type:HMDWPTypeNSUserDefault];
        });
    }
    else {
        hmd_wp_toggle_nsuserdefault_protection(nil);
    }
}

- (NSString * _Nullable)currentProtectedMethodDescription {
    pthread_rwlock_wrlock(&_rwLock);
    NSString *mainThreadProtectDescription = _mainThreadProtectionCollection.description;
    NSString *anyThreadProtectDescription = _anyThreadProtectCollection.description;
    pthread_rwlock_unlock(&_rwLock);
    
    if(mainThreadProtectDescription == nil && anyThreadProtectDescription == nil) return nil;
    
    return [NSString stringWithFormat:@"main_thread:%@, any_thread:%@",
            mainThreadProtectDescription, anyThreadProtectDescription];
}

- (void)setDynamicProtectOnMainThread:(NSArray<NSString *> *)mainThreadProtectCollection
                          onAnyThread:(NSArray<NSString *> *)anyThreadProtectCollection {
    pthread_rwlock_wrlock(&_rwLock);
    _mainThreadProtectionCollection = [mainThreadProtectCollection copy];
    _anyThreadProtectCollection = [anyThreadProtectCollection copy];
    
    if (HMDIsEmptyArray(_mainThreadProtectionCollection) && HMDIsEmptyArray(_anyThreadProtectCollection)) {
        hmd_wp_toggle_dynamic_protection(_mainThreadProtectionCollection,
                                         _anyThreadProtectCollection,
                                         nil);
    }
    else {
        hmd_wp_toggle_dynamic_protection(_mainThreadProtectionCollection,
                                         _anyThreadProtectCollection,
                                         ^(HMDWPCapture *capture) {
            [self processCapture:capture type:HMDWPTypeDynamic];
        });
    }
    pthread_rwlock_unlock(&_rwLock);
    [self trackProtectedMethods];
}

- (void)trackProtectedMethods {
    NSSet<NSString *> *currentProtectSet = hmd_wp_dynamic_protect_method_set();
    if ([currentProtectSet count] > 0) {
        NSString *currentProtectSetString = [[currentProtectSet allObjects] componentsJoinedByString:@", "];
        [[HMDInjectedInfo defaultInfo] setCustomContextValue:currentProtectSetString forKey:HMDCustomWatchdogProtectMonitorKey];
        [[HMDInjectedInfo defaultInfo] setCustomFilterValue:currentProtectSetString forKey:HMDCustomWatchdogProtectMonitorKey];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ enable custom watchdog protect: %@", [HMDWatchdogProtectConfig configKey], currentProtectSetString);
    }
    else {
        [[HMDInjectedInfo defaultInfo] removeCustomContextKey:HMDCustomWatchdogProtectMonitorKey];
        [[HMDInjectedInfo defaultInfo] removeCustomFilterKey:HMDCustomWatchdogProtectMonitorKey];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ enable custom watchdog protect: nil", [HMDWatchdogProtectConfig configKey]);
    }
    NSMutableDictionary *category = [[NSMutableDictionary alloc] init];
    [currentProtectSet enumerateObjectsUsingBlock:^(NSString * _Nonnull protectedMethodName, BOOL * _Nonnull stop) {
        if ([protectedMethodName isKindOfClass:[NSString class]]) {
            [category setValue:@(1) forKey:protectedMethodName];
        }
    }];
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hmdTrackService:HMDCustomWatchdogProtectMonitorKey metric:nil category:category extra:nil];
}

- (void)turnOnYYCacheProtectIgnoreCloudSetting:(BOOL)turnOn {
    pthread_rwlock_rdlock(&_rwLock);
    [self.localTypeList setValue:@(turnOn) forKey:HMDWPYYCacheKey];
    pthread_rwlock_unlock(&_rwLock);
}

- (void)turnOnYYCacheProtectIgnorCloudSetting:(BOOL)turnOn {
    [self turnOnYYCacheProtectIgnoreCloudSetting:turnOn];
}

- (void)processCapture:(HMDWPCapture *)capture type:(HMDWPType)type {
    if (!(capture && capture.backtraces)) {
        return;
    }
    
    hmd_safe_dispatch_async(_serialQueue, ^{
        id<HMDWatchdogProtectDetectProtocol> delegate = self.delegate;
        if (!delegate) {
            return;
        }
        
        capture.protectType = [self typeString:type];
        if ([delegate respondsToSelector:@selector(didProtectWatchdogWithCapture:)]) {
            [delegate didProtectWatchdogWithCapture:capture];
        }
    });
}

- (NSString *)typeString:(HMDWPType)type {
    switch (type) {
        case HMDWPTypeUIPasteboard:
        {
            return HMDWPUIPasteboardKey;
        }
        case HMDWPTypeUIApplication:
        {
            return HMDWPUIApplicationKey;
        }
        case HMDWPTypeYYCache:
        {
            return HMDWPYYCacheKey;
        }
        case HMDWPTypeNSUserDefault:
        {
            return HMDWPNSUserDefaultKey;
        }
        case HMDWPTypeDynamic:
        {
            return HMDWPDynamicKey;
        }
        default:
        {
            return @"Unknown";
        }
    }
}

- (NSDictionary *)getLocalTypes {
    pthread_rwlock_wrlock(&_rwLock);
    NSDictionary *localTypes = [self.localTypeList copy];
    pthread_rwlock_unlock(&_rwLock);
    return localTypes;
}

@end
