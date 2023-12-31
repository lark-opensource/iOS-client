//
//  HMDWeakProxy.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDWeakProxy.h"
#import "HMDUSELForwarder.h"

@interface HMDWeakProxy ()

@property (nonatomic, strong) id strongTarget;

@end

@implementation HMDWeakProxy

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

+ (instancetype)proxyWithTarget:(id)target {
    return [[self alloc]initWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if (_target) {
        __strong typeof(_target) strongTarget = _target;
        return strongTarget;
    }
    
    return HMDUSELForwarder.class;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    if ([_target respondsToSelector:sel]) {
        [invocation invokeWithTarget:_target];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_target methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

- (void)retainTarget {
    self.strongTarget = _target;
}

- (void)releaseTarget {
    self.strongTarget = nil;
    
}

@end
