//
// BDXServiceManager.m
// BDXServiceCenter-Pods-Aweme
//
// Created by bill on 2021/3/1.
//

#import "BDXServiceManager.h"
#import "BDXService.h"
#import "BDXServiceManager+Register.h"

/// Protocols
#import "BDXLynxKitProtocol.h"
#import "BDXMonitorProtocol.h"
#import "BDXOptimizeProtocol.h"
#import "BDXPageContainerProtocol.h"
#import "BDXPopupContainerProtocol.h"
#import "BDXResourceLoaderProtocol.h"
#import "BDXRouterProtocol.h"
#import "BDXSchemaProtocol.h"
#import "BDXServiceProtocol.h"
#import "BDXViewContainerProtocol.h"
#import "BDXWebKitProtocol.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDXServiceManager ()

@property(atomic, strong) NSMutableDictionary<NSString *, Class> *protocolToClassMap;
@property(atomic, strong) NSMutableDictionary<NSString *, id> *protocolToObjectMap;

@property(atomic, strong) NSRecursiveLock *recLock;

// 宿主调用初始化SDK 前，SDK 功能不可用
@property(atomic, assign) BOOL hasInitialize;

@end

@implementation BDXServiceManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDXServiceManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDXServiceManager alloc] init];
    });
    return instance;
}

+ (void)registerDefaultSercice:(Class)cls
{
    if (cls == nil || ![cls conformsToProtocol:@protocol(BDXServiceProtocol)]) {
        NSAssert(NO, @"%@ should conforms to %@, %s", NSStringFromClass(cls), NSStringFromProtocol(@protocol(BDXServiceProtocol)), __func__);
        return;
    }
    switch ([cls serviceType]) {
        case BDXServiceTypeResourceLoader:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXResourceLoaderProtocol)];
            break;
        case BDXServiceTypeContainerView:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXViewContainerServiceProtocol)];
            break;
        case BDXServiceTypeContainerPage:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXPageContainerServiceProtocol)];
            break;
        case BDXServiceTypeContainerPopUp:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXPopupContainerServiceProtocol)];
            break;
        case BDXServiceTypeSchema:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXSchemaProtocol)];
            break;
        case BDXServiceTypeLynxKit:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXLynxKitProtocol)];
            break;
        case BDXServiceTypeWebKit:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXWebKitProtocol)];
            break;
        case BDXServiceTypeMonitor:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXMonitorProtocol)];
            break;
        case BDXServiceTypeRouter:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXRouterProtocol)];
            break;
        case BDXServiceTypeOptimize:
            [[self sharedInstance] bindClass:cls toProtocol:@protocol(BDXOptimizeProtocol)];
            break;
        default:
            break;
    }
}

+ (void)registerCustomsizedService:(Class)cls
{
}

- (void)registerCustomsizedService:(Class)cls
{
}

#pragma mark - Lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.hasInitialize = YES;
        _protocolToClassMap = [[NSMutableDictionary alloc] init];
        _protocolToObjectMap = [[NSMutableDictionary alloc] init];
        _recLock = [[NSRecursiveLock alloc] init];
    }

    return self;
}

#pragma mark - Public

+ (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol
{
    [[self sharedInstance] bindClass:cls toProtocol:protocol];
}

+ (id)getObjectWithProtocol:(Protocol *)protocol bizID:bid
{
    [[self sharedInstance] bdx_autoRegisterService];
    return [[self sharedInstance] getObjectWithProtocol:protocol bizID:bid];
}

+ (Class)getClassWithProtocol:(Protocol *)protocol
{
    Class cls = [[self sharedInstance] getClassWithProtocol:protocol];
    return cls;
}

- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol
{
    if (cls == nil || protocol == nil || ![cls conformsToProtocol:protocol]) {
        NSAssert(NO, @"%@ should conforms to %@, %s", NSStringFromClass(cls), NSStringFromProtocol(protocol), __func__);
        return;
    }
    if (![cls conformsToProtocol:@protocol(BDXServiceProtocol)]) {
        NSAssert(NO, @"%@ should conforms to BDXServiceProtocol, %s", NSStringFromClass(cls), __func__);
        return;
    }

    [self.recLock lock];
    // Get biz name from clz instance
    // key: protocolName__xbinder__bizID
    NSString *protocolName = [NSString stringWithFormat:@"%@__xbinder__%@", NSStringFromProtocol(protocol), [cls serviceBizID] ?: DEFAULT_SERVICE_BIZ_ID];
    if ([self.protocolToClassMap objectForKey:protocolName]) {
        return;
    }

    if ([self.protocolToClassMap objectForKey:protocolName] == nil) {
        [self.protocolToClassMap btd_setObject:cls forKey:protocolName];
    } else {
        NSAssert(NO, @"%@ and %@ are duplicated bindings, %s", NSStringFromClass(cls), NSStringFromProtocol(protocol), __func__);
    }

    [self.recLock unlock];
}

- (id)getObjectWithProtocol:(Protocol *)protocol bizID:(NSString *)bizID
{
    if (!self.hasInitialize || protocol == nil) {
        return nil;
    }

    [self bdx_autoRegisterService];

    [self.recLock lock];
    // key: protocolName__xbinder__bizID
    NSString *protocolName = [NSString stringWithFormat:@"%@__xbinder__%@", NSStringFromProtocol(protocol), bizID ?: DEFAULT_SERVICE_BIZ_ID];
    id object = [self.protocolToObjectMap objectForKey:protocolName];
    if (object == nil) {
        Class cls = [self.protocolToClassMap objectForKey:protocolName];
        if (cls != nil) {
            object = [self getObjectWithClass:cls];
            if (object) {
                [self.protocolToObjectMap btd_setObject:object forKey:protocolName];
            } else {
                NSAssert(NO, @"%@ no object", protocolName);
            }
        } else {
            //      NSAssert(NO, @"%@ is not binded, %s", NSStringFromProtocol(protocol), __func__);
        }
    }

    [self.recLock unlock];
    return object;
}

- (Class)getClassWithProtocol:(Protocol *)protocol
{
    if (!self.hasInitialize || protocol == nil) {
        return nil;
    }

    [self bdx_autoRegisterService];

    [self.recLock lock];
    // key: protocolName__xbinder__bizID
    NSString *protocolName = [NSString stringWithFormat:@"%@__xbinder__%@", NSStringFromProtocol(protocol), DEFAULT_SERVICE_BIZ_ID];
    Class cls = [self.protocolToClassMap objectForKey:protocolName];
    [self.recLock unlock];

    if (cls == nil) {
        NSAssert(NO, @"%@ is not binded, %s", NSStringFromProtocol(protocol), __func__);
    }

    return cls;
}

+ (Class)getClassWithProtocol:(Protocol *)protocol bizID:(NSString *)bizID
{
    return [[self sharedInstance] getClassWithProtocol:protocol bizID:bizID];
}

- (Class)getClassWithProtocol:(Protocol *)protocol bizID:(NSString *)bizID
{
    if (!self.hasInitialize || protocol == nil) {
        return nil;
    }

    [self bdx_autoRegisterService];

    [self.recLock lock];
    // key: protocolName__xbinder__bizID
    NSString *protocolName = [NSString stringWithFormat:@"%@__xbinder__%@", NSStringFromProtocol(protocol), bizID ?: DEFAULT_SERVICE_BIZ_ID];
    Class cls = [self.protocolToClassMap objectForKey:protocolName];
    [self.recLock unlock];

    if (cls == nil) {
        //    NSAssert(NO, @"%@ is not binded, %s", NSStringFromProtocol(protocol), __func__);
    }

    return cls;
}

- (id)getObjectWithClass:(Class)cls
{
    // UI 类型需要判断主线程
    id object = nil;
    if ([cls respondsToSelector:@selector(sharedInstance)]) {
        object = [cls sharedInstance];
    } else {
        object = [[cls alloc] init];
    }

    return object;
}

@end
