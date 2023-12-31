// Copyright 2020 The Lynx Authors. All rights reserved.

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <memory>
#include <unordered_map>

#import "DevtoolMonitorView.h"
#import "LynxDebugBridge.h"
#import "LynxDeviceInfoHelper.h"
#import "LynxDevtoolEnv.h"
#import "LynxDevtoolToast.h"
#import "LynxInspectorOwner.h"
#if OS_IOS
#import <DebugRouter/DebugRouter.h>
#import <Lynx/LynxEnv.h>
#import <Lynx/LynxLog.h>
#import <vmsdk/monitor/VmsdkVersion.h>
#import "DevtoolLepusManagerDarwin.h"
#elif OS_OSX
#import <DebugRouterMacOS/DebugRouter.h>
#import <LynxMacOS/LynxEnv.h>
#import <LynxMacOS/LynxLog.h>
#endif
#include "config/devtool_config.h"
#include "tasm/recorder/ark_base_recorder.h"
#include "tasm/recorder/recorder_controller.h"

typedef LynxInspectorOwner DevtoolAgentDispatcher;

@interface LynxDebugBridge () <DebugRouterGlobalHandler, DebugRouterStateListener>

@end

@implementation LynxDebugBridge {
  DevtoolMonitorView *monitor_view_;
  DevtoolAgentDispatcher *agent_dispatcher_;
  BOOL has_set_open_card_callback_;
  NSMutableArray<LynxDebugBridgeOpenCardCallback> *open_card_callbacks;
}

+ (instancetype)singleton {
  static LynxDebugBridge *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[LynxDebugBridge alloc] init];
  });

  return _instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    agent_dispatcher_ = [[DevtoolAgentDispatcher alloc] init];
    open_card_callbacks = [[NSMutableArray alloc] init];
    [[DebugRouter instance].global_handlers addObject:self];
    [[DebugRouter instance] addStateListener:self];
  }
  return self;
}

- (BOOL)enable:(NSURL *)url withOptions:(NSDictionary *)options {
  if (!LynxEnv.sharedInstance.devtoolEnabled &&
      !LynxEnv.sharedInstance.devtoolEnabledForDebuggableView) {
    LynxDevtoolToast *toast =
        [[LynxDevtoolToast alloc] initWithMessage:@"Devtool not enabled, turn on the switch!"];
    [toast show];
    return NO;
  }

  if ([[DebugRouter instance] isValidSchema:url.absoluteString]) {
    signal(SIGPIPE, SIG_IGN);
    _hostOptions = options;
    [self setAppInfo:options];
    return [[DebugRouter instance] handleSchema:url.absoluteString];
  }
  return NO;
}

// only used by automatic test
- (void)enableDebugging:(NSString *)params {
  [[DebugRouter instance] handleSchema:params];
}

// only used by automatic test
- (void)setJSEngineType:(BOOL)enableV8 {
  [LynxDevtoolEnv.sharedInstance setV8Enabled:enableV8];
}

- (BOOL)isEnabled {
  return [DebugRouter instance].connection_state == CONNECTED;
}

using ClientInfo = std::unordered_map<std::string, std::string>;
- (ClientInfo)getClientInfo {
  ClientInfo map;
  for (NSString *key in _hostOptions) {
    map.insert(std::make_pair([key UTF8String],
                              std::string([[_hostOptions objectForKey:key] UTF8String])));
  }
  map.insert(std::make_pair("network", [[LynxDeviceInfoHelper getNetworkType] UTF8String]));
  map.insert(std::make_pair("deviceModel", [[LynxDeviceInfoHelper getDeviceModel] UTF8String]));
  map.insert(std::make_pair("osVersion", [[LynxDeviceInfoHelper getSystemVersion] UTF8String]));
  map.insert(std::make_pair("sdkVersion", [[LynxDeviceInfoHelper getLynxVersion] UTF8String]));
#if OS_IOS
  map.insert(std::make_pair("vmsdkVersion", [[VmsdkVersion versionString] UTF8String]));
#endif

  return map;
}

- (void)sendDebugStateEvent {
  if (self.debugState) {
    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:[NSString stringWithFormat:@"%@", self.debugState]];
    [monitor_view_ sendGlobalEvent:@"debugState" withParams:args];
  }
}

- (BOOL)hasSetOpenCardCallback {
  return has_set_open_card_callback_;
}

- (void)setOpenCardCallback:(LynxDebugBridgeOpenCardCallback)callback {
  [self addOpenCardCallback:callback];
}

- (void)addOpenCardCallback:(LynxDebugBridgeOpenCardCallback)callback {
  has_set_open_card_callback_ = YES;
  if (![open_card_callbacks containsObject:callback]) {
    [open_card_callbacks addObject:callback];
  }
}

- (void)openCard:(NSString *)url {
  LLogInfo(@"openCard: %@", url);
  for (LynxDebugBridgeOpenCardCallback callback in open_card_callbacks) {
    callback(url);
  }
}

- (void)onMessage:(NSString *)message withType:(NSString *)type {
  if ([type isEqualToString:@"D2RStopAtEntry"]) {
    bool stop = [message isEqualToString:@"true"];
    lynxdev::devtool::DevToolConfig::SetStopAtEntry(stop);
    [[DebugRouter instance] sendDataAsync:message WithType:@"R2DStopAtEntry" ForSession:-1];
  } else if ([type isEqualToString:@"D2RStopLepusAtEntry"]) {
#if OS_IOS
    bool stop = [message isEqualToString:@"true"];
    [DevtoolLepusManagerDarwin SetDebugActive:stop];
    [[DebugRouter instance] sendDataAsync:message WithType:@"R2DStopLepusAtEntry" ForSession:-1];
#endif
  } else if ([type isEqualToString:@"SetGlobalSwitch"]) {
    NSData *messageObj = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict =
        [NSJSONSerialization JSONObjectWithData:messageObj
                                        options:NSJSONReadingMutableContainers
                                          error:0];
    BOOL globalValue = [[messageDict objectForKey:@"global_value"] boolValue];
    [LynxDevtoolEnv.sharedInstance set:globalValue forKey:messageDict[@"global_key"]];
    [[DebugRouter instance] sendDataAsync:message WithType:@"SetGlobalSwitch" ForSession:-1];
  } else if ([type isEqualToString:@"GetGlobalSwitch"]) {
    NSData *messageObj = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict =
        [NSJSONSerialization JSONObjectWithData:messageObj
                                        options:NSJSONReadingMutableContainers
                                          error:0];
    NSString *key = messageDict[@"global_key"];
    BOOL result =
        [LynxDevtoolEnv.sharedInstance get:key
                          withDefaultValue:[LynxDevtoolEnv.sharedInstance getDefaultValue:key]];
    [[DebugRouter instance] sendDataAsync:((result) ? @"true" : @"false")
                                 WithType:@"GetGlobalSwitch"
                               ForSession:-1];
  } else if (agent_dispatcher_) {
    [agent_dispatcher_ dispatchMessage:message];
  }
}

- (void)onTracingComplete:(NSString *)traceFilePath {
  if (agent_dispatcher_) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"method"] = @"Tracing.tracingComplete";
    dict[@"trace_file"] = traceFilePath;
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    if (json) {
      NSString *msg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
      [agent_dispatcher_ dispatchMessage:msg];
    }
  }
}

- (void)setAppInfo:(NSDictionary *)hostOptions {
  for (NSString *key in hostOptions) {
    [DebugRouter instance].app_info[key] = hostOptions[key];
  }
  [DebugRouter instance].app_info[@"network"] = [LynxDeviceInfoHelper getNetworkType];
  [DebugRouter instance].app_info[@"deviceModel"] = [LynxDeviceInfoHelper getDeviceModel];
  [DebugRouter instance].app_info[@"osVersion"] = [LynxDeviceInfoHelper getSystemVersion];
  [DebugRouter instance].app_info[@"sdkVersion"] = [LynxDeviceInfoHelper getLynxVersion];
}

- (void)recordResource:(NSData *)data withKey:(NSString *)key {
  static NSMutableArray *cacheKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cacheKey = [NSMutableArray array];
  });
  if ([cacheKey containsObject:key]) {
    return;
  }
  [cacheKey addObject:key];
  lynx::tasm::recorder::RecorderController::RecordResource(
      [key UTF8String], [[data base64EncodedStringWithOptions:0] UTF8String]);
}

- (void)onClose {
  if (agent_dispatcher_) {
    [agent_dispatcher_ enableTraceMode:false];
  }
}

- (void)onError {
  if (agent_dispatcher_) {
    [agent_dispatcher_ enableTraceMode:false];
  }
}

- (void)onMessage:(nonnull id)message {
}

- (void)onOpen:(ConnectionType)type {
}

@end
