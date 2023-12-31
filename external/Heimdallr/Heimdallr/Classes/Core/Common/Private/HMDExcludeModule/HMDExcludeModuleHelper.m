//
//  HMDExcludeModuleHelper.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/16.
//

#include "HMDMacro.h"
#import "HMDExcludeModuleHelper.h"
#include "pthread_extended.h"

#define HMDExcludeModuleHelperTimeoutDefault 10.0
#define HMDExcludeModuleHelperTimeoutMin 1.0
#define HMDExcludeModuleHelperTimeoutMax 50.0

@implementation HMDExcludeModuleHelper {
    HMDExcludeModuleCallback _Nullable _successCallback;
    HMDExcludeModuleCallback _Nullable _failureCallback;
    HMDExcludeModuleCallback _Nullable _timeoutCallback;
    NSMutableArray<id<HMDExcludeModule>> *_finishArray;
    NSMutableArray<id<HMDExcludeModule>> *_successArray;
    NSMutableArray<id<HMDExcludeModule>> *_failureArray;
    pthread_mutex_t _mtx;
}

@synthesize timeout = _timeout,
            started = _started,
           finished = _finished;

+ (id<HMDExcludeModule> _Nullable)excludeModuleForRuntimeClassName:(NSString *)className {
    if(className == nil) DEBUG_RETURN(nil);
    
    Class aClass; id<HMDExcludeModule> module;
    if(className != nil &&
       (aClass = NSClassFromString(className)) != nil &&
       [aClass conformsToProtocol:@protocol(HMDExcludeModule)] &&
       (module = [aClass excludedModule]) != nil) {
        return module;
    }
    return nil;
}

+ (BOOL)verifyExcludeModuleResultWithRuntimeClassName:(NSString *)className res:(BOOL *)res_output{
    if(className == nil || res_output == NULL) DEBUG_RETURN(NO);
    
    id<HMDExcludeModule> _Nullable module;
    if((module = [HMDExcludeModuleHelper excludeModuleForRuntimeClassName:className]) == nil)
        return NO;
    
    res_output[0] = module.finishDetection && module.detected;
    
    return YES;
}

- (instancetype)initWithSuccess:(HMDExcludeModuleCallback _Nullable)successCallback
                        failure:(HMDExcludeModuleCallback _Nullable)failureCallback
                        timeout:(HMDExcludeModuleCallback _Nullable)timeoutCallback {
    if(self = [super init]) {
        _successCallback = successCallback;
        _failureCallback = failureCallback;
        _timeoutCallback = timeoutCallback;
        
        _started = NO;
        _finished = NO;
        _timeout = HMDExcludeModuleHelperTimeoutDefault;

        mutex_init_normal(_mtx);
        _finishArray = [NSMutableArray array];
        _successArray = [NSMutableArray array];
        _failureArray = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    DEBUG_ASSERT(NO);
    return nil;
}

- (void)addRuntimeClassName:(NSString *)className forDependency:(HMDExcludeModuleDependency)dependency {
    DEBUG_ASSERT(className != nil);
    Class aClass; id<HMDExcludeModule> module;
    if(className != nil &&
       (aClass = NSClassFromString(className)) != nil &&
       [aClass conformsToProtocol:@protocol(HMDExcludeModule)] &&
       (module = [aClass excludedModule]) != nil) {
        pthread_mutex_lock(&_mtx);
        if(!_started &&
           ![_successArray containsObject:module] &&
           ![_failureArray containsObject:module] &&
           ![_finishArray containsObject:module]) {
            switch (dependency) {
                case HMDExcludeModuleDependencyFinish:
                    [_finishArray addObject:module];
                    break;
                case HMDExcludeModuleDependencySuccess:
                    [_successArray addObject:module];
                    break;
                case HMDExcludeModuleDependencyFailure:
                    [_failureArray addObject:module];
                    break;
                default:
                    DEBUG_ASSERT(NO);
                    break;
            }
        }
        pthread_mutex_unlock(&_mtx);
    }
}

- (void)addClass:(Class<HMDExcludeModule>)aClass forDependency:(HMDExcludeModuleDependency)dependency {
    DEBUG_ASSERT(aClass != nil);
    id<HMDExcludeModule> module;
    if(aClass != nil &&
       [aClass conformsToProtocol:@protocol(HMDExcludeModule)] &&
       (module = [aClass excludedModule]) != nil) {
        pthread_mutex_lock(&_mtx);
        if(!_started &&
           ![_successArray containsObject:module] &&
           ![_failureArray containsObject:module] &&
           ![_finishArray containsObject:module]) {
            switch (dependency) {
                case HMDExcludeModuleDependencyFinish:
                    [_finishArray addObject:module];
                    break;
                case HMDExcludeModuleDependencySuccess:
                    [_successArray addObject:module];
                    break;
                case HMDExcludeModuleDependencyFailure:
                    [_failureArray addObject:module];
                    break;
                default:
                    DEBUG_ASSERT(NO);
                    break;
            }
        }
        pthread_mutex_unlock(&_mtx);
    }
}

- (void)startDetection {
    pthread_mutex_lock(&_mtx);
    if(_started) {
        pthread_mutex_unlock(&_mtx);
        DEBUG_ASSERT(NO);
        return;
    }
    _started = YES;
    BOOL notDecidedYet = NO;
    CFTimeInterval timeoutSecond = 0.0;
    if(![self detectExcludeSuccess_async]) {        // finished
        
        NSMutableArray<NSString *> *notificationArray = [NSMutableArray array];
        
        for(id<HMDExcludeModule> eachModule in _finishArray) {
            NSString *notificationName = [eachModule finishDetectionNotification];
            if(notificationName != nil) [notificationArray addObject:notificationName];
            DEBUG_ELSE
        }
        
        for(id<HMDExcludeModule> eachModule in _successArray) {
            NSString *notificationName = [eachModule finishDetectionNotification];
            if(notificationName != nil) [notificationArray addObject:notificationName];
            DEBUG_ELSE
        }
        
        for(id<HMDExcludeModule> eachModule in _failureArray) {
            NSString *notificationName = [eachModule finishDetectionNotification];
            if(notificationName != nil) [notificationArray addObject:notificationName];
            DEBUG_ELSE
        }
        
        for(NSString *eachString in notificationArray) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleNotification:)
                                                         name:eachString
                                                       object:nil];
        }
        
        NSMutableArray<id<HMDExcludeModule>> *removeArray = [NSMutableArray array];
        
        for(id<HMDExcludeModule> eachModule in _finishArray) {
            if(eachModule.finishDetection) [removeArray addObject:eachModule];
        }
        [_finishArray removeObjectsInArray:removeArray];
        
        [removeArray removeAllObjects];
        for(id<HMDExcludeModule> eachModule in _successArray) {
            if(eachModule.finishDetection) {
                if(eachModule.detected)
                    [removeArray addObject:eachModule];
                else {
                    _finished = YES;
                    if(_failureCallback) _failureCallback();
                    pthread_mutex_unlock(&_mtx);
                    return;
                }
            }
        }
        [_successArray removeObjectsInArray:removeArray];
        
        [removeArray removeAllObjects];
        for(id<HMDExcludeModule> eachModule in _failureArray) {
            if(eachModule.finishDetection) {
                if(!eachModule.detected)
                    [removeArray addObject:eachModule];
                else {
                    _finished = YES;
                    if(_failureCallback) _failureCallback();
                    pthread_mutex_unlock(&_mtx);
                    return;
                }
            }
        }
        [_failureArray removeObjectsInArray:removeArray];
        if(![self detectExcludeSuccess_async]) {
            notDecidedYet = YES;
            timeoutSecond = _timeout;
        }
    }
    pthread_mutex_unlock(&_mtx);
    
    if(notDecidedYet)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutSecond * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            BOOL needCallback = NO;
            HMDExcludeModuleCallback callback;
            pthread_mutex_lock(&self->_mtx);
            if(!self->_finished) {
                self->_finished = YES;
                needCallback = YES;
                callback = self->_timeoutCallback;
            }
            pthread_mutex_unlock(&self->_mtx);
            if(needCallback && callback != nil) callback();    // IN case callback is nil
        });
}

- (BOOL)detectExcludeSuccess_async {
    if(_finishArray.count == 0 && _failureArray.count == 0 && _successArray.count == 0) {
        _finished = YES;
        if(_successCallback) _successCallback();
        return YES;
    }
    return NO;
}

- (void)handleNotification:(NSNotification *)notification {
    NSString *name = notification.name;
    id<HMDExcludeModule> object = notification.object;
    if(name != nil && [object conformsToProtocol:@protocol(HMDExcludeModule)]) {
        pthread_mutex_lock(&_mtx);
        if(_finished) {
            pthread_mutex_unlock(&_mtx);
            return;
        }
        if([_failureArray containsObject:object]) {
            if(!object.detected) {
                [_failureArray removeObject:object];
                if([self detectExcludeSuccess_async]) {
                    pthread_mutex_unlock(&_mtx);
                    return;
                }
            }
            else {
                _finished = YES;
                if(_failureCallback) _failureCallback();
                pthread_mutex_unlock(&_mtx);
                return;
            }
        }
        else if([_successArray containsObject:object]) {
            if(object.detected) {
                [_successArray removeObject:object];
                if([self detectExcludeSuccess_async]) {
                    pthread_mutex_unlock(&_mtx);
                    return;
                }
            }
            else {
                _finished = YES;
                if(_failureCallback) _failureCallback();
                pthread_mutex_unlock(&_mtx);
                return;
            }
        }
        else if([_finishArray containsObject:object]) {
            [_finishArray removeObject:object];
            if([self detectExcludeSuccess_async]) {
                pthread_mutex_unlock(&_mtx);
                return;
            }
        }
        pthread_mutex_unlock(&_mtx);
    } DEBUG_ELSE
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self]; // weak-referenced [iOS 9.0 or later]
}

#pragma mark - Property Settings

- (void)setTimeout:(NSTimeInterval)timeout {
    if(timeout < HMDExcludeModuleHelperTimeoutMin) timeout = HMDExcludeModuleHelperTimeoutMin;
    else if(timeout > HMDExcludeModuleHelperTimeoutMax) timeout = HMDExcludeModuleHelperTimeoutMax;
    pthread_mutex_lock(&_mtx);
    _timeout = timeout;
    pthread_mutex_unlock(&_mtx);
}

- (NSTimeInterval)timeout {
    pthread_mutex_lock(&_mtx);
    NSTimeInterval result = _timeout;
    pthread_mutex_unlock(&_mtx);
    return result;
}

- (BOOL)isStarted {
    pthread_mutex_lock(&_mtx);
    BOOL result = _started;
    pthread_mutex_unlock(&_mtx);
    return result;
}

- (BOOL)isFinshed {
    pthread_mutex_lock(&_mtx);
    BOOL result = _finished;
    pthread_mutex_unlock(&_mtx);
    return result;
}

@end
