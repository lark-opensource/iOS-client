//
//  BDPWeakProxy.m
//  Timor
//
//  Created by 王浩宇 on 2018/11/26.
//

#import "BDPWeakProxy.h"
#import <ECOInfra/BDPLog.h>
#import <objc/runtime.h>

@interface BDPWeakProxy ()

@property (nonatomic, copy) NSString *objectClassName;
@property (nonatomic, assign) SEL selector;

@end

@implementation BDPWeakProxy

+ (instancetype)weakProxy:(id)object
{
    return [[BDPWeakProxy alloc] initWithObject:object];
}

- (instancetype)initWithObject:(id)object
{
    self.object = object;
    return self;
}

#pragma mark - Setter
- (void)setObject:(id)object {
    _object = object;
    if (object) {
        // 记录下name, 如果target没鸟, 重定向的时候进入兜底打alog用
        _objectClassName = NSStringFromClass([object class]);
    }
}

#pragma mark - 兜底保护
- (void)objectHasBeenReleased {
    BDPLogWarn(@"[BDPWeakProxy] send msg(%@) to object(%@) which has been released",
               _selector ? NSStringFromSelector(_selector) : @"unknown",
               _objectClassName ?: @"unknown");
}

#pragma mark - Override
- (BOOL)isProxy {
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    self.selector = selector; // 记录最近调用的SEL
    return _object;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 走到这的话, 已经完犊子, target没了, 进兜底吧
    [self objectHasBeenReleased];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    // 如果到这一步, 意味着_object已经释放了
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_object respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_object isEqual:object];
}

- (NSUInteger)hash {
    return [_object hash];
}

- (Class)superclass {
    return [_object superclass];
}

- (Class)class {
    return [_object class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_object isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_object isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_object conformsToProtocol:aProtocol];
}

- (NSString *)description {
    return [_object description];
}

- (NSString *)debugDescription {
    return [_object debugDescription];
}

@end


@implementation NSObject (BDPWeakProxy)

- (BDPWeakProxy *)bdp_weakProxy {
    if ([self isKindOfClass:[BDPWeakProxy class]]) {
        return (BDPWeakProxy *)self;
    }
    BDPWeakProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [BDPWeakProxy weakProxy:self];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

@end
