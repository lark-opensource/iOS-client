// Copyright 2019 The Lynx Authors. All rights reserved.

#import <DebugRouter/DebugRouterSlot.h>
#import <Lynx/LynxEnv.h>
#import <Lynx/LynxEnvKey.h>
#import <Lynx/LynxInspectorManagerDarwin.h>
#import <Lynx/LynxLazyLoad.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxService.h>
#import <Lynx/LynxServiceDevProtocol.h>
#import <Lynx/LynxTemplateRender+Internal.h>
#import <objc/runtime.h>
#import "DevtoolAgentDarwin.h"
#import "DevtoolLepusManagerDarwin.h"
#import "DevtoolMonitorView.h"
#import "DevtoolRuntimeManagerDarwin.h"
#import "Helper/LynxEmulateTouchHelper.h"
#import "Helper/LynxUITreeHelper.h"
#import "Helper/TestbenchDumpFileHelper.h"
#import "LynxDebugBridge.h"
#import "LynxDevMenu.h"
#import "LynxDevtool/LynxUIEvent+EmulateEvent.h"
#import "LynxDevtool/LynxUITouch+EmulateTouch.h"
#import "LynxDevtoolDownloader.h"
#import "LynxDevtoolEnv.h"
#import "LynxDevtoolToast.h"
#import "LynxInspectorOwner+Internal.h"
#import "LynxScreenCastHelper.h"
#include "tasm/recorder/recorder_controller.h"
#include "tasm/template_assembler.h"

#include <memory>
#include <mutex>
#include <queue>
#include "base/closure.h"
#include "base/screen_metadata.h"
#include "tasm/replay/replay_controller.h"
#if LYNX_ENABLE_TRACING
#import "LynxFrameViewTrace.h"
#endif

@interface LynxDevService : NSObject <LynxServiceDevProtocol>
@end
@LynxServiceRegister(LynxDevService) @implementation LynxDevService

+ (LynxServiceScope)serviceScope {
  return LynxServiceScopeDefault;
}

+ (LynxServiceType)serviceType {
  return LynxServiceDev;
}

+ (NSString*)serviceBizID {
  return DEFAULT_LYNX_SERVICE;
}

- (BOOL)lynxDebugEnabled {
  return YES;
}

@end

@interface LynxInspectorOwner () <DebugRouterSlotDelegate>

@end

using lynx::tasm::HmrData;

#pragma mark - LynxInspectorOwner
@implementation LynxInspectorOwner {
  // Base Data
  int session_id_;
  int connection_id_;
  __weak LynxView* _lynxView;
  BOOL _isDebugging;
  int64_t record_id;
  std::mutex mutex_;
  std::queue<std::string> message_buf_;

  // Devtool Agent
  DevtoolAgentDarwin* _agent;

  // Inspector manager
  LynxInspectorManagerDarwin* _darwin;

  // Inspector runtime manager
  DevtoolRuntimeManagerDarwin* _runtime;

  // Lepus debug manager
  DevtoolLepusManagerDarwin* _lepus;

  // DevMenu
  LynxDevMenu* _devMenu;

  // PageReload
  LynxPageReloadHelper* _reloadHelper;

  // ScreenCast
  LynxScreenCastHelper* _castHelper;

  // UITree
  LynxUITreeHelper* _uiTreeHelper;

  // EmulateTouch
  LynxEmulateTouchHelper* _touchHelper;

  DebugRouterSlot* _debug_router_slot;

  NSMapTable* _message_subscribers;

  NSMutableDictionary<NSNumber*, LynxCallbackBlock>* _invoke_cdp_callback_map;
  int _cdp_callback_id;
  std::atomic<bool> _has_cdp_called;
}

- (instancetype)init {
  if (self = [super init]) {
    _debug_router_slot = [[DebugRouterSlot alloc] init];
    _debug_router_slot.delegate = self;

    _darwin = [[LynxInspectorManagerDarwin alloc] initWithOwner:self];
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
    _runtime = [[DevtoolRuntimeManagerDarwin alloc] initWithInspectorOwner:self];
#endif
    _agent = [[DevtoolAgentDarwin alloc] initWithInspectorOwner:self withInspectorManager:_darwin];
  }
  return self;
}

- (nonnull instancetype)initWithLynxView:(nullable LynxView*)view {
  _lynxView = view;
  _isDebugging = NO;
  session_id_ = 0;
  if (![LynxEnv.sharedInstance getDevtoolEnv:@"disableInspectorV8Runtime" withDefaultValue:NO]) {
    static dispatch_once_t initV8EnvOnce;
    dispatch_once(&initV8EnvOnce, ^{
      Class v8InspectorEnvClass = NSClassFromString(@"InspectorV8Env");
      SEL selector = NSSelectorFromString(@"initEnv");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [v8InspectorEnvClass performSelector:selector];
#pragma clang diagnostic pop
    });
  }

  // Inspector manager
  _darwin = [[LynxInspectorManagerDarwin alloc] initWithOwner:self];

#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
  // Inspector runtime manager
  _runtime = [[DevtoolRuntimeManagerDarwin alloc] initWithInspectorOwner:self];
  [_runtime setInspectorManager:[_darwin getNativePtr]];
#endif

  // Lepus debug manager
  _lepus = [[DevtoolLepusManagerDarwin alloc] initWithInspectorOwner:self];

  // Devtool agent
  _agent = [[DevtoolAgentDarwin alloc] initWithInspectorOwner:self withInspectorManager:_darwin];

  // DevMenu
  _devMenu = [[LynxDevMenu alloc] initWithInspectorOwner:self];

  // PageReload
  _reloadHelper = nil;

  // ScreenCast
  _castHelper = [[LynxScreenCastHelper alloc] initWithLynxView:view withOwner:self];

  // UITreeHelper
  _uiTreeHelper = [[LynxUITreeHelper alloc] init];

  // EmulateTouch
  _touchHelper = [[LynxEmulateTouchHelper alloc] initWithLynxView:view withOwner:self];

  _debug_router_slot = [[DebugRouterSlot alloc] init];
  _debug_router_slot.delegate = self;

  _message_subscribers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                               valueOptions:NSMapTableWeakMemory];
  _invoke_cdp_callback_map = [[NSMutableDictionary alloc] init];
  _has_cdp_called.store(false);

#if LYNX_ENABLE_TRACING
  [[LynxFrameViewTrace shareInstance] attachView:view];
#endif

  return self;
}

- (void)setReloadHelper:(nullable LynxPageReloadHelper*)reloadHelper {
  _reloadHelper = reloadHelper;
}

- (void)call:(NSString*)function withParam:(NSString*)params {
  if ([function isEqualToString:@"TranspondMessage"]) {
    [self sendResponse:[params UTF8String]];
  } else if (_agent) {
    [_agent call:function withParam:params];
  }
}

- (intptr_t)GetLynxDevtoolFunction {
  if (_agent != nil) {
    return [_agent GetLynxDevtoolFunction];
  } else {
    return 0;
  }
}

- (void)onTemplateAssemblerCreated:(intptr_t)ptr {
  if (_darwin != nil) {
    [_darwin onTemplateAssemblerCreated:ptr];
  }
  self->record_id = ptr;
}

- (void)dispatchDocumentUpdated {
  [_debug_router_slot dispatchDocumentUpdated];
}

- (void)dispatchScreencastVisibilityChanged:(Boolean)status {
  [_debug_router_slot dispatchScreencastVisibilityChanged:status];
}

- (void)setPostUrl:(nullable NSString*)postUrl {
  // deprecated
}

- (void)dispatchStyleSheetAdded {
  NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
  msg[@"method"] = @"CSS.styleSheetAdded";
  msg[@"params"] = [[NSMutableDictionary alloc] init];
  msg[@"params"][@"all"] = @"true";
  NSData* json = [NSJSONSerialization dataWithJSONObject:msg
                                                 options:NSJSONWritingPrettyPrinted
                                                   error:nil];
  [self dispatchMessage:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
}

- (void)onLoadFinished {
  // Attach debug bridge if necessary
  if ([[LynxDebugBridge singleton] isEnabled]) {
    if ([_lynxView isKindOfClass:[DevtoolMonitorView class]]) {
      [[LynxDebugBridge singleton] sendDebugStateEvent];
    }
  }
}

- (void)onFirstScreen {
  if (_debug_router_slot && LynxDevtoolEnv.sharedInstance.previewScreenshotEnabled &&
      [[LynxDebugBridge singleton] isEnabled]) {
    // delay 1500ms to leave buffer time for rendering remote resources
    [self sendCardPreviewWithDelay:1500];
  }
}

- (void)reloadLynxView:(BOOL)ignoreCache {
  [self reloadLynxView:ignoreCache withTemplate:nil fromFragments:NO withSize:0];
}

- (void)reloadLynxView:(BOOL)ignoreCache
          withTemplate:(NSString*)templateBin
         fromFragments:(BOOL)fromFragments
              withSize:(int32_t)size {
  LynxDevtoolToast* toast =
      [[LynxDevtoolToast alloc] initWithMessage:@"Start to download & reload..."];
  [toast show];
  [_reloadHelper reloadLynxView:ignoreCache
                   withTemplate:templateBin
                  fromFragments:fromFragments
                       withSize:size];
}

- (void)onReceiveTemplateFragment:(NSString*)data withEof:(BOOL)eof {
  [_reloadHelper onReceiveTemplateFragment:data withEof:eof];
}

- (void)navigateLynxView:(nonnull NSString*)url {
  [_reloadHelper navigateLynxView:url];
}

- (void)startCasting:(int)quality width:(int)max_width height:(int)max_height {
  [_debug_router_slot clearScreenCastCache];
  [_castHelper startCasting:quality width:max_width height:max_height];
}

- (void)stopCasting {
  [_castHelper stopCasting];
}

- (void)continueCasting {
  [_castHelper continueCasting];
}

- (void)pauseCasting {
  [_castHelper pauseCasting];
}

- (LynxView*)getLynxView {
  return _lynxView;
}

- (void)sendScreenCast:(NSString*)data
           andMetadata:(std::shared_ptr<lynxdev::devtool::ScreenMetadata>)metadata {
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  dict[@"offsetTop"] = @(metadata->offset_top_);
  dict[@"pageScaleFactor"] = @(metadata->page_scale_factor_);
  dict[@"deviceWidth"] = @(metadata->device_width_);
  dict[@"deviceHeight"] = @(metadata->device_height_);
  dict[@"scrollOffsetX"] = @(metadata->scroll_off_set_x_);
  dict[@"scrollOffsetY"] = @(metadata->scroll_off_set_y_);
  dict[@"timestamp"] = @(metadata->timestamp_);
  [_debug_router_slot sendScreenCast:data andMetadata:dict];
}

// send card preview after delay miliseconds
- (void)sendCardPreviewWithDelay:(int)delay {
  if (delay <= 0) {
    [self sendCardPreview];
    return;
  }
  __weak __typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delay * NSEC_PER_MSEC),
                 dispatch_get_main_queue(), ^{
                   __strong __typeof(weakSelf) strongSelf = weakSelf;
                   [strongSelf sendCardPreview];
                 });
}

- (void)sendCardPreview {
  if (_debug_router_slot) {
    NSString* cardPreviewData = [_castHelper takeCardPreview];
    if (cardPreviewData) {
      NSDictionary* param =
          [[NSMutableDictionary alloc] initWithDictionary:@{@"data" : cardPreviewData}];
      NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
      msg[@"params"] = param;
      msg[@"method"] = @"Lynx.screenshotCaptured";
      if ([NSJSONSerialization isValidJSONObject:msg]) {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:msg options:0 error:nil];
        NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_debug_router_slot sendDataAsync:jsonStr WithType:@"CDP"];
      }
    }
  }
}

- (void)emulateTouch:(std::shared_ptr<lynxdev::devtool::MouseEvent>)input {
  NSString* type = [NSString stringWithCString:input->type_.c_str()
                                      encoding:[NSString defaultCStringEncoding]];
  NSString* button = [NSString stringWithCString:input->button_.c_str()
                                        encoding:[NSString defaultCStringEncoding]];
  [self emulateTouch:type
         coordinateX:input->x_
         coordinateY:input->y_
              button:button
              deltaX:input->delta_x_
              deltaY:input->delta_y_
           modifiers:input->modifiers_
          clickCount:input->clickcount_];
}

- (void)emulateTouch:(nonnull NSString*)type
         coordinateX:(int)x
         coordinateY:(int)y
              button:(nonnull NSString*)button
              deltaX:(CGFloat)dx
              deltaY:(CGFloat)dy
           modifiers:(int)modifiers
          clickCount:(int)clickCount {
  if (_touchHelper != nil) {
    __weak LynxEmulateTouchHelper* weakTouchHelper = _touchHelper;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakTouchHelper) strongTouchHelper = weakTouchHelper;
      if (!strongTouchHelper) {
        return;
      }
      [strongTouchHelper emulateTouch:type
                          coordinateX:x
                          coordinateY:y
                               button:button
                               deltaX:dx
                               deltaY:dy
                            modifiers:modifiers
                           clickCount:clickCount];
    });
  }
}

- (void)setConnectionID:(int)connectionID {
  connection_id_ = connectionID;
}

- (void)dealloc {
  [self stopCasting];
  [self setViewDestroyed:true];
  [_debug_router_slot pull];
}

- (void)handleLongPress {
  if (LynxEnv.sharedInstance.devtoolEnabled && LynxDevtoolEnv.sharedInstance.longPressMenuEnabled) {
    [self showDevMenu];
  }
}

- (void)showDevMenu {
  if (_devMenu != nil) {
    [_devMenu show];
  }
}

- (NSInteger)getSessionId {
  return session_id_;
}

- (void)dispatchMessage:(NSString*)message {
  [self setDebugActive:message];
  if (_agent != nil) {
    [_agent dispatchMessage:message];
    // FIXME: (qianxin.1024) should receive notification from page agent
    if ([message length] < 220 && [message containsString:@"screencastFrameAck"]) {
      [_castHelper onAckReceived];
    }
  }
}

- (void)setDebugActive:(NSString*)message {
  std::string mes = [message UTF8String];
  if (mes.find("Debugger.setDebugActive") != -1) {
    [DevtoolRuntimeManagerDarwin setDebugActive:mes.find("true") != -1];
  }
}

- (NSString*)getTemplateUrl {
  return _reloadHelper ? [_reloadHelper getURL] : @"___UNKNOWN___";
}

- (UIView*)getTemplateView {
  return _lynxView;
}

- (LynxTemplateData*)getTemplateData {
  return _reloadHelper ? [_reloadHelper getTemplateData] : nullptr;
}

- (NSString*)getTemplateConfigInfo {
  LynxView* lynxView = [self getLynxView];
  if (lynxView != nil) {
    NSData* data = [[lynxView lynxConfigInfo] json];
    if (data != nil) {
      return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
  }
  return nil;
}

- (void)sendResponse:(std::string)response {
  if (session_id_ == 0 && _lynxView) {
    std::lock_guard<std::mutex> lock(mutex_);
    message_buf_.push(response);
  } else {
    [_debug_router_slot sendDataAsync:[NSString stringWithUTF8String:response.c_str()]
                             WithType:@"CDP"];
  }
  [self responseCdpWithUtf8String:response.c_str()];
}

- (BOOL)isDebugging {
  return _isDebugging;
}

- (void)dispatchConsoleMessage:(NSString*)message
                     withLevel:(int32_t)level
                  withTimStamp:(int64_t)timeStamp {
  if (_agent != nil) {
    [_agent dispatchConsoleMessage:message withLevel:level withTimStamp:timeStamp];
  }
}

- (void)attach:(nonnull LynxView*)lynxView {
  _lynxView = lynxView;
  [_touchHelper attachLynxView:lynxView];
  [_castHelper attachLynxView:lynxView];
  [_reloadHelper attachLynxView:lynxView];
#if LYNX_ENABLE_TRACING
  [[LynxFrameViewTrace shareInstance] attachView:lynxView];
#endif
}

- (NSInteger)attachDebugBridge {
  if (session_id_ != 0) {
    return session_id_;
  }

  if (_debug_router_slot) {
    [self setSessionID:[_debug_router_slot plug]];
    [self flushMessageBuf];
  }
  return self->session_id_;
}

- (void)setSessionID:(NSInteger)session {
  CGSize size = [UIScreen mainScreen].bounds.size;
  self->session_id_ = (int)session;
  NSString* filePath =
      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  lynx::tasm::recorder::RecorderController::InitConfig([filePath UTF8String], self -> session_id_,
                                                       size.width, size.height, self->record_id);
}

- (void)flushMessageBuf {
  while (!message_buf_.empty()) {
    std::string mes;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      mes = message_buf_.front();
      message_buf_.pop();
    }
    [self sendResponse:mes];
  }
}

- (intptr_t)createInspectorRuntimeManager {
  if (_runtime != nil) {
    return [_runtime createInspectorRuntimeManager];
  } else {
    return 0;
  }
}

- (void)OnConnectionClose {
  if (_runtime != nil) {
    [_runtime StopDebug];
  }
}

- (void)OnConnectionOpen {
  if (_runtime != nil) {
    [_runtime DispatchDebuggerDisableMessage];
  }
}

- (void)sendTouchEvent:(nonnull NSString*)type sign:(int)sign x:(int)x y:(int)y {
  if (_darwin) {
    [_darwin sendTouchEvent:type sign:sign x:x y:y onLynxView:_lynxView];
  }
}

- (void)RunOnJSThread:(intptr_t)closure {
  if (_darwin) {
    [_darwin RunOnJSThread:closure];
  }
}

- (intptr_t)getJavascriptDebugger {
  if (_runtime != nil) {
    [_runtime setEnableNeeded:[[LynxDebugBridge singleton] isEnabled]];
    return [_runtime getJavascriptDebugger];
  } else {
    return 0;
  }
}

- (intptr_t)getLepusDebugger:(NSString*)url {
  if (_lepus != nil) {
    return [_lepus getJavascriptDebugger:url];
  } else {
    return 0;
  }
}

- (void)DispatchMessageToJSEngine:(std::string)message {
  auto pos = message.find("LEPUSDEBUGSESSIONID");
  if (pos == -1 && _runtime != nil) {
    [_runtime DispatchMessageToJSEngine:message];
  } else if (pos != -1 && _lepus != nil) {
    [_lepus DispatchMessageToJSEngine:message];
  }
}

- (void)setShowConsoleBlock:(LynxDevMenuShowConsoleBlock)block {
  if (_devMenu) {
    [_devMenu setShowConsoleBlock:block];
  }
}

- (void)onMessage:(NSString*)message WithType:(NSString*)type {
  if ([type isEqual:@"CDP"]) {
    [self dispatchMessage:message];
  } else if ([type isEqual:@"HMR"]) {
    [self handleHmrMessage:message];
  } else {
    id<MessageHandler> handler = [_message_subscribers objectForKey:type];
    [handler onMessage:message];
  }
}

- (void)handleHmrMessage:(NSString*)message {
  NSData* jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
  NSError* err;
  NSDictionary* params = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&err];
  if (err) {
    NSLog(@"[hmr], error. Message: %@", message);
    return;
  }

  NSArray* paramsArray = [params objectForKey:@"components"];
  for (NSDictionary* obj in paramsArray) {
    NSDictionary* params = [obj objectForKey:@"data"];
    if ([[params objectForKey:@"type"] isEqualToString:@"card"]) {
      if ([params[@"isFullReload"] boolValue]) {
        // trigger full reload and return
        [_reloadHelper reloadLynxView:YES];
        return;
      }
    }
  }

  __block std::vector<HmrData> components_datas;

  // format data to native
  for (NSDictionary* obj in paramsArray) {
    NSDictionary* params = [obj objectForKey:@"data"];
    // can be used for dynamic-component
    const std::string url = std::string([params[@"url"] UTF8String]);
    const std::string update_url = std::string([params[@"updateUrl"] UTF8String]);
    const std::string url_download_template =
        [params[@"isFullReload"] boolValue] ? url : update_url;
    std::vector<uint8_t> bin_data{0};
    components_datas.emplace_back(url, url_download_template, bin_data);
  }

  // download "template.js" for components and card
  long templatesCount = components_datas.size();
  __block int download_count = 0;
  __weak LynxInspectorOwner* weakSelf = self;

  for (__block auto& item : components_datas) {
    NSString* url = [[NSString alloc] initWithUTF8String:item.url_download_template.c_str()];
    LynxResourceLoadBlock complete = ^(LynxResourceResponse* response) {
      NSData* binary = response.data;
      if (!response.success || binary.length == 0) {
        NSLog(@"[hmr], error for url: %@", url);
        return;
      }
      download_count++;
      // fill with new template data
      std::vector<uint8_t> result;
      result.resize(binary.length);
      std::memcpy(result.data(), reinterpret_cast<const uint8_t*>(binary.bytes), binary.length);
      item.template_bin_data = result;
      // after all "template.js" is ready, call native
      if (download_count == templatesCount) {
        // post to main thread in order to avoid crash
        dispatch_async(dispatch_get_main_queue(), ^() {
          __strong __typeof(weakSelf) strongSelf = weakSelf;
          [strongSelf hotModuleReplaceWithHmrData:std::move(components_datas)
                                          message:std::string([message UTF8String])];
        });
      }
    };
    [self downloadResource:url callback:complete];
  }
}

- (void)hotModuleReplaceWithHmrData:(const std::vector<HmrData>&)component_datas
                            message:(const std::string&)message {
  if (_darwin != nil) {
    [_darwin HotModuleReplaceWithHmrData:component_datas message:message];
  }
}

- (void)sendMessage:(CustomizedMessage*)message {
  [_debug_router_slot sendDataAsync:message.data WithType:message.type WithMark:message.mark];
}

- (void)subscribeMessage:(NSString*)type withHandler:(id<MessageHandler>)handler {
  [_message_subscribers setObject:handler forKey:type];
}

- (void)unsubscribeMessage:(NSString*)type {
  [_message_subscribers removeObjectForKey:type];
}

- (void)invokeCdp:(NSString*)type message:(NSString*)message callback:(LynxCallbackBlock)callback {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf->_has_cdp_called.store(true);
    strongSelf->_cdp_callback_id++;
    NSNumber* key = [NSNumber numberWithInt:strongSelf->_cdp_callback_id];
    [strongSelf->_invoke_cdp_callback_map setObject:callback forKey:key];
    NSError* error = nil;
    NSData* jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
    NSMutableDictionary* m = [jsonDict mutableCopy];
    [m setObject:key forKey:@"id"];
    jsonData = [NSJSONSerialization dataWithJSONObject:m
                                               options:NSJSONWritingPrettyPrinted
                                                 error:&error];
    NSString* jsonString;
    if (jsonData) {
      jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
      NSLog(@"error for cdp json : %@", message);
    }

    [self dispatchMessage:jsonString];
  });
}

- (void)responseCdpWithUtf8String:(const char*)response {
  if (!_has_cdp_called.load()) {
    return;
  }
  NSString* response_ns = [NSString stringWithUTF8String:response];
  __weak typeof(self) weakSelf = self;
  void (^cdpResponseBlock)() = ^(void) {
    __strong typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if ([strongSelf->_invoke_cdp_callback_map count] == 0) {
      strongSelf->_has_cdp_called.store(false);
      return;
    }
    NSError* error = nil;
    NSData* jsonData = [response_ns dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
    NSNumber* cdp_module_call_id = jsonDict[@"id"];
    if (cdp_module_call_id) {
      LynxCallbackBlock cdp_call_back =
          [strongSelf->_invoke_cdp_callback_map objectForKey:cdp_module_call_id];
      if (cdp_call_back) {
        [strongSelf->_invoke_cdp_callback_map removeObjectForKey:cdp_module_call_id];
        lynx::base::closure callback = [cdp_call_back, response_ns]() {
          cdp_call_back(response_ns);
        };
        [strongSelf RunOnJSThread:reinterpret_cast<intptr_t>(&callback)];
      }
    }
  };

  if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
             dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
    cdpResponseBlock();
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      cdpResponseBlock();
    });
  }
}

- (void)setViewDestroyed:(bool)destroyed {
  if (_runtime) {
    [_runtime setViewDestroyed:destroyed];
  }
}

- (void)setSharedVM:(LynxGroup*)group {
  [_runtime setSharedVM:group];
}

- (NSString*)groupID {
  return _runtime ? [_runtime groupName] : [LynxGroup singleGroupTag];
}

- (void)destroyDebugger {
  [_runtime DestroyDebug];
  [_lepus DestroyDebug];
  [_agent DestroyDebug];
}

- (void)endTestbench:(NSString*)filePath {
  NSLog(@"end testbench replay test");
  LynxTemplateRender* render = [self getLynxView].templateRender;
  NSString* ui_tree = [TestbenchDumpFileHelper getUITree:render.uiOwner.rootUI];
  std::string ui_tree_str([ui_tree UTF8String]);
  lynx::tasm::replay::ReplayController::SendFileByAgent("UITree", ui_tree_str);

  lynx::tasm::replay::ReplayController::EndTest(std::string([filePath UTF8String]));
}

- (int64_t)getRecordID {
  return self->record_id;
}

- (void)enableRecording:(bool)enable {
  LynxEnv.sharedInstance.recordEnable = enable;
}

- (void)enableTraceMode:(bool)enable {
  [LynxDevtoolEnv.sharedInstance setSwitchMask:!enable forKey:SP_KEY_ENABLE_DOM_TREE];
  [LynxDevtoolEnv.sharedInstance setSwitchMask:!enable forKey:SP_KEY_ENABLE_V8];
  [LynxDevtoolEnv.sharedInstance setSwitchMask:!enable forKey:SP_KEY_ENABLE_PREVIEW_SCREEN_SHOT];
}

- (void)onPageUpdate {
  NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
  msg[@"method"] = @"LayerTree.layerTreeDidChange";
  NSData* json = [NSJSONSerialization dataWithJSONObject:msg
                                                 options:NSJSONWritingPrettyPrinted
                                                   error:nil];
  [self dispatchMessage:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
}

- (void)downloadResource:(NSString* _Nonnull)url callback:(LynxResourceLoadBlock _Nonnull)callback {
  [LynxDevtoolDownloader
          download:url
      withCallback:^(NSData* _Nullable data, NSError* _Nullable error) {
        if (!error) {
          callback([[LynxResourceResponse alloc] initWithData:data]);
        } else {
          callback([[LynxResourceResponse alloc] initWithError:error
                                                          code:LynxResourceResponseCodeFailed]);
        }
      }];
}

- (void)attachLynxUIOwnerToAgent:(nullable LynxUIOwner*)uiOwner {
  if (_uiTreeHelper) {
    [_uiTreeHelper attachLynxUIOwner:uiOwner];
  }
}

- (int)findNodeIdForLocationWithX:(float)x withY:(float)y fromUI:(int)uiSign {
  if (_uiTreeHelper) {
    return [_uiTreeHelper findNodeIdForLocationWithX:x withY:y fromUI:uiSign];
  }
  return 0;
}

- (NSString*)getLynxUITree {
  NSString* res;
  if (_uiTreeHelper) {
    res = [_uiTreeHelper getLynxUITree];
  }
  return res;
}

- (NSString*)getUINodeInfo:(int)id {
  NSString* res;
  if (_uiTreeHelper) {
    res = [_uiTreeHelper getUINodeInfo:id];
  }
  return res;
}

- (int)setUIStyle:(int)id withStyleName:(NSString*)name withStyleContent:(NSString*)content {
  if (_uiTreeHelper) {
    return [_uiTreeHelper setUIStyle:id withStyleName:name withStyleContent:content];
  } else {
    return -1;
  }
}

@end
