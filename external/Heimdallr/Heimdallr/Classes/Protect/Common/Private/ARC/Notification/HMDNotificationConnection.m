//
//  HMDNotificationConnection.m
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//
// 非线程安全 [由 Center 管理]
// 依赖: KVO 线程安全

#import "HMDProtectNSNotification.h"
#import "HMDNotificationConnection.h"
#import "HMDNotificationCenter.h"
#import "HMDALogProtocol.h"
#import "HMDProtectCapture.h"
#import <malloc/malloc.h>

@implementation HMDNotificationConnection

- (instancetype)initWithObserver:(__kindof NSObject  * _Nonnull)observer
                        selector:(SEL _Nonnull)selector
                            name:(NSNotificationName _Nullable)name
                          object:(__kindof NSObject * _Nullable)object {
    if(self = [super init]) {
        _observer = observer;
        _observerPtr = (__bridge void *)observer;
        _observerSize = malloc_size(_observerPtr);
        _observerClass = object_getClass(observer);
        _selector = selector;
        _name = name;
        _object = object;
        if (object != nil) {
            _objectClass = object_getClass(object);
        }
        else {
            _objectClass = nil;
        }
        
        _actived = NO;
        _crashed = NO;
    }
    
    return self;
}

#pragma mark - Public

- (BOOL)valid {
    // 监听者已释放
    if (_observer == nil) {
        return NO;
    }
    
    // 监听对象已释放
    if (_objectClass != nil && _object == nil) {
        return NO;
    }
    
    return _actived;
}

- (void)active {
    if(_actived) {
        return;
    }
    
    __kindof NSObject *current_observer = _observer;
    if(current_observer != nil) {
        _actived = YES;
        [NSNotificationCenter.defaultCenter HMDP_addObserver:self
                                                    selector:@selector(receiveNotification:)
                                                        name:_name
                                                      object:_object];
    }
}

- (void)deactive {
    if(!_actived) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter HMDP_removeObserver:self name:_name object:_object];
    _actived = NO;
}

#pragma mark - Check Mark

- (void)dealloc {
    [self deactive];
}

#pragma mark - KVO Callback [dispatch thread execution]

- (void)receiveNotification:(NSNotification *)notification {
    if (_crashed) {
        return;
    }
    
    /// 任何情况下 Connection 都不能 disconnect 在当前环境
    __strong __kindof NSObject *current_observer = _observer;
    if(current_observer) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [current_observer performSelector:_selector withObject:notification];
#pragma clang diagnostic pop
        return;
    }
    
    // Observer正在Deallocing，引用计数为0，但内存没有free，还可以响应事件
    size_t size = malloc_size(_observerPtr);
    if (size > 0 && size == _observerSize) {
        Class cls = object_getClass((__bridge NSObject *)(_observerPtr));
        if (cls == _observerClass) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [(__bridge NSObject *)(_observerPtr) performSelector:_selector withObject:notification];
            #pragma clang diagnostic pop
            return;
        }
    }
    
    _crashed = YES;
    if (hmd_upper_trycatch_effective(0)) {
        [HMDNotificationCenter.sharedInstance asyncCleanUpInvalidConnection];
        return;
    }
    
    NSString *observerClassName = NSStringFromClass(_observerClass);
    NSString *selectorName = NSStringFromSelector(_selector);
    NSString *reason = [NSString stringWithFormat:@"-[recieveNotification observer:%@ notificationName:%@ object:%@ selector:%@] observer has released", observerClassName, _name, _object, selectorName];
    NSString *crashKey = [NSString stringWithFormat:@"-[recieveNotification observer:%@ notificationName:%@ object: selector:%@] observer has released", observerClassName, _name, selectorName];
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInternalInconsistencyException" reason:reason crashKey:crashKey];
    HMD_Protect_Notification_captureException(capture);
    [HMDNotificationCenter.sharedInstance asyncCleanUpInvalidConnection];
}

@end
