//
//  HTSServiceCenter.m
//  LiveStreaming
//
//  Created by denggang on 16/7/13.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "HTSServiceCenter.h"
#import <objc/runtime.h>
#import "HTSServiceInterceptor.h"

id hts_get_protocol(Protocol *prot) {
    return [[HTSServiceCenter defaultCenter] getProtocolService:prot];
}

Class hts_get_class(Protocol *prot) {
    return [[HTSServiceCenter defaultCenter] getStatelessProtocolService:prot];
}
            
id hts_get_service(Class clz) {
    return [[HTSServiceCenter defaultCenter] getService:clz];
}

void hts_bind_protocol(Class clz, Protocol *prot) {
    [[HTSServiceCenter defaultCenter] bindClass:clz toProtocol:prot];
}

void hts_unbind_protocol(Protocol *prot) {
    [[HTSServiceCenter defaultCenter] unbindProtocol:prot];
}

void hts_remove_service(Class clz) {
    [[HTSServiceCenter defaultCenter] removeService:clz];
}

#if DEBUG
id HTSFakeMethodIMP(id self, SEL _cmd) {
    NSLog(@"ServiceKit invalid call: +[%@ %@]", NSStringFromClass(self), NSStringFromSelector(_cmd));
    return nil;
}

id HTSFakeInstanceIMP(id self, SEL _cmd) {
    NSLog(@"ServiceKit invalid call: -[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

@interface HTSFakeService : HTSService<HTSService>

@end

@implementation HTSFakeService

- (void)onServiceInit { }

+ (BOOL)resolveClassMethod:(SEL)name
{
    class_addMethod(objc_getMetaClass(NSStringFromClass(self.class).UTF8String), name, (IMP)HTSFakeMethodIMP, "@@:");
    return YES;
}

+ (BOOL)resolveInstanceMethod:(SEL)name
{
    class_addMethod(self.class, name, (IMP)HTSFakeInstanceIMP, "@@:");
    return YES;
}

@end
#endif

@interface HTSServiceCenter (){
    NSMutableDictionary *p_hashService;
    NSMutableDictionary *p_hashProtocolService;
    NSRecursiveLock     *p_lock;
}
@end

@implementation HTSServiceCenter

#if DEBUG
static BOOL kDebugAssertOn = YES;
#else
static BOOL kDebugAssertOn = NO;
#endif

+ (void)setDebugAssertOn:(BOOL)debugAssertOn
{
    kDebugAssertOn = debugAssertOn;
}

+ (BOOL)debugAssertOn
{
    return kDebugAssertOn;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (instancetype)init
{
    self = [super init];
    if(self){
        p_hashService = [[NSMutableDictionary alloc] init];
        p_hashProtocolService = [[NSMutableDictionary alloc] init];
        p_lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if(p_hashService != nil){
        p_hashService = nil;
    }
    
    p_lock = nil;
}

#pragma mark - Public

+ (HTSServiceCenter *)defaultCenter
{
    static HTSServiceCenter *serviceCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serviceCenter = [[HTSServiceCenter alloc] init];
    });
    return serviceCenter;
}

- (id)getService:(Class)cls
{
    Class<HTSServiceInterceptor> interceptor = getInterceptor();
    if(interceptor && [interceptor shouldIgnoreService:cls]){
        return nil;
    }
    [p_lock lock];
    id obj = [p_hashService objectForKey:cls];
    if(obj == nil) {
        if(![cls isSubclassOfClass:[HTSService class]]) {
            [p_lock unlock];
            SK_NSAssert(0, @"%@ must inherit HTSService", NSStringFromClass(cls));
            return nil;
        }
        
        if(![cls conformsToProtocol:@protocol(HTSService)]) {
            [p_lock unlock];
            SK_NSAssert(0, @"%@ must conforms to protocol HTSService", NSStringFromClass(cls));
            return nil;
        }
        
        obj = [[cls alloc] init];
        [p_hashService setObject:obj forKey:(id<NSCopying>)cls];
        [p_lock unlock];
        
        if([obj respondsToSelector:@selector(onServiceInit)]) {
            [obj onServiceInit];
        }
    } else {
        [p_lock unlock];
    }
    
    return obj;
}

- (void)removeService:(Class)cls
{
    [p_lock lock];
    HTSService<HTSService> *obj = [p_hashService objectForKey:cls];
    
    if(obj == nil){
        [p_lock unlock];
        return ;
    }
    
    [p_hashService removeObjectForKey:cls];
    
    obj.isServiceRemoved = YES;
    [p_lock unlock];
    obj = nil;
}

//Need caller to insure thread safe
FOUNDATION_EXPORT Class HTSCompileServiceForProtocol(Protocol *protocol);
FOUNDATION_EXPORT Class HTSRemoveCompileServiceForProtocol(Protocol * protocol);

static Class<HTSServiceInterceptor> getInterceptor(){
    static Class<HTSServiceInterceptor> cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString * className = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"HTSServiceInterceptor"];
        cls = NSClassFromString(className);
#if DEBUG
        if (className && !cls) {
            [NSException raise:@"HTSInvalidInterceptorException" format:@"%@ is not a valid className",className];
        }
        if (cls && ![cls conformsToProtocol:@protocol(HTSServiceInterceptor)]) {
            [NSException raise:@"HTSInvalidInterceptorException" format:@"%@ not conforms to HTSServiceInterceptor",className];
        }
#endif
    });
    return cls;
}

- (id)getProtocolService:(Protocol *)protocol
{
    NSParameterAssert(protocol);
    Class<HTSServiceInterceptor> interceptor = getInterceptor();
    if(interceptor && [interceptor shouldIgnoreProtocol:protocol]){
        return nil;
    }

    NSString *protocolName = NSStringFromProtocol(protocol);
    [p_lock lock];
    Class cls = [p_hashProtocolService objectForKey:protocolName];
    if (!cls) {
        cls = HTSCompileServiceForProtocol(protocol);
    }
    [p_lock unlock];
    if (!cls) {
        cls = NSClassFromString(protocolName);
    }
#if DEBUG
    if (cls) {
        SK_NSAssert([cls conformsToProtocol:protocol], @"%@ must conforms to protocol %@", NSStringFromClass(cls), protocolName);
    } else {
        SK_NSAssert(!HTSServiceCenter.debugAssertOn, @"Could not find implement of protocol %@", protocolName);
        Class servicecls = [self getStatelessProtocolService:protocol];
        cls = servicecls;
    }
#endif
    return [self getService:cls];
}

- (Class)getStatelessProtocolService:(Protocol *)protocol
{
    NSParameterAssert(protocol);
    Class<HTSServiceInterceptor> interceptor = getInterceptor();
    if(interceptor && [interceptor shouldIgnoreProtocol:protocol]){
        return nil;
    }
    NSString *protocolName = NSStringFromProtocol(protocol);
    [p_lock lock];
    Class cls = [p_hashProtocolService objectForKey:protocolName];
    if (!cls) {
        cls = HTSCompileServiceForProtocol(protocol);
    }
    [p_lock unlock];
    if (!cls) {
        cls = NSClassFromString(protocolName);
    }
    
#if DEBUG
    if (cls) {
        SK_NSAssert([cls conformsToProtocol:protocol], @"%@ must conforms to protocol %@", NSStringFromClass(cls), protocolName);
    } else {
        SK_NSAssert(!HTSServiceCenter.debugAssertOn, @"Could not find implement of protocol %@", protocolName);
        const char *subclassName = [NSStringFromClass(HTSFakeService.class) stringByAppendingFormat:@"_%@", NSStringFromProtocol(protocol)].UTF8String;
        Class subclass = objc_getClass(subclassName);
        if (subclass == nil) {
            subclass = objc_allocateClassPair(HTSFakeService.class, subclassName, 0);
            if (subclass == nil) {
                NSCAssert(NO, @"objc_allocateClassPair failed to allocate class %s.", subclassName);
                return nil;
            }
            objc_registerClassPair(subclass);
        }
        return subclass;
    }
#endif
    
    return cls;
}

- (Class)getClassFromProtocol:(Protocol *)protocol
{
    NSParameterAssert(protocol);
    NSString *protocolName = NSStringFromProtocol(protocol);
    [p_lock lock];
    Class cls = [p_hashProtocolService objectForKey:protocolName];
    if (!cls) {
        cls = HTSRemoveCompileServiceForProtocol(protocol);
    }
    [p_lock unlock];
    if (!cls) {
        cls = NSClassFromString(protocolName);
    }
    return cls;
}

- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol
{
    NSParameterAssert(cls && [cls conformsToProtocol:@protocol(HTSService)]);
    NSParameterAssert(protocol);

    NSString *protocolName = NSStringFromProtocol(protocol);
#if DEBUG
    if ([p_hashProtocolService objectForKey:protocolName]) {
        SK_NSAssert(NO, @"Bind protocol %@ twice", protocolName);
    }
#endif
    [p_lock lock];
    [p_hashProtocolService setObject:cls forKey:protocolName];
    [p_lock unlock];
}

- (void)unbindProtocol:(Protocol *)protocol
{
    NSParameterAssert(protocol);
    NSString *protocolName = NSStringFromProtocol(protocol);
    [p_lock lock];
    Class cls = [p_hashProtocolService objectForKey:protocolName];
    [p_hashProtocolService removeObjectForKey:protocolName];
    if (!cls) {
        cls = HTSRemoveCompileServiceForProtocol(protocol);
    }
    [p_lock unlock];
    if (!cls) {
        cls = NSClassFromString(protocolName);
    }
    [self removeService:cls];
}

- (void)callEnterForeground
{
    [p_lock lock];
    NSArray *aryCopy = [p_hashService allValues];
    [p_lock unlock];
    
    for(id obj in aryCopy) {
        if([obj respondsToSelector:@selector(onServiceEnterForeground)]) {
            [obj onServiceEnterForeground];
        }
    }
}

- (void)callEnterBackground
{
    [p_lock lock];
    NSArray *aryCopy = [p_hashService allValues];
    [p_lock unlock];
    
    for(id obj in aryCopy) {
        if ([obj respondsToSelector:@selector(onServiceEnterBackground)]) {
            [obj onServiceEnterBackground];
        }
    }
}

- (void)callTerminate
{
    [p_lock lock];
    NSArray *aryCopy = [p_hashService allValues];
    [p_lock unlock];
    
    for(id obj in aryCopy) {
        if ([obj respondsToSelector:@selector(onServiceTerminate)]) {
            [obj onServiceTerminate];
        }
    }
}

- (void)callServiceMemoryWarning
{
    [p_lock lock];
    NSArray *aryCopy = [p_hashService allValues];
    [p_lock unlock];
    
    for(id obj in aryCopy) {
        if([obj respondsToSelector:@selector(onServiceMemoryWarning)]) {
            [obj onServiceMemoryWarning];
        }
    }
}

- (void)callClearData
{
    [p_lock lock];
    NSArray *aryCopy = [p_hashService allValues];
    [p_lock unlock];
    
    for(HTSService<HTSService> *obj in aryCopy) {
        if([obj respondsToSelector:@selector(onServiceClearData)]) {
            [obj onServiceClearData];
        }
        
        if(obj.isServicePersistent == NO) {
            [self removeService:[obj class]];
        }
    }
}

#pragma clang diagnostic pop

@end
