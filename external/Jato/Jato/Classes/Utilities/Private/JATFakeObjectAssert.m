//
// JATFakeObject.m
// 
//
// Created by Aircode on 2022/8/12

#import "JATFakeObjectAssert.h"
#import "JATAnyCallForwarder.h"
#import <Heimdallr/HMDUserExceptionTracker.h>

@implementation JATFakeObjectAssert

- (instancetype)initWithTarget:(id)target uploadException:(BOOL)uploadException {
    _target = target;
    _exceptionUpload = uploadException;
    return self;
}

+ (instancetype)useFakeObjAssertWithTarget:(id)target uploadException:(BOOL)uploadException {
    return [[self alloc]initWithTarget:target uploadException:uploadException];
}

- (id)forwardingTargetForSelector:(SEL)selector {
#ifdef DEBUG
    NSAssert(NO, @"Jat fatal error. this object does not expect to be call, you can connact developer @zhangxiao.ryan");
#endif
    if (_exceptionUpload) {
        [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"jat_fake_object_use_exception" skippedDepth:0 customParams:nil filters:nil callback:nil];
    }
    if (_target) {
        return _target;
    }
    return JATAnyCallForwarder.class;
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

@end
