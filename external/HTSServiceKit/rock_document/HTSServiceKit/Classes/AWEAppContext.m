//
//  AWEAppContext.m
//  Pods
//
//  Created by liurihua on 2018/7/20.
//

#import "AWEAppContext.h"

@interface AWEAppContext ()
@property (nonatomic, strong) NSMapTable *objectRegistry;
@property (nonatomic, strong) NSMapTable *classRegistry;
@property (nonatomic, strong) NSMapTable *providerRegistry;
@end

@implementation AWEAppContext

+ (instancetype)appContext
{
    static AWEAppContext *appContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!appContext) {
            appContext = [[self alloc] init];
        }
    });
    return appContext;
}

- (instancetype)init
{
    if (self = [super init]) {
        _objectRegistry = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                    valueOptions:NSPointerFunctionsWeakMemory
                                                        capacity:0];
        _classRegistry = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                   valueOptions:NSPointerFunctionsStrongMemory
                                                       capacity:0];
        _providerRegistry = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                      valueOptions:NSPointerFunctionsCopyIn
                                                          capacity:0];
    }
    return self;
}

- (BOOL)bindProvider:(IESAppContextProvider)provider forProtocol:(Protocol *)protocol
{
    NSAssert(provider, @"provider can not be nil");
    NSAssert(protocol, @"protocol can not be nil");
    if (!provider || !protocol) {
        return NO;
    }
    [self.providerRegistry setObject:provider forKey:protocol];
    return YES;
}

- (BOOL)bindClass:(Class)clazz forProtocol:(Protocol *)protocol
{
    NSAssert([clazz conformsToProtocol:protocol], @"class does not conforms to protocol");
    NSAssert(protocol, @"protocol can not be nil");
    if (!clazz || !protocol || ![clazz conformsToProtocol:protocol]) {
        return NO;
    }
    [self.classRegistry setObject:clazz forKey:protocol];
    return YES;
}

- (BOOL)bind:(id)object forProtocol:(Protocol *)protocol
{
    NSAssert([object conformsToProtocol:protocol], @"object does not conforms to protocol");
    NSAssert(protocol, @"protocol can not be nil");
    if (!object || !protocol || ![object conformsToProtocol:protocol]) {
        return NO;
    }
    [self.objectRegistry setObject:object forKey:protocol];
    return YES;
}

- (id)objectForProtocol:(Protocol *)protocol
{
    NSAssert(protocol, @"protocol can not be nil");
    if (nil == protocol) {
        return nil;
    }
    
    id object = [self.objectRegistry objectForKey:protocol];
    if (object) {
        NSAssert([object conformsToProtocol:protocol], @"object does not conforms to protocol");
        if ([object conformsToProtocol:protocol]) {
            return object;
        }
    }
    
    Class class = [self.classRegistry objectForKey:protocol];
    if (class) {
        object = [[class alloc] init];
        NSAssert(object, @"object is nil");
        NSAssert([object conformsToProtocol:protocol], @"object does not conforms to protocol");
        if (object && [object conformsToProtocol:protocol]) {
            return object;
        }
    }
    
    IESAppContextProvider provider = [self.providerRegistry objectForKey:protocol];
    if (provider) {
        object = provider(self);
        NSAssert(object, @"object is nil");
        NSAssert([object conformsToProtocol:protocol], @"object does not conforms to protocol");
        if (object && [object conformsToProtocol:protocol]) {
            return object;
        }
    }
    
    object = [[HTSServiceCenter defaultCenter] getProtocolService:protocol];
    if (object) {
        NSAssert(object, @"object is nil");
        NSAssert([object conformsToProtocol:protocol], @"object does not conforms to protocol");
        if (object && [object conformsToProtocol:protocol]) {
            return object;
        }
    }
    return nil;
}

@end
