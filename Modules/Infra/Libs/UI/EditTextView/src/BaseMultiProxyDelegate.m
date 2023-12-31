//
//  BaseMultiProxyDelegate.m
//  EditTextView
//
//  Created by zc09v on 2020/7/1.
//

#import "BaseMultiProxyDelegate.h"
#import <UIKit/UIKit.h>

//__attribute__(cleanup)修饰一个变量在该变量作用域结束后, 自动调用一个指定的方法
#define DEFER __strong void(^deferBlk)(void) __attribute__((cleanup(defer), unused)) = ^

@interface BaseMultiProxyDelegate()
{
    NSHashTable *_delegates;
    NSLock *_lock;
    BOOL _threadSafe;
}
@end


@implementation BaseMultiProxyDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _lock = [[NSLock alloc] init];
        _threadSafe = false;
    }
    return self;
}

- (instancetype)initThreadSafe {
    self = [self init];
    if (self) {
        _threadSafe = true;
    }
    return self;
}


-(void) unsafeAddDelegate:(id) delegate {
    [self lockIfNeed];
    if (![_delegates containsObject:delegate]) {
        [_delegates addObject:delegate];
    }
    [self unlockIfNeed];
}

-(NSHashTable *)unsafeDelegates {
    [self lockIfNeed];
    NSHashTable *result = [_delegates mutableCopy];
    [self unlockIfNeed];
    return result;
}

-(BOOL)respondsToSelector:(SEL)aSelector {
    DEFER {
        [self unlockIfNeed];
    };
    [self lockIfNeed];
    for(id delegate in _delegates) {
        if([delegate respondsToSelector:aSelector]) {
            return true;
        }
    }
    return [super respondsToSelector:aSelector];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    DEFER {
        [self unlockIfNeed];
    };
    [self lockIfNeed];
    NSMethodSignature *signature;
    for(NSObject *delegate in _delegates) {
        signature = [delegate methodSignatureForSelector:aSelector];
        if (signature != nil) {
            return signature;
        }
    }
    return nil;
}

-(void) forwardInvocation:(NSInvocation *)invocation {
    [self lockIfNeed];
    for(id delegate in _delegates) {
        if([delegate respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:delegate];
        }
    }
    [self unlockIfNeed];
}

-(void)lockIfNeed {
    if (_threadSafe) {
        [_lock lock];
    }
}

-(void)unlockIfNeed {
    if (_threadSafe) {
        [_lock unlock];
    }
}

inline static void defer(__strong void(^*block)(void))
{
    (*block)();
}
@end
