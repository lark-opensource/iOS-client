//
//  IESStaticContainer.m
//  IESInject
//
//  Created by bytedance on 2020/4/7.
//

#import "IESStaticContainer.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <pthread/pthread.h>

@implementation IESServiceScopeBase

- (instancetype)init:(IESContainerProvider)provider
{
    if (self = [super init]) {
        _provider = provider;
    }
    return self;
}

@end

@implementation IESServiceScopeNormal

- (IESInjectScopeType)scope
{
    return IESInjectScopeTypeNormal;
}

@end

@implementation IESServiceScopeWeak

- (IESInjectScopeType)scope
{
    return IESInjectScopeTypeWeak;
}


@end

@implementation IESServiceScopeSingleton

- (IESInjectScopeType)scope
{
    return IESInjectScopeTypeSingleton;
}

@end

struct IESBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;    // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

typedef NS_OPTIONS(int, IESBlockDescriptionFlags) {
    IESBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    IESBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    IESBlockDescriptionFlagsIsGlobal = (1 << 28),
    IESBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    IESBlockDescriptionFlagsHasSignature = (1 << 30)
};

NS_INLINE BOOL IESIsBlock(id _Nullable block) {
    static Class blockClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blockClass = [^{} class];
        while ([blockClass superclass] != NSObject.class) {
            blockClass = [blockClass superclass];
        }
    });

    return [block isKindOfClass:blockClass];
}

NS_INLINE const char *IESBlockSignature(id block) {
    if (!IESIsBlock(block)) {
        return NULL;
    }
    struct IESBlockLiteral *blockLiteral = (__bridge void *)block;
    if (blockLiteral->flags & IESBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockLiteral->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (blockLiteral->flags & IESBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return signature;
    }

    return NULL;
}

NS_INLINE BOOL IESBlockIsProvider(id block, BOOL(^classChecker)(Class cls)) {
    const char *signature = IESBlockSignature(block);
    if (signature == NULL) {
        return NO;
    }
    
    static NSMethodSignature *providerSignature = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IESContainerProvider provider = ^id{
            return nil;
        };
        providerSignature = [NSMethodSignature signatureWithObjCTypes:IESBlockSignature(provider)];
    });
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    if (methodSignature.numberOfArguments == providerSignature.numberOfArguments &&
        methodSignature.frameLength == providerSignature.frameLength &&
        methodSignature.methodReturnLength == providerSignature.methodReturnLength) {
        if (strcmp(methodSignature.methodReturnType, providerSignature.methodReturnType) != 0) {
            NSString *sigString = @(methodSignature.methodReturnType);
            if ([sigString hasPrefix:@"@\""] && // is class
                [sigString hasSuffix:@"\""] && sigString.length > 3) {
                Class candidateClass = NSClassFromString([sigString substringWithRange:NSMakeRange(2, sigString.length - 3)]);
                if (candidateClass != nil) {
                    BOOL matched = classChecker(candidateClass);
                    NSCAssert(matched, @"%@ doesn't match its requirment", candidateClass);
                    return matched;
                }
            }
        }
        return YES;
    }
    return NO;
}

@interface IESStaticContainer ()

@property (nonatomic, strong) NSMutableSet <NSString *> *registeredStaticServices;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *multiRegisteredService;
@property (nonatomic, assign) pthread_mutex_t lock;

@end

@implementation IESStaticContainer

-(instancetype)initWithParentContainer:(IESContainer *)container
{
    if (self = [super initWithParentContainer:container]) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &attr);
#if DEBUG
        _registeredStaticServices = [[NSMutableSet alloc] init];
        unsigned int count;
        Method *methodList = class_copyMethodList([self class], &count);
        for (int i = 0; i < count; i++) {
            Method method = methodList[i];
            NSString * methodName = NSStringFromSelector(method_getName(method));
            if ([methodName hasPrefix:@"provide"] || [methodName hasPrefix:@"multiProvide"]){
                NSArray<NSString *> *protocolNames = [methodName componentsSeparatedByString:@":"];
                for (int i = 1; i < protocolNames.count -1 ; i++) {
                    NSAssert(![_registeredStaticServices containsObject:protocolNames[i]], @"%@ already be static registered in %@ and can not be registered again!", protocolNames[i], [self class]);
                    [_registeredStaticServices addObject:protocolNames[i]];
                }
            }
        }
#endif
    }
    return self;
}

- (id)resolveObject:(id)classOrProtocol
{
    pthread_mutex_lock(&_lock);
    id object = [self resolveCurrentContainerObject:classOrProtocol];
    if (!object) {
        object = [self resolveViaStaticProviders:classOrProtocol];
    }
    pthread_mutex_unlock(&_lock);
    
    if (!object) {
        object = [self resolveParentContainerObject:classOrProtocol];
    }
    return object;
}

- (id)resolveViaStaticProviders:(id)classOrProtocol
{
    NSString *key = nil;
    BOOL isClass = class_isMetaClass(object_getClass(classOrProtocol));
    if (isClass) {
        key = NSStringFromClass(classOrProtocol);
    } else {
        key = NSStringFromProtocol(classOrProtocol);
    }
    
    SEL candidateSelector = NSSelectorFromString(key);
    if ([[self class] respondsToSelector:candidateSelector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        IESServiceScopeBase<IESServiceScopeTypeConvertable> *serviceScope = [[self class] performSelector:candidateSelector];
        #pragma clang diagnostic pop
        if ([serviceScope isKindOfClass:[IESServiceScopeBase class]] &&
            [serviceScope conformsToProtocol:@protocol(IESServiceScopeTypeConvertable)]) {
            if ([serviceScope isKindOfClass:[IESServiceScopeNormal class]] ||
                [serviceScope isKindOfClass:[IESServiceScopeWeak class]]) {
                [self registerProvider:serviceScope.provider forProtocol:classOrProtocol scope:serviceScope.scope];
                return [self resolveCurrentContainerObject:classOrProtocol];
            } else if ([serviceScope isKindOfClass:[IESServiceScopeSingleton class]]) {
                id result = serviceScope.provider();
                [self registerInstance:result forProtocol:classOrProtocol];
                return result;
            }
        } else if (IESBlockIsProvider(serviceScope, ^(Class cls) {
            if (isClass) {
                return [cls isKindOfClass:classOrProtocol];
            } else {
                return [cls conformsToProtocol:classOrProtocol];
            }
        })) {
            IESContainerProvider provider = (IESContainerProvider)serviceScope;
            [self registerProvider:provider forProtocol:classOrProtocol scope:IESInjectScopeTypeNormal];
            return [self resolveCurrentContainerObject:classOrProtocol];
        }
    }
    
    NSString *singletonMethodName = [NSString stringWithFormat:@"provideSingleton:%@:", key];
    NSString *normalMethodName = [NSString stringWithFormat:@"provide:%@:",key];
    NSString *weakMethodName = [NSString stringWithFormat:@"provideWeakObject:%@:",key];
    SEL normalSEL = NSSelectorFromString(normalMethodName);
    SEL singleMethodSEL= NSSelectorFromString(singletonMethodName);
    SEL weakSEL = NSSelectorFromString(weakMethodName);
    
    NSString *oldSingletonMethodName = [NSString stringWithFormat:@"provideSingleton%@", key];
    NSString *oldNormalMethodName = [NSString stringWithFormat:@"provide%@",key];
    NSString *oldWeakMethodName = [NSString stringWithFormat:@"provideWeakObject%@",key];
    SEL oldNormalSEL = NSSelectorFromString(oldNormalMethodName);
    SEL oldSingleMethodSEL= NSSelectorFromString(oldSingletonMethodName);
    SEL oldWeakSEL = NSSelectorFromString(oldWeakMethodName);
    
    if ([self respondsToSelector:singleMethodSEL]) {
        return [self handleSingleMethod:singleMethodSEL withProtocols:@[classOrProtocol] isOldMethod:NO];
    } else if ([self respondsToSelector:normalSEL]) {
        return [self handleNormalMethod:normalSEL withProtocols:@[classOrProtocol] isOldMethod:NO];
    } else if ([self respondsToSelector:weakSEL]) {
        return [self handleWeakMethod:weakSEL withProtocols:@[classOrProtocol] isOldMethod:NO];
    } else if ([self respondsToSelector:oldSingleMethodSEL]) {
        return [self handleSingleMethod:oldSingleMethodSEL withProtocols:@[classOrProtocol] isOldMethod:YES];
    } else if ([self respondsToSelector:oldNormalSEL]) {
        return [self handleNormalMethod:oldNormalSEL withProtocols:@[classOrProtocol] isOldMethod:YES];
    } else if ([self respondsToSelector:oldWeakSEL]) {
        return [self handleWeakMethod:oldWeakSEL withProtocols:@[classOrProtocol] isOldMethod:YES];
    } else {
        NSString *multiServieMethod = [self.multiRegisteredService objectForKey:key];
        if (!multiServieMethod) {
            return nil;
        }
        
        NSArray<NSString *> *protocolNames = [multiServieMethod componentsSeparatedByString:@":"];
        NSMutableArray<Protocol *> *protocols = [[NSMutableArray alloc] init];
        for (int i = 1; i < protocolNames.count - 1; i++) {
            [protocols addObject:NSProtocolFromString(protocolNames[i])];
        }
        
        id object;
        SEL methodName = NSSelectorFromString(multiServieMethod);
        if ([multiServieMethod containsString:@"multiProvideSingleton:"]) {
            object = [self handleSingleMethod:methodName withProtocols:protocols isOldMethod:NO];
        } else if ([multiServieMethod containsString:@"multiProvide:"]) {
            object = [self handleNormalMethod:methodName withProtocols:protocols isOldMethod:NO];
        } else if ([multiServieMethod containsString:@"multiProvideWeakObject:"]) {
            object = [self handleWeakMethod:methodName withProtocols:protocols isOldMethod:NO];
        }
        
        return object;
    }
}


#pragma mark - privateMethod

- (id)handleSingleMethod:(SEL)singleMethod withProtocols:(NSArray<Protocol *> *)protocols isOldMethod:(BOOL)oldMethod
{
    NSUInteger methodParametersCount = 0;
    if (!oldMethod) {
        methodParametersCount = protocols.count + 1;
    }
    
    id object = [self performSelector:singleMethod withparameterCount:methodParametersCount];

    [super registerInstance:object forProtocols:protocols];
    return object;
}


- (id)handleNormalMethod:(SEL)normalMethod withProtocols:(NSArray<Protocol *> *)protocols isOldMethod:(BOOL)oldMethod
{
    NSUInteger methodParametersCount = 0;
    if (!oldMethod) {
        methodParametersCount = protocols.count + 1;
    }
    
    __weak IESStaticContainer *weakSelf = self;
    [super registerProvider:^id _Nonnull() {
        __strong IESStaticContainer *strongSelf = weakSelf;
        if (strongSelf) {
            id object = [strongSelf performSelector:normalMethod withparameterCount:methodParametersCount];
            return object;
        } else {
            return nil;
        }
    } forProtocols:protocols scope:IESInjectScopeTypeNormal];
    
    id object = [self performSelector:normalMethod withparameterCount:methodParametersCount];
    
    return object;
}

- (id)handleWeakMethod:(SEL)weakMethod withProtocols:(NSArray<Protocol *> *)protocols isOldMethod:(BOOL)oldMethod
{
    NSUInteger methodParametersCount = 0;
    if (!oldMethod) {
        methodParametersCount = protocols.count + 1;
    }
    
    __weak IESStaticContainer *weakSelf = self;
    [super registerProvider:^id _Nonnull() {
        __strong IESStaticContainer *strongSelf = weakSelf;
        if (strongSelf) {
            id object = [strongSelf performSelector:weakMethod withparameterCount:methodParametersCount];
            return object;
        } else {
            return nil;
        }
    } forProtocols:protocols scope:IESInjectScopeTypeWeak];
    
    id object = [self resolveCurrentContainerObject:protocols[0]];
    
    return object;
}

#pragma mark - property
-(NSMutableDictionary<NSString *,NSString *> *)multiRegisteredService
{
    if (!_multiRegisteredService) {
        _multiRegisteredService = [[NSMutableDictionary alloc] init];
        NSMutableSet *containerClasses = [[NSMutableSet alloc] init];
        [containerClasses addObject:[self class]];
        Class cls = class_getSuperclass([self class]);
        while ([cls isSubclassOfClass:[IESStaticContainer class]]) {
            [containerClasses addObject:cls];
            cls = class_getSuperclass(cls);
        }
        for (Class containerClass in containerClasses) {
            unsigned int count;
            Method *methodList = class_copyMethodList(containerClass, &count);
            for (int i = 0; i < count; i++) {
                Method method = methodList[i];
                NSString * methodName = NSStringFromSelector(method_getName(method));
                if ([methodName hasPrefix:@"multiProvide"]){
                    NSArray<NSString *> *protocolNames = [methodName componentsSeparatedByString:@":"];
                    for (int i = 1; i < protocolNames.count - 1; i++) {
                        [_multiRegisteredService setObject:methodName forKey:protocolNames[i]];
                    }
                }
            }
            free(methodList);
        }
    }
    return _multiRegisteredService;
}

- (id)performSelector:(SEL)aSelector withparameterCount:(NSUInteger)count
{
    NSAssert(count <= 5, @"Too many parameters. count <= 5");

    id object;
    switch (count) {
        case 0:
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            object = [self performSelector:aSelector];
            #pragma clang diagnostic pop
            break;
        case 1:
            object = ((id (*)(id, SEL, id))(void *) objc_msgSend)(self, aSelector, nil);
            break;
        case 2:
            object = ((id (*)(id, SEL, id, id))(void *) objc_msgSend)(self, aSelector, nil, nil);
            break;
        case 3:
            object = ((id (*)(id, SEL, id, id, id))(void *) objc_msgSend)(self, aSelector, nil, nil, nil);
            break;
        case 4:
            object = ((id (*)(id, SEL, id, id, id, id))(void *) objc_msgSend)(self, aSelector, nil, nil, nil, nil);
            break;
        case 5:
            object = ((id (*)(id, SEL, id, id, id, id, id))(void *) objc_msgSend)(self, aSelector, nil, nil, nil, nil, nil);
            break;
        case 6:
            object = ((id (*)(id, SEL, id, id, id, id, id, id))(void *) objc_msgSend)(self, aSelector, nil, nil, nil, nil, nil, nil);
            break;
        default:
            break;
    }
    return object;
}

#pragma mark - check repeat register

-(void)registerInstance:(id)instance forProtocol:(Protocol *)protocol
{
    NSAssert(![self.registeredStaticServices containsObject:NSStringFromProtocol(protocol)], @"%@ already be static registered in %@ and can not be registered again!", protocol, [self class]);
    [super registerInstance:instance forProtocol:protocol];
}

-(void)registerInstance:(id)instance forProtocols:(NSArray<Protocol *> *)protocols
{
#if DEBUG
    for (Protocol * protocol in protocols) {
        NSAssert(![self.registeredStaticServices containsObject:NSStringFromProtocol(protocol)], @"%@ already be static registered in %@ and can not be registered again!", NSStringFromProtocol(protocol), [self class]);
    }
#endif
    [super registerInstance:instance forProtocols:protocols];
}

-(void)registerProvider:(IESContainerProvider)provider forProtocol:(Protocol *)protocol scope:(IESInjectScopeType)scopeType
{
    NSAssert(![self.registeredStaticServices containsObject:NSStringFromProtocol(protocol)], @"%@ already be static registered in %@ and can not be registered again!", protocol, [self class]);
    [super registerProvider:provider forProtocol:protocol scope:scopeType];
}

-(void)registerProvider:(IESContainerProvider)provider forProtocols:(NSArray<Protocol *> *)protocols scope:(IESInjectScopeType)scopeType
{
#if DEBUG
    for (Protocol * protocol in protocols) {
        NSAssert(![self.registeredStaticServices containsObject:NSStringFromProtocol(protocol)], @"%@ already be static registered in %@ and can not be registered again!", protocol, [self class]);
    }
#endif
    [super registerProvider:provider forProtocols:protocols scope:scopeType];
}

@end
