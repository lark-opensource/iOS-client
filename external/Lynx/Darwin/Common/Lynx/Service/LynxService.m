//  Copyright 2022 The Lynx Authors. All rights reserved.
#import "LynxService.h"
#import "LynxLazyLoad.h"
#import "LynxServiceDevProtocol.h"
#import "LynxServiceHybridAPIProtocol.h"

#import "LynxServiceAppLogProtocol.h"
#import "LynxServiceImageProtocol.h"
#import "LynxServiceMonitorProtocol.h"
#import "LynxServiceProtocol.h"
#import "LynxServiceResourceProtocol.h"
#import "LynxServiceSettingsProtocol.h"
#import "LynxServiceTrackEventProtocol.h"
#import "LynxServiceTrailProtocol.h"

#import <objc/runtime.h>

#if __ENABLE_LYNX_NET__
#import "LynxNetworkProtocol.h"
#endif

static NSArray<NSString *> *lynx_services = nil;
static NSString *const LYNX_AUTO_REGISTER_SERVICE_PREFIX = @"__lynx_auto_register_serivce__";

@interface LynxServices ()

@property(atomic, strong) NSMutableDictionary<NSString *, Class> *protocolToClassMap;
@property(atomic, strong) NSMutableDictionary<NSString *, id> *protocolToInstanceMap;
@property(atomic, strong) NSRecursiveLock *recLock;
@property(atomic, strong) NSMutableSet<NSString *> *protocolClassCalledSet;

@end

@implementation LynxServices

LYNX_LOAD_LAZY(
    static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
      NSMutableArray<NSString *> *autoRegisteredService = [NSMutableArray new];
      unsigned int methodCount = 0;
      Method *methods = class_copyMethodList(object_getClass([self class]), &methodCount);
      for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        if ([NSStringFromSelector(selector) hasPrefix:LYNX_AUTO_REGISTER_SERVICE_PREFIX]) {
          IMP imp = method_getImplementation(method);
          NSString *className = ((NSString * (*)(id, SEL)) imp)(self, selector);
          if ([className isKindOfClass:[NSString class]] && className.length > 0) {
            [autoRegisteredService addObject:className];
            Class cls = NSClassFromString(className);
            if (cls != nil) {
              // check cls is nil? and check is subclass of LynxService?
              if (cls == nil || ![cls conformsToProtocol:@protocol(LynxServiceProtocol)]) {
                return;
              }
              [LynxServices registerService:cls];
            }
          }
        }
      }
      free(methods);
      lynx_services = [autoRegisteredService copy];
    });)

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static LynxServices *services;
  dispatch_once(&onceToken, ^{
    services = [[LynxServices alloc] init];
  });
  return services;
}

+ (void)registerService:(Class)cls {
  if (cls == nil || ![cls conformsToProtocol:@protocol(LynxServiceProtocol)]) {
    NSAssert(NO, @"%@ should conforms to %@, %s", NSStringFromClass(cls),
             NSStringFromProtocol(@protocol(LynxServiceProtocol)), __func__);
    return;
  }
  switch ([cls serviceType]) {
    case LynxServiceTypeMonitor:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceMonitorProtocol)];
      break;
#if __ENABLE_LYNX_NET__
    case LynxServiceTypeNetwork:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxNetworkProtocol)];
      break;
#endif
    case LynxServiceHybridAPI:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceHybridAPIProtocol)];
      break;
    case LynxServiceTrail:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceTrailProtocol)];
      break;
    case LynxServiceDev:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceDevProtocol)];
      break;
#ifdef OS_IOS
    case LynxServiceImage:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceImageProtocol)];
      break;
#endif
    case LynxServiceResource:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceResourceProtocol)];
      break;
    case LynxServiceTrack:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceTrackEventProtocol)];
      break;
    case LynxServiceAppLog:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceAppLogProtocol)];
      break;
    case LynxServiceSettings:
      [[self sharedInstance] bindClass:cls toProtocol:@protocol(LynxServiceSettingsProtocol)];
      break;
  }
}

#pragma mark - Lifecycle
- (instancetype)init {
  if (self = [super init]) {
    _protocolToClassMap = [[NSMutableDictionary alloc] init];
    _protocolToInstanceMap = [[NSMutableDictionary alloc] init];
    _recLock = [[NSRecursiveLock alloc] init];
    _protocolClassCalledSet = [[NSMutableSet alloc] init];
  }
  return self;
}

#pragma mark - Public

+ (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol {
  [[self sharedInstance] bindClass:cls toProtocol:protocol];
}

+ (id)getInstanceWithProtocol:(Protocol *)protocol bizID:bid {
  if (!protocol || protocol == nil) {
    return nil;
  }
  return [[self sharedInstance] getInstanceWithProtocol:protocol bizID:bid];
}

- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol {
  if (cls == nil || protocol == nil || ![cls conformsToProtocol:protocol]) {
    NSAssert(NO, @"%@ should conforms to %@, %s", NSStringFromClass(cls),
             NSStringFromProtocol(protocol), __func__);
    return;
  }
  if (![cls conformsToProtocol:@protocol(LynxServiceProtocol)]) {
    NSAssert(NO, @"%@ should conforms to LynxServiceProtocol, %s", NSStringFromClass(cls),
             __func__);
    return;
  }
  [self.recLock lock];
  // Get biz name from clz instance
  // key: protocolName__lynx_binder__${bizID}
  NSString *protocolName =
      [NSString stringWithFormat:@"%@__lynx_binder__%@", NSStringFromProtocol(protocol),
                                 [cls serviceBizID] ?: DEFAULT_LYNX_SERVICE];
  if ([self.protocolToClassMap objectForKey:protocolName] == nil) {
    [self.protocolToClassMap setObject:cls forKey:protocolName];
  } else {
    NSAssert(NO, @"%@ and %@ are duplicated bindings, %s", NSStringFromClass(cls),
             NSStringFromProtocol(protocol), __func__);
  }
  [self.recLock unlock];
}

- (id)getInstanceWithProtocol:(Protocol *)protocol bizID:(NSString *)bizID {
  if (lynx_services == nil || lynx_services.count == 0) {
    return nil;
  }
  [self.recLock lock];
  // key: protocolName__lynx_binder__${bizID}
  NSString *finalBizID = bizID ?: DEFAULT_LYNX_SERVICE;
  NSString *protocolName = [NSString
      stringWithFormat:@"%@__lynx_binder__%@", NSStringFromProtocol(protocol), finalBizID];
  id object = [self.protocolToInstanceMap objectForKey:protocolName];
  if (object == nil) {
    Class cls = [self.protocolToClassMap objectForKey:protocolName];
    if (cls != nil) {
      object =
          [self.protocolToInstanceMap objectForKey:protocolName] ?: [self getInstanceWithClass:cls];
      if (object) {
        [self.protocolToInstanceMap setObject:object forKey:protocolName];
      } else {
        NSAssert(NO, @"%@ no object", protocolName);
      }
    } else {
      // NSAssert(NO, @"%@ is not binded, %s", NSStringFromProtocol(protocol), __func__);
    }
  }
  [self.recLock unlock];
  return object;
}

- (id)getInstanceWithClass:(Class)cls {
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
