//
//  HMDDelegateProxy.m
//  Heimdallr
//
//  Created by 谢俊逸 on 25/1/2018.
//

#import "HMDDelegateProxy.h"

#if __has_feature(modules)
@import ObjectiveC.message;
#else
#import <objc/runtime.h>
#endif

//placeholer IMP to prevent crash
void dynamicAdditionProxyMethodIMP(id self, SEL _cmd) {
}

@interface HMDPlaceHolder : NSObject
+ (instancetype)sharedInstance;
@end

@implementation HMDPlaceHolder : NSObject
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static HMDPlaceHolder *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMDPlaceHolder alloc] init];
    });
    
    return sharedInstance;
}

+ (BOOL)resolveInstanceMethod:(SEL)selector {
    return class_addMethod(self,selector,(IMP)dynamicAdditionProxyMethodIMP, "v@:");
}
@end


@interface HMDDelegateProxy()
@property (nonatomic, weak, readwrite) id _Nullable target;
@end

@implementation HMDDelegateProxy

// 需要重写的方法
+ (instancetype)proxyWithTarget:(id)target consignor:(id)consignor {
    HMDDelegateProxy *proxy = [[HMDDelegateProxy alloc] initWithTarget:target consignor:consignor];
    return proxy;
}

- (instancetype)initWithTarget:(id)target consignor:(id)consignor {
    _target = target;
    _consignor = consignor;
    return self;
}

- (void)dealloc {
    _consignor = nil;
}

/// 需要重写的方法
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if (!self.target) {
        self.target = [HMDPlaceHolder sharedInstance];
    }
    
    if ([self.target isKindOfClass:[HMDPlaceHolder class]] && ![self.target respondsToSelector:selector]) {
        if((class_addMethod([HMDPlaceHolder class],selector,(IMP)dynamicAdditionProxyMethodIMP, "v@:"))==NO) {
            HMDPrint("HMDDelegateProxy forwardingTargetForSelector failed to add target method to class");
        }
    }
    
    return self.target;
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.target respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.target];
    }
}
- (BOOL)isEqual:(id)object {
    return [self.target isEqual:object];
}

- (NSUInteger)hash {
    return [self.target hash];
}

- (Class)superclass {
    return [self.target superclass];
}

- (Class)class {
    return [self.target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [self.target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [self.target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [self.target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [self.target description];
}

- (NSString *)debugDescription {
    return [self.target debugDescription];
}

@end
