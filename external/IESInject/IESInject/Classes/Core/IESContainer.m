//
//  IESContainer.m
//  IESInject
//
//  Created by bytedance on 2020/2/5.
//

#import "IESContainer.h"
#import "IESServiceBindingEntry.h"
#import "IESServiceProviderEntry.h"
#import <objc/runtime.h>
#import <pthread/pthread.h>

@interface IESContainer ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, id<IESServiceEntryProtocol>> *services;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet<IESBlockDisposable *> *> *blocksNeedServicesResponse;
@property (nonatomic, strong) IESContainer *parentContainer;
@property (nonatomic, assign) pthread_mutex_t serviceDataLock;
@property (nonatomic, assign) pthread_mutex_t blockDataLock;

@end

@implementation IESContainer

- (instancetype)initWithParentContainer:(IESContainer *)container
{
    if (self = [super init]) {
        _services = [[NSMutableDictionary alloc] init];
        _blocksNeedServicesResponse = [[NSMutableDictionary alloc] init];
        _parentContainer = container;

        pthread_mutexattr_t serviceAttr;
        pthread_mutexattr_init(&serviceAttr);
        pthread_mutexattr_settype(&serviceAttr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_serviceDataLock, &serviceAttr);

        pthread_mutexattr_t blockAttr;
        pthread_mutexattr_init(&blockAttr);
        pthread_mutexattr_settype(&blockAttr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_blockDataLock, &blockAttr);
    }
    return self;
}

- (instancetype)init
{
    return [self initWithParentContainer:nil];
}

#pragma mark - IESServiceRegister

- (void)registerInstance:(id)instance forProtocol:(Protocol *)protocol
{
    [self registerInstance:instance forProtocols:@[protocol]];
}

- (void)registerInstance:(id)instance forProtocols:(NSArray<Protocol *> *)protocols
{
    IESServiceBindingEntry *entry = [[IESServiceBindingEntry alloc] initWithInstance:instance];
    for (Protocol * protocol in protocols) {
        NSAssert([instance conformsToProtocol:protocol], @"%@ should conforms to %@", instance, protocol);
        [self registerServiceEntry:entry withProtocol:protocol];
        [self responseToBlockWithServiceInstance:instance serviceKey:NSStringFromProtocol(protocol)];
    }
}

- (void)registerInstance:(id)instance forClass:(Class)aClass
{
    pthread_mutex_lock(&_serviceDataLock);
    NSString *key = NSStringFromClass(aClass);
    IESServiceBindingEntry *entry = [[IESServiceBindingEntry alloc] initWithInstance:instance];
    [self.services setObject:entry forKey:key];
    pthread_mutex_unlock(&_serviceDataLock);
}

- (void)registerClass:(Class)aClass forProtocol:(Protocol *)protocol scope:(IESInjectScopeType)scopeType
{
    [self registerClass:aClass forProtocols:@[protocol] scope:scopeType];
}

- (void)registerClass:(Class)aClass forProtocols:(NSArray<Protocol *> *)protocols scope:(IESInjectScopeType)scopeType
{
    IESServiceProviderEntry *entry = [[IESServiceProviderEntry alloc] initWithClass:aClass scopeType:scopeType];
    for (Protocol * protocol in protocols) {
        [self registerServiceEntry:entry withProtocol:protocol];
    }
}

- (void)registerProvider:(IESContainerProvider)provider forProtocol:(Protocol *)protocol scope:(IESInjectScopeType)scopeType
{
    [self registerProvider:provider forProtocols:@[protocol] scope:scopeType];
}

-(void)registerProvider:(IESContainerProvider)provider forProtocols:(NSArray<Protocol *> *)protocols scope:(IESInjectScopeType)scopeType
{
    IESServiceProviderEntry *entry = [[IESServiceProviderEntry alloc] initWithProvider:provider scopeType:scopeType];
    for (Protocol *protocol in protocols) {
        [self registerServiceEntry:entry withProtocol:protocol];
    }
}

- (void)registerProvider:(IESContainerProvider)provider forClass:(Class)aClass scope:(IESInjectScopeType)scopeType
{
     pthread_mutex_lock(&_serviceDataLock);
     NSString *key = NSStringFromClass(aClass);
     IESServiceProviderEntry *entry = [[IESServiceProviderEntry alloc] initWithProvider:provider scopeType:scopeType];
     [self.services setObject:entry forKey:key];
     pthread_mutex_unlock(&_serviceDataLock);
}

-(IESBlockDisposable * _Nullable)provideBlockNeedServiceResponse:(IESServiceResponeseBlock)block forProtocol:(Protocol *)protocol
{
    if (!block) {
        return nil;
    }
    
    id objectOfProtocol = [self resolveObject:protocol];
    if (objectOfProtocol) { //if the service had been registered，run block
        block(objectOfProtocol);
        return nil;
    } else { //if the service has not registered，save block
        pthread_mutex_lock(&_blockDataLock);
        NSString *serviceKey = NSStringFromProtocol(protocol);
        
        IESContainer *serviceContainer = self;
        __block IESBlockDisposable *blockRegisted = nil;
        while (!blockRegisted && serviceContainer) {
            //Judge whether block has been registered
            NSMutableSet<IESBlockDisposable *> *blockSet = [serviceContainer.blocksNeedServicesResponse objectForKey:serviceKey];
            if (blockSet) {
                for (IESBlockDisposable *blockDisposable in blockSet) {
                    if (block == blockDisposable.block) {
                        blockRegisted = blockDisposable;
                        break;
                    }
                }
            }
            serviceContainer = serviceContainer.parentContainer;
        }
        
        if (!blockRegisted) {
            blockRegisted = [[IESBlockDisposable alloc] initWithBlock:block serviceKey:serviceKey serviceContainer:self];
            NSMutableSet<IESBlockDisposable *> *blockSet = [self.blocksNeedServicesResponse objectForKey:serviceKey];
            if (!blockSet) {
                blockSet = [[NSMutableSet alloc] init];
                [blockSet addObject:blockRegisted];
                [self.blocksNeedServicesResponse setObject:blockSet forKey:serviceKey];
            } else {
                [blockSet addObject:blockRegisted];
            }
        }
        pthread_mutex_unlock(&_blockDataLock);
        
        return blockRegisted;
    }
}

#pragma mark - IESServiceProvider

- (id)resolveObject:(id)classOrProtocol
{
    id object = [self resolveCurrentContainerObject:classOrProtocol];
    if (!object) {
        object = [self resolveParentContainerObject:classOrProtocol];
    }
    return object;
}

- (id)resolveCurrentContainerObject:(id)classOrProtocol
{
    if (!classOrProtocol) {
        return nil;
    }
    
    NSString *key = [self stringFromClassOrProtocol:classOrProtocol];
    __block id object = nil;
    pthread_mutex_lock(&_serviceDataLock);
    id<IESServiceEntryProtocol> entry = [_services objectForKey:key];
    if (entry) {
        object = [entry extractObject];
    }
    pthread_mutex_unlock(&_serviceDataLock);
    return object;
}

- (id)resolveParentContainerObject:(id)classOrProtocol
{
    id object;
    if (_parentContainer) {
        object = [_parentContainer resolveObject:classOrProtocol];
    }
    return object;
}

#pragma mark - private

- (void)removeBlockNeedServiceResponse:(IESBlockDisposable *)blockDisposable withRelatedServiceKey:(NSString *)relatedServiceKey
{
    pthread_mutex_lock(&_blockDataLock);
    NSMutableSet *blockSet = [self.blocksNeedServicesResponse objectForKey:relatedServiceKey];
    if ([blockSet containsObject:blockDisposable]) {
            [blockSet removeObject:blockDisposable];
    }
    pthread_mutex_unlock(&_blockDataLock);
}

- (NSString *)stringFromClassOrProtocol:(id)classOrProtocol
{
    BOOL isClass = class_isMetaClass(object_getClass(classOrProtocol));
    NSString *key;
    if (isClass) {
        key = NSStringFromClass(classOrProtocol);
    } else {
        key = NSStringFromProtocol(classOrProtocol);
    }
    return key;
}

- (void)responseToBlockWithServiceInstance:(id)instance serviceKey:(NSString *)serviceKey
{
    IESContainer *serviceContainer = self;
    NSSet<IESBlockDisposable *> *blocksNeedResponse;
    
    while (serviceContainer) {
        pthread_mutex_lock(&_blockDataLock);
        blocksNeedResponse = [serviceContainer.blocksNeedServicesResponse objectForKey:serviceKey].mutableCopy;
        [serviceContainer.blocksNeedServicesResponse removeObjectForKey:serviceKey];
        pthread_mutex_unlock(&_blockDataLock);
        
        if (blocksNeedResponse && blocksNeedResponse.count > 0) {
            for (IESBlockDisposable *blockDisposable in blocksNeedResponse) {
                blockDisposable.block(instance);
                [blockDisposable dispose];
            }
        }

        serviceContainer = serviceContainer.parentContainer;
    }
}

- (void)registerServiceEntry:(IESServiceEntry *)entry withProtocol:(Protocol *)protocol
{
    pthread_mutex_lock(&_serviceDataLock);
    NSString *serivceKey = NSStringFromProtocol(protocol);
    NSAssert(![[self.services allKeys] containsObject:serivceKey], @"%@ already be registered and can not be registered again!", serivceKey);
    [self.services setObject:entry forKey:serivceKey];
    pthread_mutex_unlock(&_serviceDataLock);
}

@end
