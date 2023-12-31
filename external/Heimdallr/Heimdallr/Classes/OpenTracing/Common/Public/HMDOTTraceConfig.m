//
//  HMDOTTraceConfig.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/6/7.
//

#import "HMDOTTraceConfig.h"
#import "HMDOTTraceConfig+Tools.h"
#include "pthread_extended.h"

NSString *const kHMDTraceParentStr = @"traceparent";

@interface HMDOTTraceConfig ()

@property (nonatomic, copy, readwrite) NSString *serviceName;

@end

@implementation HMDOTTraceConfig

- (instancetype)initWithServiceName:(NSString *)serviceName {
    if (self = [super init]) {
        self.serviceName = serviceName;
        _isForcedUplaod = NO;
        _insertMode = HMDOTTraceInsertModeEverySpanStart;
    }
    return self;
}

@end



@interface HMDOTManagerConfig() {
    pthread_rwlock_t _memoryCacheOverCallbackRWLock;
}

@property (nonatomic, strong, readwrite) NSLock *intervalLock;
@property (nonatomic, assign, readwrite) NSTimeInterval lastInvokeCallbackTime;

@end

@implementation HMDOTManagerConfig

@synthesize memoryCacheOverCallBack = _memoryCacheOverCallBack;

static HMDOTManagerConfig *defaultConfig = nil;

+ (instancetype)defaultConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultConfig = [[HMDOTManagerConfig alloc] init];
    });
    return defaultConfig;
}


- (instancetype)init {
    if (self = [super init]) {
        _enableCacheUnHitLog = NO;
        _maxCacheFileSize = 512;
        _maxMemoryCacheCount = 400;
        _memoryCacheOverCallbackInvokeInterval = 60;
        
        _lastInvokeCallbackTime = -1;
        _intervalLock = [[NSLock alloc] init];
        pthread_rwlock_init(&_memoryCacheOverCallbackRWLock, NULL);
    }
    
    return self;
}

- (void)setMemoryCacheOverCallBack:(HMDOTTraceMemoryCacheOverCallBack)memoryCacheOverCallBack {
    pthread_rwlock_wrlock(&_memoryCacheOverCallbackRWLock);
    _memoryCacheOverCallBack = memoryCacheOverCallBack;
    pthread_rwlock_unlock(&_memoryCacheOverCallbackRWLock);
}

- (HMDOTTraceMemoryCacheOverCallBack)memoryCacheOverCallBack {
    pthread_rwlock_rdlock(&_memoryCacheOverCallbackRWLock);
    HMDOTTraceMemoryCacheOverCallBack callback = _memoryCacheOverCallBack;
    pthread_rwlock_unlock(&_memoryCacheOverCallbackRWLock);
    return callback;
}

- (void)invokeMemoryCacheCallback {
    HMDOTTraceMemoryCacheOverCallBack callback = self.memoryCacheOverCallBack;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    [self.intervalLock lock];
    BOOL isIntervalValid = ((currentTime - self.lastInvokeCallbackTime) >= self.memoryCacheOverCallbackInvokeInterval);
    if ((self.lastInvokeCallbackTime == -1 || isIntervalValid) && callback != NULL) {
        self.lastInvokeCallbackTime = currentTime;
        [self.intervalLock unlock];
        
        callback();
        return;
    }
    [self.intervalLock unlock];
}

- (NSString *)GetEnableCacheUnHitLogStrValue {
    return self.enableCacheUnHitLog ? @"1" : @"0";
}

@end
