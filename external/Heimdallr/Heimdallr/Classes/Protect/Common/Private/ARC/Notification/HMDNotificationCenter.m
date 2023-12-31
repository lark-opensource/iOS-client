//
//  HMDNotificationCenter.m
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//
//  线程安全

#import <pthread.h>
#import "HMDNotificationCenter.h"
#import "HMDNotificationConnection.h"
#import "HMDProtectNSNotification.h"
#import "HMDALogProtocol.h"
#import "HMDProtect_Private.h"

pthread_mutex_t g_mutex = PTHREAD_MUTEX_INITIALIZER;

@implementation HMDNotificationCenter {
    NSMutableArray<HMDNotificationConnection *> *_connectionArray;
}

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static HMDNotificationCenter *defaultCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCenter = [[HMDNotificationCenter alloc] init];
    });
    return defaultCenter;
}

- (instancetype)init {
    if(self = [super init]) {
        _connectionArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Control Method of KVO

- (HMDProtectCapture *)addObserver:(id)observer
                          selector:(SEL)aSelector
                              name:(NSNotificationName)aName
                            object:(id)anObject {
    if(observer == nil || aSelector == NULL || CHECK_STRING_INVALID(aName)) {
        if (hmd_upper_trycatch_effective(0)) {
            return nil;
        }
        
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSString *reason = [NSString stringWithFormat:@"-[NSNotificationCenter addObserver:%@ selector:%@ name:%@ object:%@]", observer, selectorName, aName, anObject];
        NSString *crashKey = [NSString stringWithFormat:@"-[NSNotificationCenter addObserver:%@ selector:%@ name:%@ object:%@]", [observer class], selectorName, aName, [anObject class]];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        return capture;
    }
    
    
    HMDNotificationConnection *connection = [[HMDNotificationConnection alloc] initWithObserver:observer
                                                                                       selector:aSelector
                                                                                           name:aName
                                                                                         object:anObject];
    
    int lock_rst = pthread_mutex_lock(&g_mutex);
    [connection active];
    [_connectionArray addObject:connection];
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_mutex);
    }
    
    return nil;
}

- (HMDProtectCapture *)removeObserver:(id)observer {
    if(observer == nil) {
        return nil;
    }
    
    int lock_rst = pthread_mutex_lock(&g_mutex);
    [self removeConnectionForObserver:observer];
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_mutex);
    }
    
    // 无论有没有找到配对，都存在保护开启之前添加的通知，调用原生方法并进行try-catch保护
    HMDProtectCapture *capture = nil;
    @try {
        [NSNotificationCenter.defaultCenter HMDP_removeObserver:observer];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return nil;
        }
        
        NSString *crashKey = [NSString stringWithFormat:@"-[NSNotificationCenter removeObserver:%@]", [observer class]];
        capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
    }
    
    return capture;
}

- (HMDProtectCapture *)removeObserver:(id _Nonnull)observer
                                 name:(NSNotificationName _Nullable)aName
                               object:(id _Nullable)anObject {
    if(observer == nil) {
        return nil;
    }
    
    int lock_rst = pthread_mutex_lock(&g_mutex);
    [self removeConnectionForObserver:observer name:aName object:anObject];
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_mutex);
    }
    
    // 无论有没有找到配对，都存在保护开启之前添加的通知，调用原生方法并进行try-catch保护
    HMDProtectCapture *capture = nil;
    @try {
        [NSNotificationCenter.defaultCenter HMDP_removeObserver:observer name:aName object:anObject];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return nil;
        }
        
        NSString *crashKey = [NSString stringWithFormat:@"-[NSNotificationCenter removeObserver:%@ name:%@ object:%@]", [observer class], aName, [anObject class]];
        capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
    }
    
    return capture;
}

#pragma mark - Supporting Method

- (BOOL)removeConnectionForObserver:(__kindof NSObject * _Nonnull)observer {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    void *observerPtr = (__bridge void *)observer;
    [_connectionArray enumerateObjectsWithOptions:0 usingBlock:^(HMDNotificationConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.observerPtr == observerPtr) {
            [obj deactive];
            [indexSet addIndex:idx];
        }
    }];
    
    if (indexSet.count > 0) {
        [_connectionArray removeObjectsAtIndexes:indexSet];
        return YES;
    }
        
    return NO;
}

- (BOOL)removeConnectionForObserver:(__kindof NSObject * _Nonnull)observer name:(NSString *)aName object:anObject {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    void *observerPtr = (__bridge void *)observer;
    [_connectionArray enumerateObjectsWithOptions:0 usingBlock:^(HMDNotificationConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.observerPtr != observerPtr) {
            return;
        }
        
        if(aName != nil && (obj.name == nil || ![obj.name isEqualToString:aName])) {
            return;
        }
        
        if(anObject != nil && (obj.object == nil || obj.object != anObject)) {
            return;
        }
        
        [obj deactive];
        [indexSet addIndex:idx];
    }];

    if(indexSet.count > 0) {
        [_connectionArray removeObjectsAtIndexes:indexSet];
        return YES;
    }
    
    return NO;
}

- (void)asyncCleanUpInvalidConnection {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int lock_rst = pthread_mutex_lock(&g_mutex);
        __block NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
        [self->_connectionArray enumerateObjectsUsingBlock:^(HMDNotificationConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj valid]) {
                [indexSet addIndex:idx];
                [obj deactive];
            }
        }];
        
        if (indexSet.count > 0) {
            [self->_connectionArray removeObjectsAtIndexes:indexSet];
        }
        
        if (lock_rst == 0) {
        pthread_mutex_unlock(&g_mutex);
    }
    });
}


@end
