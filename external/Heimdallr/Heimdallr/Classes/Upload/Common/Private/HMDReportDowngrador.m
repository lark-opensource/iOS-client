//
//  HMDReportDowngrador.m
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 1/8/2022.
//

#import "HMDReportDowngrador.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInjectedInfo.h"
#import <pthread/pthread.h>
#import "HeimdallrUtilities.h"

static NSString * const kServiceMonitorLogType = @"service_monitor";
static NSString * const kOtherMonitorLogType = @"other";
static NSString * const kExpiredTime = @"expired_time";
static NSString * const kUserDefaultsTopKey = @"rule";

bool hmd_downgrade_performance_aid(NSString *logType, NSString *aid) {
    if (![HMDReportDowngrador sharedInstance].enabled) return false;
    BOOL needUpload = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:logType serviceName:nil aid:aid];
    return !needUpload;
}

bool hmd_downgrade_performance(NSString *logType) {
    return hmd_downgrade_performance_aid(logType, [HMDInjectedInfo defaultInfo].appID);
}

@implementation HMDReportDowngrador {
    pthread_rwlock_t _rwlock;
    NSDictionary *_downgradeRule;
    NSUserDefaults *_userDefaults;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HMDReportDowngrador *downgrador;
    dispatch_once(&onceToken, ^{
        downgrador = [[HMDReportDowngrador alloc] init];
    });
    return downgrador;
}


- (instancetype)init {
    if (self = [super init]) {
        pthread_rwlock_init(&_rwlock, NULL);
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[HeimdallrUtilities customPlistSuiteComponent:@"event_downgrade_rule_new"]];
        NSUserDefaults *oldRuleUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:[HeimdallrUtilities customPlistSuiteComponent:@"event_downgrade_rule"]];
        id oldRule = [oldRuleUserDefaults objectForKey:kUserDefaultsTopKey];
        if (oldRule) {
            [self updateDowngradeRule:oldRule];
            [oldRuleUserDefaults removeObjectForKey:kUserDefaultsTopKey];
        } else {
            _downgradeRule = [_userDefaults objectForKey:kUserDefaultsTopKey];
        }
        _enabled = NO;
    }
    return self;
}

- (BOOL)needUploadWithLogType:(NSString *)logType serviceName:(NSString *)serviceName aid:(NSString *)aid {
    CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    return [self needUploadWithLogType:logType serviceName:serviceName aid:aid currentTime:currentTime];
}

- (BOOL)needUploadWithLogType:(NSString *)logType serviceName:(NSString *)serviceName aid:(NSString *)aid currentTime:(CFTimeInterval)currentTime {
    if (!self.enabled) return YES;
    
    pthread_rwlock_rdlock(&_rwlock);
    
    // check if the info is empty
    if (!_downgradeRule) {
        pthread_rwlock_unlock(&_rwlock);
        return YES;
    }
    
    NSDictionary *aidDict = [_downgradeRule hmd_dictForKey:aid];
    NSDictionary *defaultDict = [_downgradeRule hmd_dictForKey:@"default"];
    NSTimeInterval expiredTime = [aidDict objectForKey:kExpiredTime] ? [aidDict hmd_doubleForKey:kExpiredTime] : [defaultDict hmd_doubleForKey:kExpiredTime];
    
    // check if the time is expired
    if (currentTime > expiredTime) {
        pthread_rwlock_unlock(&_rwlock);
        return YES;
    }
    
    // check if the data hit downgrade rule
    BOOL ret = YES;
    NSDictionary *dic;
    NSString *key;
    BOOL defaultValue = YES;
    if ([logType isEqualToString:kServiceMonitorLogType]) {
        dic = [aidDict hmd_dictForKey:kServiceMonitorLogType];
        defaultValue = [defaultDict hmd_boolForKey:kServiceMonitorLogType];
        key = serviceName;
    } else {
        dic = [aidDict hmd_dictForKey:kOtherMonitorLogType];
        defaultValue = [defaultDict hmd_boolForKey:kOtherMonitorLogType];
        key = logType;
    }
    
    ret = [dic objectForKey:key] ? [dic hmd_boolForKey:key] : defaultValue;
    pthread_rwlock_unlock(&_rwlock);
    return ret;
}

- (void)updateDowngradeRule:(NSDictionary *)info {
    [self updateDowngradeRule:info forAid:[HMDInjectedInfo defaultInfo].appID];
}

- (void)updateDowngradeRule:(NSDictionary *)info forAid:(NSString *)aid {
    pthread_rwlock_wrlock(&_rwlock);
    NSMutableDictionary *lastRule = [NSMutableDictionary dictionaryWithDictionary:_downgradeRule];
    NSUInteger duration = [info hmd_unsignedIntegerForKey:@"duration"];
#if RANGERSAPM
    duration = MIN(duration, 24 * 60 * 60);
#endif
    NSTimeInterval expireTime = CFAbsoluteTimeGetCurrent() + duration;
    NSDictionary *other = [info hmd_dictForKey:kOtherMonitorLogType];
    NSDictionary *serviceMonitor = [info hmd_dictForKey:kServiceMonitorLogType];
    //获取降级策略包含的所有aid，同时把本次降级策略触发的aid也加进来，兼容同一aid降级策略变化的情况
    NSMutableSet *allAids = [NSMutableSet setWithArray:[other allKeys]];
    [allAids addObjectsFromArray:[serviceMonitor allKeys]];
    if (aid) {
        [allAids addObject:aid];
    }
    
    [allAids enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSString.class]) {
            NSMutableDictionary *aidRule = [NSMutableDictionary dictionary];
            [aidRule hmd_setObject:[other objectForKey:obj] forKey:kOtherMonitorLogType];
            [aidRule hmd_setObject:[serviceMonitor objectForKey:obj] forKey:kServiceMonitorLogType];
            if (aidRule.count > 0){
                [aidRule hmd_setObject:@(expireTime) forKey:kExpiredTime];
                [lastRule hmd_setObject:[aidRule copy] forKey:obj];
            } else {
                [lastRule removeObjectForKey:obj];
            }
        }
    }];
    _downgradeRule = [lastRule copy];
    pthread_rwlock_unlock(&_rwlock);
    
    @try {
        [_userDefaults setObject:_downgradeRule forKey:kUserDefaultsTopKey];
    } @catch (NSException *exception) {
    }
}

@end
