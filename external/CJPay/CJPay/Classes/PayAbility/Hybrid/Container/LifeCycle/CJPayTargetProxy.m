//
//  CJPayTargetProxy.m
//  cjpay_hybrid
//
//  Created by shanghuaijun on 2023/3/22.
//

#import "CJPayTargetProxy.h"

@interface CJPayTargetProxy ()
{
    NSHashTable *_subscribers;
}
@end

@implementation CJPayTargetProxy

- (instancetype)init {
    _subscribers = [NSHashTable weakObjectsHashTable];
    return self;
}

#pragma mark - Override
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    for (id obj  in _subscribers) {
        if ([obj conformsToProtocol:aProtocol]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    for (id obj  in _subscribers) {
        if ([obj respondsToSelector:aSelector]) {
            return YES;
        }
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    for (id obj in _subscribers) {
        if ([obj methodSignatureForSelector:sel]) {
            return [obj methodSignatureForSelector:sel];
        }
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    for (id obj in _subscribers) {
        id msg = [obj methodSignatureForSelector:invocation.selector];
        if (msg && [obj respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:obj];
        }
    }
}

#pragma mark - Public
- (void)addSubscriber:(id)subscriber {
    if (subscriber) {
        [_subscribers addObject:subscriber];
    }
}

- (void)removeSubscriber:(id)subscriber {
    if (subscriber) {
        [_subscribers removeObject:subscriber];
    }
}

@end
