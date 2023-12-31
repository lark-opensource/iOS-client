//
//  TSPKLock.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/30.
//

#import "TSPKLock.h"

#include <os/lock.h>
#import <pthread.h>

API_AVAILABLE(ios(10.0))
@interface TSPKUnfairLockImp : NSObject<TSPKLock>
{
    os_unfair_lock _lock;
}

@end

@implementation TSPKUnfairLockImp

- (instancetype)init {
    if (self = [super init]) {
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (void)lock {
    os_unfair_lock_lock(&_lock);
}

- (void)unlock {
    os_unfair_lock_unlock(&_lock);
}

@end

@interface TSPKMutexLockImpl : NSObject<TSPKLock>
{
    pthread_mutex_t _plock;
}

@end

@implementation TSPKMutexLockImpl

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_plock, NULL);
    }
    return self;
}

- (void)lock {
    pthread_mutex_lock(&_plock);
}

- (void)unlock {
    pthread_mutex_unlock(&_plock);
}

@end

@implementation TSPKLockFactory

+ (id<TSPKLock>)getLock
{
    if (@available(iOS 10.0, *)) {
        return [TSPKUnfairLockImp new];
    }
    return [TSPKMutexLockImpl new];
}

@end
