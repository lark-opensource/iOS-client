//
//  HMDSimpleBackgroundTask.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/22.
//

#include "pthread_extended.h"
#import "HMDSimpleBackgroundTask.h"
#import "UIApplication+HMDUtility.h"

#define HMDSimpleBackgroundTask_ExpireTime_NO_EXPIRE -1.0

static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;

@implementation HMDSimpleBackgroundTask {
    NSString *_name;
    volatile UIBackgroundTaskIdentifier _identifer;
    volatile BOOL _isEnded;
}

+ (NSMutableArray<HMDSimpleBackgroundTask *> *)currentBackgroundTask {
    static NSMutableArray<HMDSimpleBackgroundTask *> *array;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        array = [NSMutableArray array];
    });
    return array;
}

+ (void)detachBackgroundTaskWithName:(NSString *)name
                          expireTime:(NSTimeInterval)expireTime
                                task:(HMDSimpleBackgroundTaskBlock)customWork {
    NSAssert(name != nil && customWork != nil,
             @"[FATAL ERROR] Please preserve current environment"
              " and contact Heimdallr developer ASAP.");
    if(name != nil && customWork != nil) {
        HMDSimpleBackgroundTask *task = [[HMDSimpleBackgroundTask alloc] initWithName:name];
        pthread_mutex_lock(&mtx);
        NSMutableArray<HMDSimpleBackgroundTask *> *allBGTasks = [HMDSimpleBackgroundTask currentBackgroundTask];
        if([allBGTasks containsObject:task]) {
            pthread_mutex_unlock(&mtx);
            return;
        }
        pthread_mutex_unlock(&mtx);
        
        UIBackgroundTaskIdentifier identifier =
        [[UIApplication hmdSharedApplication] beginBackgroundTaskWithName:name
                                                     expirationHandler:^{
                                                         // retained here
                                                         [task completeBackgroundTask];
                                                     }];
        
        if(identifier != UIBackgroundTaskInvalid) {
            __atomic_store_n(&task->_identifer, identifier, __ATOMIC_RELEASE);  // It is correct
            
            pthread_mutex_lock(&mtx);
            [allBGTasks addObject:task];        // The correct place to add task to allBGTasks
            pthread_mutex_unlock(&mtx);
            
            if(expireTime != HMDSimpleBackgroundTask_ExpireTime_NO_EXPIRE && expireTime > 0.0) {
                NSTimer *timer = [NSTimer timerWithTimeInterval:expireTime target:task selector:@selector(completeBackgroundTaskFromTimer:) userInfo:nil repeats:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
                });
            }
            
            void (^terminateCallback)(void) = ^ {
                // retained here
                [task completeBackgroundTask];
            };
            customWork(terminateCallback);
        }
        else {
            NSAssert(NO,
                     @"[WARING] Launch background task failed."
                      " All related task could not complete.");
        }
    }
}

+ (void)detachBackgroundTaskWithName:(NSString *)name
                                task:(HMDSimpleBackgroundTaskBlock)customWork {
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:name expireTime:HMDSimpleBackgroundTask_ExpireTime_NO_EXPIRE task:customWork];
}

+ (void)endBackgroundTaskWithName:(NSString *)name {
    __block HMDSimpleBackgroundTask *thisTask;
    pthread_mutex_lock(&mtx);
    NSMutableArray<HMDSimpleBackgroundTask *> *allBGTasks = [HMDSimpleBackgroundTask currentBackgroundTask];
    [allBGTasks enumerateObjectsUsingBlock:^(HMDSimpleBackgroundTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        if([task->_name isEqualToString:name]) {
            thisTask = task;
            *stop = YES;
        }
    }];
    pthread_mutex_unlock(&mtx);
    [thisTask completeBackgroundTask];
}

- (void)completeBackgroundTask {
    UIBackgroundTaskIdentifier identifier;
    while((identifier = __atomic_load_n(&self->_identifer, __ATOMIC_ACQUIRE)) == UIBackgroundTaskInvalid)
        continue;   // SPIN-LOCK
    
    BOOL expected = NO;
    if(__atomic_compare_exchange_n(&_isEnded, &expected, YES, NO, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        [[UIApplication hmdSharedApplication] endBackgroundTask:_identifer];
        pthread_mutex_lock(&mtx);
        NSMutableArray<HMDSimpleBackgroundTask *> *allBGTasks = [HMDSimpleBackgroundTask currentBackgroundTask];
        [allBGTasks removeObject:self];
        pthread_mutex_unlock(&mtx);
    }
}

- (void)completeBackgroundTaskFromTimer:(NSTimer *)timer {
    /* currently in main thread */
    [self completeBackgroundTask];
}

- (instancetype)initWithName:(NSString *)name {
    if(self = [super init]) {
        _name = name;
        _identifer = UIBackgroundTaskInvalid;
    }
    return self;
}

- (NSUInteger)hash {
    return _name.length;
}

- (BOOL)isEqual:(id)object {
    if(object != nil &&
       [object isKindOfClass:HMDSimpleBackgroundTask.class] &&
       [_name isEqualToString:((HMDSimpleBackgroundTask *)object)->_name])
        return YES;
    return NO;
}

#ifdef DEBUG

- (void)dealloc {
    UIBackgroundTaskIdentifier identifier;
    identifier = __atomic_load_n(&_identifer, __ATOMIC_ACQUIRE);
    if(identifier != UIBackgroundTaskInvalid) {
        BOOL ended;
        ended = __atomic_load_n(&_isEnded, __ATOMIC_ACQUIRE);
        NSAssert(ended, @"[FATAL ERROR] Please preserve current environment"
                         " and contact Heimdallr developer ASAP.");
    }
}

#endif

@end
