// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxEnv.h"

#import <objc/message.h>
#import "LynxBaseInspectorOwner.h"
#import "LynxComponentRegistry.h"
#import "LynxConfig.h"
#import "LynxDevtoolUtils.h"
#import "LynxEnvKey.h"
#import "LynxError.h"
#import "LynxLazyRegister.h"
#import "LynxLifecycleDispatcher.h"
#import "LynxLog.h"
#import "LynxService.h"
#import "LynxServiceDevProtocol.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#import "LynxViewClient.h"
#include "base/iOS/lynx_env_darwin.h"
#include "base/lynx_env.h"
#include "starlight/style/computed_css_style.h"
#include "tasm/config.h"
#include "tasm/fluency/fluency_tracer.h"
#if OS_IOS
#import "LynxUICollection.h"
#endif

@interface LynxEnv ()

@property(nonatomic, assign) pthread_mutex_t settingsLock;

@end

@implementation LynxEnv

+ (instancetype)sharedInstance {
  static LynxEnv *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[LynxEnv alloc] init];
    [_instance initDevtool];
    // register component here without using +load
#if OS_IOS
    [LynxComponentRegistry registerUI:[LynxUICollection class] withName:@"list"];
#endif
  });

  return _instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    pthread_mutex_init(&_settingsLock, NULL);
    _lifecycleDispatcher = [[LynxLifecycleDispatcher alloc] init];
    _lynxDebugEnabled = NO;
    _devtoolComponentAttach = NO;
    _resoureProviders = [NSMutableDictionary dictionary];
    _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    _layoutOnlyEnabled = YES;
    _autoResumeAnimation = YES;
    _enableNewTransformOrigin = YES;
    _recordEnable = NO;
    _switchRunloopThread = NO;
    [LynxLazyRegister loadLynxInitTask];
    lynx::base::LynxEnvDarwin::initNativeUIThread();
#if OS_IOS
    lynx::tasm::Config::InitializeVersion([[UIDevice currentDevice].systemVersion UTF8String]);
#endif
  }
  LLogInfo(@"LynxEnv: init success");
  return self;
}

- (void)initDevtool {
  if ([LynxService(LynxServiceDevProtocol) lynxDebugEnabled]) {
    self.lynxDebugEnabled = YES;
  }
  [self initDevtoolComponentAttachSwitch];
}

- (void)initDevtoolComponentAttachSwitch {
  Class inspectorClass = NSClassFromString(@"LynxInspectorOwner");
  if ([inspectorClass conformsToProtocol:@protocol(LynxBaseInspectorOwner)]) {
    _devtoolComponentAttach = YES;
    lynx::base::LynxEnv::GetInstance().SetEnv([KEY_DEVTOOL_COMPONENT_ATTACH UTF8String], true);
  } else {
    _devtoolComponentAttach = NO;
  }
}

- (void)setLynxDebugEnabled:(BOOL)lynxDebugEnabled {
  _lynxDebugEnabled = lynxDebugEnabled;
  if (lynxDebugEnabled) {
    Class devtoolEnv = NSClassFromString(@"LynxDevtoolEnv");
    SEL sharedInstanceSel = NSSelectorFromString(@"sharedInstance");
    if (devtoolEnv && sharedInstanceSel && [devtoolEnv respondsToSelector:sharedInstanceSel]) {
      id (*sharedInstance)(Class, SEL) = (id(*)(Class, SEL))objc_msgSend;
      sharedInstance(devtoolEnv, sharedInstanceSel);
    }
  }
}

- (void)setEnableRadonCompatible:(BOOL)value
    __attribute__((deprecated("Radon diff mode can't be close after lynx 2.3."))) {
}

- (void)setEnableLayoutOnly:(BOOL)value {
  _layoutOnlyEnabled = value;
}

- (void)setDevtoolEnv:(BOOL)value forKey:(NSString *)key {
  [LynxDevtoolUtils setDevtoolEnv:value forKey:key];
}

- (BOOL)getDevtoolEnv:(NSString *)key withDefaultValue:(BOOL)value {
  return [LynxDevtoolUtils getDevtoolEnv:key withDefaultValue:value];
}

- (void)setDevtoolEnv:(NSSet *)newGroupValues forGroup:(NSString *)groupKey {
  [LynxDevtoolUtils setDevtoolEnv:newGroupValues forGroup:groupKey];
}

- (NSSet *)getDevtoolEnvWithGroupName:(NSString *)groupKey {
  return [LynxDevtoolUtils getDevtoolEnvWithGroupName:groupKey];
}

- (void)setDevtoolEnabled:(BOOL)enableDevtool {
  LLogInfo(@"Turn on devtool");
  [self setDevtoolEnv:enableDevtool forKey:SP_KEY_ENABLE_DEVTOOL];
}

- (BOOL)devtoolEnabled {
  return [self getDevtoolEnv:SP_KEY_ENABLE_DEVTOOL withDefaultValue:NO];
}

- (void)setDevtoolEnabledForDebuggableView:(BOOL)enable {
  [self setDevtoolEnv:enable forKey:SP_KEY_ENABLE_DEVTOOL_FOR_DEBUGGABLE_VIEW];
}

- (BOOL)devtoolEnabledForDebuggableView {
  return [self getDevtoolEnv:SP_KEY_ENABLE_DEVTOOL_FOR_DEBUGGABLE_VIEW withDefaultValue:NO];
}

- (BOOL)getEnableRadonCompatible
    __attribute__((deprecated("Radon diff mode can't be close after lynx 2.3."))) {
  return true;
}

- (BOOL)getEnableLayoutOnly {
  return _layoutOnlyEnabled;
}

- (void)setRedBoxEnabled:(BOOL)enableRedBox {
  [self setDevtoolEnv:enableRedBox forKey:SP_KEY_ENABLE_REDBOX];
}

- (BOOL)redBoxEnabled {
  return [self devtoolComponentAttach] && [self getDevtoolEnv:SP_KEY_ENABLE_REDBOX
                                              withDefaultValue:YES];
}

- (void)setRedBoxNextEnabled:(BOOL)enableRedBoxNext {
  [self setDevtoolEnv:enableRedBoxNext forKey:SP_KEY_ENABLE_REDBOX_NEXT];
}

- (BOOL)redBoxNextEnabled {
  return [self devtoolComponentAttach] && [self getDevtoolEnv:SP_KEY_ENABLE_REDBOX_NEXT
                                              withDefaultValue:YES];
}

- (void)setPerfMonitorEnabled:(BOOL)enablePerfMonitor {
#if OS_IOS
  [self setDevtoolEnv:enablePerfMonitor forKey:SP_KEY_ENABLE_PERF_MONITOR_DEBUG];
#endif
}

- (BOOL)perfMonitorEnabled {
#if OS_IOS
  return [self getDevtoolEnv:SP_KEY_ENABLE_PERF_MONITOR_DEBUG withDefaultValue:NO];
#else
  return NO;
#endif
}

- (void)setAutomationEnabled:(BOOL)enableAutomation {
  NSUserDefaults *preference = [NSUserDefaults standardUserDefaults];
  [preference setBool:enableAutomation forKey:SP_KEY_ENABLE_AUTOMATION];
  [preference synchronize];
}

- (BOOL)automationEnabled {
  NSUserDefaults *preference = [NSUserDefaults standardUserDefaults];
  return [preference objectForKey:SP_KEY_ENABLE_AUTOMATION]
             ? [preference boolForKey:SP_KEY_ENABLE_AUTOMATION]
             : YES;
}

- (void)setEnableRedBox:(BOOL)enableRedBox __attribute__((deprecated("Use redBoxEnabled"))) {
  [self setRedBoxEnabled:enableRedBox];
}

- (BOOL)enableRedBox __attribute__((deprecated("Use redBoxEnabled"))) {
  return [self redBoxEnabled];
}

- (void)setEnableDevtoolDebug:(BOOL)enableRedBox __attribute__((deprecated("Use devtoolEnabled"))) {
  [self setDevtoolEnabled:enableRedBox];
}

- (BOOL)enableDevtoolDebug __attribute__((deprecated("Use devtoolEnabled"))) {
  return [self devtoolEnabled];
}

- (void)setAutoResumeAnimation:(BOOL)value {
  _autoResumeAnimation = value;
}

- (BOOL)getAutoResumeAnimation {
  return _autoResumeAnimation;
}

- (void)setEnableNewTransformOrigin:(BOOL)value {
  _enableNewTransformOrigin = value;
}

- (BOOL)getEnableNewTransformOrigin {
  return _enableNewTransformOrigin;
}

- (void)prepareConfig:(LynxConfig *)config {
  _config = config;
  [_config.componentRegistry makeIntoGloabl];
  // notify devtool
#if OS_IOS
  if (self.lynxDebugEnabled) {
    Class devtoolEnv = NSClassFromString(@"LynxDevtoolEnv");
    SEL sharedInstanceSel = NSSelectorFromString(@"sharedInstance");
    if (devtoolEnv && sharedInstanceSel && [devtoolEnv respondsToSelector:sharedInstanceSel]) {
      id (*sharedInstance)(Class, SEL) = (id(*)(Class, SEL))objc_msgSend;
      void (*prep)(id, SEL, LynxConfig *) = (void (*)(id, SEL, LynxConfig *))objc_msgSend;
      prep(sharedInstance(devtoolEnv, sharedInstanceSel), NSSelectorFromString(@"prepareConfig:"),
           config);
    }
  }
#endif
}

- (void)updateSettings:(NSDictionary *)settings {
  if (![settings isKindOfClass:NSDictionary.class]) {
    LLogError(@"settings is not NSDictionary type.");
    return;
  }

  pthread_mutex_lock(&_settingsLock);
  if ([_settings isEqualToDictionary:settings]) {
    pthread_mutex_unlock(&_settingsLock);
    LLogError(@"settings hash not changed");
    return;
  }

  _settings = [settings copy];
  LLogInfo(@"LynxEnv: settings info %@", [settings description]);
  _switchRunloopThread = [self.class boolValueFromSettings:settings
                                                     group:@"lynx_common"
                                                       key:@"IOS_SWITCH_RUNLOOP_THREAD"
                                              defaultValue:NO];
  bool disableLepusngOptimize = [self.class boolValueFromSettings:settings
                                                            group:@"lynx_common"
                                                              key:@"DISABLE_LEPUSNG_OPTIMIZE"
                                                     defaultValue:NO];
  bool enableFluencyTrace = [self.class boolValueFromSettings:settings
                                                        group:@"lynx_common"
                                                          key:@"ENABLE_FLUENCY_TRACE"
                                                 defaultValue:NO];
  bool enableGlobalFeatureSwitchStatistic =
      [self.class boolValueFromSettings:settings
                                  group:@"lynx_common"
                                    key:@"ENABLE_GLOBAL_FEATURE_SWITCH_STATISTIC"
                           defaultValue:NO];
  pthread_mutex_unlock(&_settingsLock);

  lynx::tasm::FluencyTracer::SetEnable(enableFluencyTrace);
  lynx::base::LynxEnv::GetInstance().SetEnv("disable_lepusng_optimize", disableLepusngOptimize);
  lynx::base::LynxEnv::GetInstance().SetEnv("enable_global_feature_switch_statistic",
                                            enableGlobalFeatureSwitchStatistic);
}

- (void)reportModuleCustomError:(NSString *)error {
  [_lifecycleDispatcher lynxView:nil
                 didRecieveError:[LynxError lynxErrorWithCode:LynxErrorCodeModuleBusinessError
                                                      message:error]];
}

- (void)onPiperInvoked:(NSString *)module
                method:(NSString *)method
              paramStr:(NSString *)paramStr
                   url:(NSString *)url
             sessionID:(NSString *)sessionID {
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  [info setObject:module forKey:@"module-name"];
  [info setObject:method forKey:@"method-name"];
  [info setObject:sessionID forKey:@"session-id"];
  [info setObject:url forKey:@"url"];
  if (![paramStr isEqualToString:@""]) {
    NSArray *arr = @[ paramStr ];
    [info setObject:arr forKey:@"params"];
  }
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifeCycle onPiperInvoked");
  [_lifecycleDispatcher onPiperInvoked:info];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)onPiperResponsed:(NSString *)module
                  method:(NSString *)method
                     url:(NSString *)url
                response:(NSDictionary *)response
               sessionID:(NSString *)sessionID {
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  [info setObject:module ?: @"" forKey:@"module-name"];
  [info setObject:method ?: @"" forKey:@"method-name"];
  [info setObject:sessionID ?: @"" forKey:@"session-id"];
  [info setObject:url ?: @"" forKey:@"url"];
  [info setObject:response ?: @{} forKey:@"response"];
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxViewLifeCycle onPiperResponsed");
  [_lifecycleDispatcher onPiperResponsed:info];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
}

- (void)setPiperMonitorState:(BOOL)state {
  lynx::base::LynxEnv::GetInstance().SetEnv("enablePiperMonitor", (bool)state);
}

- (void)addResoureProvider:(NSString *)key provider:(id<LynxResourceProvider>)provider {
  _resoureProviders[key] = provider;
}

- (void)initLayoutConfig:(CGSize)screenSize {
#if OS_IOS
  NSString *version = [UIDevice currentDevice].systemVersion;
  lynx::tasm::Config::Initialize(screenSize.width, screenSize.height, 1, [version UTF8String]);
  lynx::starlight::ComputedCSSStyle::LAYOUTS_UNIT_PER_PX = 1;
  const CGFloat scale = [UIScreen mainScreen].scale;
  lynx::starlight::ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT = scale;
  lynx::tasm::Config::InitPixelValues(screenSize.width * scale, screenSize.height * scale, scale);

  CGFloat statusBarHeight = 0;
  UIWindow *keyWindow = nil;
  // The first object of windows is not necessarily keyWindow! Do not use the first object of
  // windows as keyWindow.
  if (@available(iOS 13.0, *)) {
    if (@available(iOS 15.0, *)) {
      for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
          keyWindow = ((UIWindowScene *)scene).keyWindow;
          break;
        }
      }
    } else {
      for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
          keyWindow = window;
          break;
        }
      }
    }
    statusBarHeight =
        keyWindow ? keyWindow.windowScene.statusBarManager.statusBarFrame.size.height : 0;
  } else {
    keyWindow = [UIApplication sharedApplication].keyWindow;
    statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
  }

  lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_TOP_ = statusBarHeight;
  lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_BOTTOM_ = 0;
  lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_LEFT_ = 0;
  lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_RIGHT_ = 0;
  if (@available(iOS 11.0, *)) {
    lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_BOTTOM_ = keyWindow.safeAreaInsets.bottom;
    lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_LEFT_ = keyWindow.safeAreaInsets.left;
    lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_RIGHT_ = keyWindow.safeAreaInsets.right;
  }
  LLogInfo(@"LynxEnv: init safe area, top:%f , bottom:%f, left:%f, right:%f.",
           lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_TOP_,
           lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_BOTTOM_,
           lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_LEFT_,
           lynx::starlight::ComputedCSSStyle::SAFE_AREA_INSET_RIGHT_);
#endif
}

- (void)setCronetEngine:(void *)engine {
  _cronetEngine = engine;
}

- (void)setCronetServerConfig:(void *)config {
  _cronetServerConfig = config;
}

- (void)enableFluencyTracer:(BOOL)value {
  lynx::tasm::FluencyTracer::SetEnable(value);
}

+ (NSMutableDictionary *)getExperimentSettingsMap {
  static NSMutableDictionary *_experimentSettingsMap = nil;
  static dispatch_once_t experimentSettingsMapOnceToken;
  dispatch_once(&experimentSettingsMapOnceToken, ^{
    _experimentSettingsMap = [NSMutableDictionary new];
  });

  return _experimentSettingsMap;
}

+ (NSString *)getExperimentSettings:(NSString *)key {
  NSMutableDictionary *experimentSettingsMap = [self getExperimentSettingsMap];
  @synchronized(experimentSettingsMap) {
    NSString *value = [experimentSettingsMap objectForKey:key];
    if (value) {
      return value;
    }
    value = [LynxTrail stringValueFromABSettings:key];
    if (value == nil) {
      value = @"";
    }
    [experimentSettingsMap setValue:value forKey:key];
    return value;
  }
}

+ (BOOL)getBoolExperimentSettings:(NSString *)key {
  NSString *value = [self getExperimentSettings:key];
  if ([value isEqualToString:@"true"] || [value isEqualToString:@"1"]) {
    return YES;
  }
  return NO;
}

+ (NSString *)stringValueFromSettings:(NSDictionary *)settings
                                group:(NSString *)group
                                  key:(NSString *)key {
  if (!group || !key || ![settings isKindOfClass:NSDictionary.class]) {
    return nil;
  }
  NSDictionary *groupDict = settings[group];
  if (![groupDict isKindOfClass:NSDictionary.class]) {
    return nil;
  }
  id value = groupDict[key];
  if (![value isKindOfClass:NSString.class]) {
    return nil;
  }
  return value;
}

+ (BOOL)boolValueFromSettings:(NSDictionary *)settings
                        group:(NSString *)group
                          key:(NSString *)key
                 defaultValue:(BOOL)defaultValue {
  NSString *value = [self stringValueFromSettings:settings group:group key:key].lowercaseString;
  if (value == nil) {
    return defaultValue;
  }
  return [value isEqualToString:@"1"] || [value isEqualToString:@"yes"] ||
         [value isEqualToString:@"true"];
}

@end
