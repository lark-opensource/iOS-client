//
//  HMDURLCacheManager.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/3.
//

#import "HMDURLCacheManager.h"
#import "HMDURLProtocolManager.h"
#import "NSURLCache+HMDCustomCache.h"
#include "pthread_extended.h"
#import "Heimdallr+Private.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"

@interface HMDURLCacheManager ()

@property (nonatomic, strong) NSMutableSet *customCachePath;
@property (nonatomic, assign) BOOL isRunning;

@end

@implementation HMDURLCacheManager {
    pthread_rwlock_t _managedPathRWLock;
}

#pragma mark --- life cycle control
+ (instancetype)sharedInstance {
    static HMDURLCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDURLCacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _customCachePath = [NSMutableSet set];
        pthread_rwlock_init(&_managedPathRWLock, NULL);
    }
    return self;
}

- (void)start {
    pthread_rwlock_wrlock(&_managedPathRWLock);
    if (!_isRunning) {
        _isRunning = YES;
        [NSURLCache hmdExchangeCacheStoreClearMethod];
    }
    pthread_rwlock_unlock(&_managedPathRWLock);
}

- (void)stop {
    pthread_rwlock_wrlock(&_managedPathRWLock);
    if (_isRunning) {
        _isRunning = NO;
    }
    pthread_rwlock_unlock(&_managedPathRWLock);
}

#pragma mark --- public api
- (void)registerCustomCachePath:(NSString *)path {
    if (!path || path.length == 0) { return; }
    if (![path isKindOfClass:[NSString class]]) { return; }
    pthread_rwlock_wrlock(&_managedPathRWLock);
    [self.customCachePath addObject:[path copy]];
    pthread_rwlock_unlock(&_managedPathRWLock);
}

- (void)unregisterCustomCachePath:(NSString *)path {
    if (!path || path.length == 0) { return; }
    if (![path isKindOfClass:[NSString class]]) { return; }
    pthread_rwlock_wrlock(&_managedPathRWLock);
    [self.customCachePath removeObject:[path copy]];
    pthread_rwlock_unlock(&_managedPathRWLock);
}

- (BOOL)checkAvailabaleCustomCachePath:(NSString *)url urlCacheInstance:(NSURLCache *)urlCache {
    if (!url || url.length == 0) { return NO; }
    if (![url isKindOfClass:[NSString class]]) { return NO; }
    BOOL isInstanceEqual = [urlCache isEqual: [HMDURLProtocolManager shared].session.configuration.URLCache];
    if (!isInstanceEqual) {  return NO; }

    pthread_rwlock_rdlock(&_managedPathRWLock);
    if (!_isRunning) {
        pthread_rwlock_unlock(&_managedPathRWLock);
        return NO;
    }

    __block BOOL isAvailable = NO;
    [self.customCachePath enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([url rangeOfString:((NSString *)obj)].location != NSNotFound) {
            isAvailable = YES;
            *stop = YES;
        }
    }];
    pthread_rwlock_unlock(&_managedPathRWLock);
    if (!isAvailable) { return NO; }

    // filter blockList
    BOOL isContainedInList = [[HMDHTTPRequestTracker sharedTracker].trackerConfig isURLInBlockList:url];
    return !isContainedInList;
}

- (BOOL)managerIsRunning {
    BOOL runningState = NO;
    pthread_rwlock_rdlock(&_managedPathRWLock);
    runningState = self.isRunning;
    pthread_rwlock_unlock(&_managedPathRWLock);
    return runningState;
}

@end
