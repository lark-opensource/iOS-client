//
//  HMDApplicationSession.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/12.
//

#include <atomic>
#import "HMDSessionTracker.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *kHMDSessionIDChangeNotification = @"kHMDSessionIDChangeNotification";
static const NSInteger kHMDSessionDurationUpdateThreshold = 5;

@interface HMDApplicationSession ()

@property (nonatomic, strong) NSLock *accessLock;
@property (atomic, readwrite) NSString *eternalSessionID;
@end

@implementation HMDApplicationSession {
    // 参考 C11 内容的原子变量
    std::atomic<double> _duration;
    std::atomic<double> _memoryUsage;
    std::atomic<double> _deviceMemoryUsage;
    std::atomic<double> _freeDisk;
    std::atomic<double> _freeMemory;
    std::atomic<NSUInteger> _localID;
}

@synthesize timestamp = _timestamp, customParams = _customParams, filters = _filters;
@dynamic duration, memoryUsage, deviceMemoryUsage, freeDisk, freeMemory,
         localID, backgroundStatus;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timestamp = [[NSDate date] timeIntervalSince1970];
        _accessLock = [[NSLock alloc] init];
        
        std::atomic_store_explicit(&_duration,
                                   (double)0.0,
                                   std::memory_order_release);
        
        self.appVersion = [HMDInfo defaultInfo].shortVersion;
        self.buildVersion = [HMDInfo defaultInfo].buildVersion;
        self.sdkVersion = [HMDInfo defaultInfo].sdkVersion;
        self.osVersion = [HMDInfo defaultInfo].systemVersion;
    }
    return self;
}

- (BOOL)isBackgroundStatus {
    return HMDApplicationSession_backgroundState();
}

- (NSUInteger)localID {
    return std::atomic_load_explicit(&_localID, std::memory_order_acquire);
}

- (void)setLocalID:(NSUInteger)localID {
    std::atomic_store_explicit(&_localID, localID, std::memory_order_release);
}

- (CFTimeInterval)timeInSession {
    CFTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    self.duration = endTime - self.timestamp;

    return self.duration;
}

#pragma mark - Atomic Operation

- (void)setDuration:(CFTimeInterval)duration {
    static std::atomic<NSTimeInterval> updateTS = {0};
    std::atomic_store_explicit(&_duration, duration, std::memory_order_release);
    
    NSTimeInterval curTS = [[NSDate date] timeIntervalSince1970];
    
    //duration update to database every 5 seconds
    if (curTS - std::atomic_load_explicit(&updateTS, std::memory_order_acquire) > kHMDSessionDurationUpdateThreshold) {
        
        if (hermas_enabled()) {
            if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
                [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
                std::atomic_store_explicit(&updateTS, [[NSDate date] timeIntervalSince1970], std::memory_order_release);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
                [self.delegate didUpdateForProperty:@"duration"];
                std::atomic_store_explicit(&updateTS, [[NSDate date] timeIntervalSince1970], std::memory_order_release);
            }
        }
        
    }
}

- (CFTimeInterval)duration {
    return std::atomic_load_explicit(&_duration, std::memory_order_acquire);
}

- (void)setMemoryUsage:(double)memoryUsage {
    std::atomic_store_explicit(&_memoryUsage, memoryUsage, std::memory_order_release);
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"memoryUsage"];
        }
    }
    
}

- (double)memoryUsage {
    return std::atomic_load_explicit(&_memoryUsage, std::memory_order_acquire);
}

- (void)setDeviceMemoryUsage:(double)deviceMemoryUsage {
    std::atomic_store_explicit(&_deviceMemoryUsage, deviceMemoryUsage, std::memory_order_release);
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"deviceMemoryUsage"];
        }
    }
}

- (double)deviceMemoryUsage {
    return std::atomic_load_explicit(&_deviceMemoryUsage, std::memory_order_acquire);
}

- (void)setFreeDisk:(double)freeDisk {
    std::atomic_store_explicit(&_freeDisk, freeDisk, std::memory_order_release);
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"freeDisk"];
        }
    }
    
}

- (double)freeDisk {
    return std::atomic_load_explicit(&_freeDisk, std::memory_order_acquire);
}

- (void)setFreeMemory:(double)freeMemory {
    std::atomic_store_explicit(&_freeMemory, freeMemory, std::memory_order_release);
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"freeMemory"];
        }
    }
    
}

- (double)freeMemory {
    return std::atomic_load_explicit(&_freeMemory, std::memory_order_acquire);
}

- (void)setCustomParams:(NSDictionary<NSString *,id> *)customParams {
    [self.accessLock lock];
    _customParams = customParams;
    [self.accessLock unlock];
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"customParams"];
        }
    }
    
}

- (NSDictionary<NSString *,id> *)customParams {
    NSDictionary<NSString *,id> *result;
    [self.accessLock lock];
    result = _customParams;
    [self.accessLock unlock];
    return result;
}

- (void)setFilters:(NSDictionary<NSString *,id> *)filters {
    [self.accessLock lock];
    _filters = filters;
    [self.accessLock unlock];
    
    if (hermas_enabled()) {
        if ([self.delegate respondsToSelector:@selector(didUpdateWithSessionDic:)]) {
            [self.delegate didUpdateWithSessionDic:[self dictionaryValue]];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didUpdateForProperty:)]) {
            [self.delegate didUpdateForProperty:@"filters"];
        }
    }
}

- (NSDictionary<NSString *,id> *)filters {
    NSDictionary<NSString *,id> *result;
    [self.accessLock lock];
    result = _filters;
    [self.accessLock unlock];
    return result;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:@(self.localID) forKey:@"localID"];
    [dic setValue:self.sessionID forKey:@"sessionID"];
    [dic setValue:@(self.duration) forKey:@"duration"];
    [dic setValue:@(self.memoryUsage) forKey:@"memoryUsage"];
    [dic setValue:@(self.deviceMemoryUsage) forKey:@"deviceMemoryUsage"];
    [dic setValue:@(self.freeMemory) forKey:@"freeMemory"];
    [dic setValue:@(self.freeDisk) forKey:@"freeDisk"];
    [dic setValue:@(self.timestamp) forKey:@"timestamp"];
    [dic setValue:@(self.backgroundStatus) forKey:@"backgroundStatus"];
    [dic setValue:self.eternalSessionID forKey:@"eternalSessionID"];
    [dic setValue:self.appVersion forKey:@"app_version"];
    [dic setValue:self.osVersion forKey:@"os_version"];
    [dic setValue:self.buildVersion forKey:@"buildVersion"];
    [dic setValue:self.sdkVersion forKey:@"sdk_version"];
    [dic setValue:self.customParams forKey:@"customParams"];
    [dic setValue:self.filters forKey:@"filters"];
    return [dic copy];
}

#pragma mark - Optimizing processing speed

- (std::atomic<double> *)ivarAddressForAtomicDoubleType:(NSString *)ivarName {
    if([@[@"duration", @"_duration"] containsObject:ivarName]) return &_duration;
    else if([@[@"memoryUsage", @"_memoryUsage"] containsObject:ivarName]) return &_memoryUsage;
    else if([@[@"freeDisk", @"_freeDisk"] containsObject:ivarName]) return &_freeDisk;
    else if([@[@"freeMemory", @"_freeMemory"] containsObject:ivarName]) return &_freeMemory;
    return NULL;
}

#pragma mark - KVC compatibility

- (void)setValue:(id)value forKey:(NSString *)key {
    if(key == nil) return;
    std::atomic<double> *propertyAddress;
    if((propertyAddress = [self ivarAddressForAtomicDoubleType:key]) != NULL) {
        if([value isKindOfClass:NSNumber.class]) {
            double val = [value doubleValue];
            std::atomic_store_explicit(propertyAddress, val, std::memory_order_release);
        }
    }
    else if([key isEqualToString:@"localID"]) {
        if([value isKindOfClass:NSNumber.class]) {
            NSUInteger val = [value unsignedIntegerValue];
            std::atomic_store_explicit(&_localID, val, std::memory_order_release);
        }
    }
    else [super setValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key {
    std::atomic<double> *propertyAddress;
    if((propertyAddress = [self ivarAddressForAtomicDoubleType:key]) != NULL) {
        return @((double)std::atomic_load_explicit(propertyAddress, std::memory_order_acquire));
    }
    else if([key isEqualToString:@"localID"]) {
        return @((NSUInteger)std::atomic_load_explicit(&_localID, std::memory_order_acquire));
    }
    return [super valueForKey:key];
}

#pragma mark - BGTool compatibility

+ (NSString *)HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:(NSString *)ivarNameWithoutPrefixUnderscore {
    if([@[@"duration", @"memoryUsage", @"freeDisk", @"freeMemory"] containsObject:ivarNameWithoutPrefixUnderscore])
        return [NSString stringWithUTF8String:@encode(double)];
    if([ivarNameWithoutPrefixUnderscore isEqualToString:@"localID"])
        return [NSString stringWithUTF8String:@encode(NSUInteger)];
    return nil;
}

#pragma todo deprecated
+ (NSString *)tableName {
    return NSStringFromClass(self);
}

+ (NSArray *)bg_ignoreKeys {
    return @[@"delegate",@"timeInSession",@"accessLock"];
}

@end
