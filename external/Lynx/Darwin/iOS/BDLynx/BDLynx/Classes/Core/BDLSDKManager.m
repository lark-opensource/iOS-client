//
//  BDLSDKManager.m
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import "BDLSDKManager.h"
#import "BDLConfig.h"
#import "BDLReportProtocol.h"
#import "BDLSDKProtocol.h"
#import "BDLUtils.h"
#import "BDLynxKitModule.h"
#import "BDLynxProvider.h"
#import "BDSettings.h"
#import "LynxBacktrace.h"
#import "LynxConfig.h"
#import "LynxEnv.h"
#import "LynxLog.h"
#import "LynxVersion.h"

@interface BDLSDKManager ()

@property(atomic, strong) NSMutableDictionary<NSString *, Class> *protocolToClassMap;
@property(atomic, strong) NSMutableDictionary<NSString *, id> *protocolToObjectMap;
@property(atomic, strong) NSMutableDictionary *systemInfo;

@property(atomic, strong) NSRecursiveLock *recLock;

@end

static bool alogInitialized = NO;

@implementation BDLSDKManager

#pragma mark - public
/**
 * SDK 启动,宿主自定义内容建议在setup之前启动
 */
+ (void)setup {
  if (!alogInitialized) {
    [self initLogObserver];
    alogInitialized = YES;
  }
  LLogInfo(@"BDLynxInit: BDLSDKManager setup");
  LynxConfig *globalConfig;
  if ([LynxEnv sharedInstance].config) {
    globalConfig = [LynxEnv sharedInstance].config;
  } else {
    globalConfig = [[LynxConfig alloc] initWithProvider:[BDLynxProvider new]];
  }
  [[LynxEnv sharedInstance] prepareConfig:globalConfig];
  LynxSetBacktraceFunction(^NSString *(NSString *message, NSUInteger skippedDepth) {
    NSString *tracelog = [BDL_SERVICE_WITH_SELECTOR(
        BDLReportProtocol, @selector(backtraceWithMessage:
                                           bySkippedDepth:)) backtraceWithMessage:message
                                                                   bySkippedDepth:skippedDepth + 1];

    return tracelog;
  });
  [self registerCustomSystemInfo];
  [self registCustomUIComponent];
  [[BDSettings shareInstance] initSettings];
  [[BDSettings shareInstance] syncSettings];
}

+ (void)initLogObserver {
  LynxLogObserver *observer = [[LynxLogObserver alloc]
      initWithLogFunction:^(LynxLogLevel level, NSString *message) {
        switch (level) {
          case LynxLogLevelInfo:
            [BDLUtils info:message];
            break;
          case LynxLogLevelWarning:
            [BDLUtils warn:message];
            break;
          case LynxLogLevelError:
            [BDLUtils error:message];
            break;
          case LynxLogLevelFatal:
            [BDLUtils fatal:message];
            break;
          default:
            break;
        }
      }
              minLogLevel:LynxLogLevelInfo];
  observer.acceptSource = LynxLogSourceNaitve;
  LynxAddLogObserverByModel(observer);
}

+ (NSString *)lynxVersionString {
  return [LynxVersion versionString];
}

/**
 * 绑定协议和协议的实现类
 * @param cls 协议实现类，实现了 sharedInstance，是单例
 * @param protocol 协议
 */
+ (void)bdl_bindServiceClass:(Class)cls toProtocol:(Protocol *)protocol {
  [[self sharedInstance] bdl_bindServiceClass:cls toProtocol:protocol];
}

/**
 * 通过协议获取实现
 * @param protocol 协议，实现了 sharedInstance，返回单例
 * @return 协议实现类的对象；如果没有绑定过协议，返回空
 */
+ (_Nullable id)bdl_serviceWithProtocol:(Protocol *)protocol {
  return [[self sharedInstance] bdl_serviceWithProtocol:protocol];
}

+ (_Nullable id)bdl_serviceWithProtocol:(Protocol *)protocol selector:(SEL)selector {
  if (!protocol || !selector) {
    return nil;
  }

  id service = [self bdl_serviceWithProtocol:protocol];
  if (service && [service respondsToSelector:selector]) {
    return service;
  }
  return nil;
}

#pragma mark - private
+ (instancetype)sharedInstance {
  static BDLSDKManager *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[BDLSDKManager alloc] init];
  });
  return _instance;
}

+ (void)registCustomUIComponent {
  void (^internalRegistBlock)(void) =
      [BDL_SERVICE(BDLComponentInternalProtocol) registCustomUIComponent];
  if (internalRegistBlock) {
    internalRegistBlock();
  }

  void (^registBlock)(void) = [BDL_SERVICE(BDLSDKProtocol) registCustomUIComponent];
  if (registBlock) {
    registBlock();
  }
}

+ (void)registerCustomSystemInfo {
  if ([[self sharedInstance] systemInfo] == nil) {
    [[self sharedInstance] setSystemInfo:[[NSMutableDictionary alloc] init]];
  }
  BDLConfig *areaConfig = [[BDLConfig alloc] init];
  if (areaConfig) {
    @synchronized([self sharedInstance]) {
      [[[self sharedInstance] systemInfo] addEntriesFromDictionary:[areaConfig defaultConfigDict]];
    }
  }
}

+ (NSObject *)getSystemInfoByKey:(NSString *__nonnull)key {
  return [[[self sharedInstance] systemInfo] objectForKey:key];
}

+ (NSDictionary *)getAllSystemInfo {
  return [[NSDictionary alloc] initWithDictionary:[[self sharedInstance] systemInfo]];
}

- (instancetype)init {
  if (self = [super init]) {
    _protocolToClassMap = [[NSMutableDictionary alloc] init];
    _protocolToObjectMap = [[NSMutableDictionary alloc] init];
    _recLock = [[NSRecursiveLock alloc] init];
  }
  return self;
}

#pragma mark - Private

- (void)bdl_bindServiceClass:(Class)cls toProtocol:(Protocol *)protocol {
  if (cls == nil || protocol == nil || ![cls conformsToProtocol:protocol]) {
    NSAssert(NO, @"%@ should conforms to %@, %s", NSStringFromClass(cls),
             NSStringFromProtocol(protocol), __func__);
    return;
  }

  [self.recLock lock];
  NSString *protocolName = NSStringFromProtocol(protocol);
  if ([self.protocolToClassMap objectForKey:protocolName] == nil) {
    [self.protocolToClassMap setObject:cls forKey:protocolName];
  } else {
    NSAssert(NO, @"%@ and %@ are duplicated bindings, %s", NSStringFromClass(cls),
             NSStringFromProtocol(protocol), __func__);
  }
  [self.recLock unlock];
}

- (_Nullable id)bdl_serviceWithProtocol:(Protocol *)protocol {
  if (protocol == nil) {
    return nil;
  }

  [self.recLock lock];
  NSString *protocolName = NSStringFromProtocol(protocol);
  id object = [self.protocolToObjectMap objectForKey:protocolName];
  if (object == nil) {
    Class cls = [self.protocolToClassMap objectForKey:protocolName];
    if (cls != nil) {
      if ([cls respondsToSelector:@selector(sharedInstance)]) {
        // 单例模式
        object = [cls sharedInstance];
      } else {
        object = [[cls alloc] init];
      }
      [self.protocolToObjectMap setObject:object forKey:protocolName];
    } else {
      LLogInfo(@"%@ is not binded, %s", NSStringFromProtocol(protocol), __func__);
    }
  }
  [self.recLock unlock];
  return object;
}

@end
