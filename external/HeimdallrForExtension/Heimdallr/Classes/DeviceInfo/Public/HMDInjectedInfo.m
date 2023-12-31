//
//  HMDInjectedInfo.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#include <math.h>
#import "NSNumber+HMDTypeClassify.h"
#import "HMDInjectedInfo.h"
#include "pthread_extended.h"
#import "HMDDynamicCall.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDUserDefaults.h"
#import "HMDALogProtocol.h"
#import "HMDMacro.h"

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

static NSString *const kHMDIgnorePerformanceDataTimekey = @"HeimdallrIgnorePerformanceDataTime";

typedef NSDictionary<NSString *, NSString *> *(^HMDGetCommonParamsByLevelBlock)(int level);

@interface HMDInjectedInfo() {
    pthread_rwlock_t commonParamsRWLock;
    pthread_rwlock_t didRWLock;
    pthread_rwlock_t iidRWLock;
    pthread_rwlock_t uidRWLock;
    pthread_rwlock_t ignoreTimeRWLock;
}

@property (atomic, copy, readwrite) NSDictionary *customContext; /**自定义环境信息，崩溃时可在后台查看辅助分析问题*/
@property (atomic, copy, readwrite) NSDictionary *filters; /**自定义环境信息，崩溃时可在后台查看辅助分析问题*/
@property (atomic, copy, readwrite) NSDictionary *customHeader;/**自定义Header*/

@end

@implementation HMDInjectedInfo

@synthesize commonParams = _commonParams, allUploadHost = _allUploadHost, deviceID = _deviceID, installID = _installID, userID = _userID, ignorePerformanceDataTime = _ignorePerformanceDataTime;

static HMDInjectedInfo *defaultInfo = nil;

+ (instancetype)defaultInfo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInfo = [[HMDInjectedInfo alloc] init];
        [defaultInfo addBytestFilterIfNeed];
    });
    return defaultInfo;
}

- (instancetype)init {
    if (self = [super init]) {
        _customContext = [[NSDictionary alloc] init];
        _filters = [[NSDictionary alloc] init];
        _business = @"unknown";
        _ignorePIPESignalCrash = NO;
        _ignorePerformanceDataTime = [[HMDUserDefaults standardUserDefaults] objectForKey:kHMDIgnorePerformanceDataTimekey];
        // 初始化读写锁
        pthread_rwlock_init(&commonParamsRWLock,NULL);
        pthread_rwlock_init(&didRWLock,NULL);
        pthread_rwlock_init(&iidRWLock,NULL);
        pthread_rwlock_init(&uidRWLock,NULL);
        pthread_rwlock_init(&ignoreTimeRWLock, NULL);
    }
    
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInfo = [super allocWithZone:zone];
    });
    return defaultInfo;
}

- (NSString *)appName {
    if (!_appName) {
        _appName = [self defaultAppName];
    }
    
    return _appName;
}

- (NSString *)channel {
    if (!_channel) {
        _channel = [self getCurrentChannel];
    }
    
    return _channel;
}

- (NSString *)appID {
    if (!_appID) {
        _appID = [self ssAppID];
    }
    
    return _appID;
}

- (NSDictionary<NSString*, id> *)commonParams {
    NSDictionary<NSString*, id> *parmas;
    
    HMDCommonParamsBlock block = self.commonParamsBlock;
    if(block) parmas = block();
    if(parmas) return parmas;
    
    pthread_rwlock_rdlock(&commonParamsRWLock);
    parmas = _commonParams;
    pthread_rwlock_unlock(&commonParamsRWLock);
    if(parmas) return parmas;
    
    return [self getTTNetParamsIfAvailable];
}

- (NSDictionary<NSString*, id> *)getTTNetParamsIfAvailable {
    id ttnetInstance = DC_CL(TTNetworkManager, shareInstance);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([ttnetInstance respondsToSelector:@selector(enableNewAddCommonParamsStrategy)] &&
        [ttnetInstance respondsToSelector:@selector(getCommonParamsByLevelBlock)]) {
        BOOL enableStrategy = [DC_OB(ttnetInstance, enableNewAddCommonParamsStrategy) boolValue];
        if (enableStrategy) {
            HMDGetCommonParamsByLevelBlock levelBlock = DC_OB(ttnetInstance, getCommonParamsByLevelBlock);
            if (levelBlock) {
                NSDictionary<NSString *, NSString *> *params = levelBlock(1);
                if (params) { return params; }
            }
        }
    }
#pragma clang diagnostic pop
    HMDCommonParamsBlock block = DC_OB(DC_CL(TTNetworkManager, shareInstance), commonParamsblock);
    if(block) return block();
    else return nil;
}

- (void)setCommonParams:(NSDictionary<NSString *,id> *)commonParams {
    pthread_rwlock_wrlock(&commonParamsRWLock);
    _commonParams = commonParams;
    pthread_rwlock_unlock(&commonParamsRWLock);
}

- (NSString *)defaultAppName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppName"];
}

- (NSString *)getCurrentChannel {
    static NSString *channelName;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channelName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
    });
    return channelName;
}

- (NSString *)ssAppID {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"];
}

- (void)setAllUploadHost:(NSString *)allUploadHost {
    allUploadHost = [allUploadHost copy];
    if (allUploadHost) {
        _crashUploadHost = allUploadHost;
        _exceptionUploadHost = allUploadHost;
        _performanceUploadHost = allUploadHost;
        _fileUploadHost = allUploadHost;
        _userExceptionUploadHost = allUploadHost;
    }
    _allUploadHost = allUploadHost;
}

- (void)setCustomContextValue:(id)value forKey:(NSString *)key {
    if (key == nil || key.length == 0) return;
    else key = [key copy];
    
    if([value isKindOfClass:NSNumber.class]) {
        __kindof NSNumber *num = (__kindof NSNumber *)value;
        if(!num.boolType && !num.integerType) {
            double testnum = num.doubleValue;
            if(isnan(testnum) || isinf(testnum)) {
                DEBUG_POINT // 传入 Nan or inf
                return;
            }
        }
    }
    else if([value isKindOfClass:NSString.class]) {
        __kindof NSString *temp = [(__kindof NSString *)value copy];
#ifdef DEBUG
        if(temp != value)
            HMDLog(@"mutable value is unsafe");
#endif
        value = temp;
    }
    else {
        DEBUG_POINT // 仅支持基本数据类型 [NSNumber / NSString] 不支持嵌套结构
        return;
    }
    
    NSMutableDictionary *mContext = [NSMutableDictionary dictionaryWithDictionary:self.customContext];
    [mContext setValue:value forKey:key];
    self.customContext = mContext;
}

- (void)removeCustomContextKey:(NSString *)key {
    if (key.length == 0 || ![self.customContext.allKeys containsObject:key]) return;
    
    NSMutableDictionary *mContext = [NSMutableDictionary dictionaryWithDictionary:self.customContext];
    [mContext removeObjectForKey:key];
    self.customContext = mContext;
}

- (void)setCustomFilterValue:(id)value forKey:(NSString *)key {
    if (![key isKindOfClass:NSString.class]) {
        return;
    }
    
    if (key.length == 0) {
        return;
    }
    
    key = [key copy];
    if ([value isKindOfClass:NSMutableString.class] || [value isKindOfClass:NSMutableDictionary.class]) {
        value = [value copy];
    }
    
    NSString *strVal = nil;
    if([value isKindOfClass:NSNumber.class]) {
        strVal = [(NSNumber *)value stringValue];
    }
    else if([value isKindOfClass:NSString.class]) {
        strVal = [value copy];
    } else {
        if ([value respondsToSelector:@selector(description)]) {
            strVal = [value description];
        }
    }
    
    NSMutableDictionary *mFilters = [NSMutableDictionary dictionaryWithDictionary:self.filters];
    [mFilters setValue:strVal forKey:key];
    self.filters = mFilters;
}

- (void)removeCustomFilterKey:(NSString *)key {
    if (key.length == 0 || ![self.filters.allKeys containsObject:key]) return;
    
    NSMutableDictionary *mFilters = [NSMutableDictionary dictionaryWithDictionary:self.filters];
    [mFilters removeObjectForKey:key];
    self.filters = mFilters;
}

- (void)addBytestFilterIfNeed {
    if ([HMDInfo isBytest]) {
        NSDictionary *bytestFilter = [HMDInfo bytestFilter];
        if (bytestFilter) {
            for (NSString *key in bytestFilter.allKeys) {
                [self setCustomFilterValue:[bytestFilter valueForKey:key] forKey:key];
            }
        }
    }
}

- (void)setCustomHeaderValue:(id)value forKey:(NSString *)key {
    if (![key isKindOfClass:NSString.class]) {
        return;
    }
    
    if (key.length == 0) {
        return;
    }
    
    key = [key copy];
    
    id mValue = nil;
    if ([value isKindOfClass:NSNumber.class]) {
        mValue = value;
    } else if ([value isKindOfClass:NSString.class]){
        mValue = [value copy];
    } else {
        if ([value respondsToSelector:@selector(description)]) {
            mValue = [value description];
        }
    }
    
    NSMutableDictionary *mHeader = [NSMutableDictionary dictionaryWithDictionary:self.customHeader];
    [mHeader setValue:mValue forKey:key];
    self.customHeader = mHeader;
}

- (void)removeCustomHeaderKey:(NSString *)key {
    if (key.length == 0 || ![self.customHeader.allKeys containsObject:key]) return;
    
    NSMutableDictionary *mHeader = [NSMutableDictionary dictionaryWithDictionary:self.customHeader];
    [mHeader removeObjectForKey:key];
    self.customHeader = mHeader;
}

- (void)setDeviceID:(NSString *)deviceID {
    pthread_rwlock_wrlock(&didRWLock);
    _deviceID = deviceID;
    pthread_rwlock_unlock(&didRWLock);
}

- (NSString *)deviceID {
    pthread_rwlock_rdlock(&didRWLock);
    HMDDynamicInfoBlock dynamicBlock = self.dynamicDID;
    NSString *deviceID = dynamicBlock ? dynamicBlock() : _deviceID;
    pthread_rwlock_unlock(&didRWLock);
    if (HMDIsEmptyString(deviceID)) {
        deviceID = @"0";
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"device_id invalid, use 0 as default value");
    }
    return deviceID;
}

- (void)setInstallID:(NSString *)installID {
    pthread_rwlock_wrlock(&iidRWLock);
    _installID = installID;
    pthread_rwlock_unlock(&iidRWLock);
}

- (NSString *)installID {
    pthread_rwlock_rdlock(&iidRWLock);
    HMDDynamicInfoBlock dynamicBlock = self.dynamicIID;
    NSString *installID = dynamicBlock ? dynamicBlock() : _installID;
    pthread_rwlock_unlock(&iidRWLock);
    if (HMDIsEmptyString(installID)) {
        installID = @"0";
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"install_id invalid, use 0 as default value");
    }
    return installID;
}

- (void)setUserID:(NSString *)userID {
    pthread_rwlock_wrlock(&uidRWLock);
    _userID = userID;
    pthread_rwlock_unlock(&uidRWLock);
}

- (NSString *)userID {
    pthread_rwlock_rdlock(&uidRWLock);
    HMDDynamicInfoBlock dynamicBlock = self.dynamicUID;
    NSString *userID = dynamicBlock ? dynamicBlock() : _userID;
    pthread_rwlock_unlock(&uidRWLock);
    if (HMDIsEmptyString(userID)) {
        userID = @"0";
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"user_id invalid, use 0 as default value");
    }
    return userID;
}

- (NSDate *)ignorePerformanceDataTime {
    pthread_rwlock_rdlock(&ignoreTimeRWLock);
    NSDate *ignoreTime = _ignorePerformanceDataTime;
    pthread_rwlock_unlock(&ignoreTimeRWLock);
    return ignoreTime;
}

- (void)setIgnorePerformanceDataTime:(NSDate *)ignorePerformanceDataTime {
    pthread_rwlock_wrlock(&ignoreTimeRWLock);
    _ignorePerformanceDataTime = ignorePerformanceDataTime;
    pthread_rwlock_unlock(&ignoreTimeRWLock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[HMDUserDefaults standardUserDefaults] setObject:ignorePerformanceDataTime forKey:kHMDIgnorePerformanceDataTimekey];
    });
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"set ignore performance data time : %@", ignorePerformanceDataTime.description);
}

- (NSTimeInterval)getIgnorePerformanceDataTimeInterval {
    NSDate *date = self.ignorePerformanceDataTime;
    NSTimeInterval timeInterval = 0.f;
    if (date) {
        timeInterval = [date timeIntervalSince1970];
    }
    return timeInterval;
}

@end
