#import "DebugRouter.h"
#import "DebugRouterGlobalHandler.h"
#import "DebugRouterLog.h"
#import "DebugRouterSlot.h"
#import "DebugRouterVersion.h"
#ifdef OS_IOS
#import "PeertalkClient.h"
#endif
#import "WebSocketClient.h"

#ifndef OS_IOS
#import "DebugRouterSocketServerClient.h"
#endif

#include "processor/message_handler.h"
#include "processor/processor.h"

NSString *const KEY_FORBID_RECONNECT_ON_CLOSE =
    @"debugrouter_forbid_reconnect_on_close";

#pragma mark - MessageHandlerDarwin
class MessageHandlerDarwin : public debugrouter::processor::MessageHandler {
public:
  MessageHandlerDarwin(DebugRouter *router) : router_(router) {}

  std::string GetRoomId() override {
    return router_.room_id ? [router_.room_id UTF8String] : "";
  }

  std::unordered_map<std::string, std::string> GetClientInfo() override {
    std::unordered_map<std::string, std::string> client_info;
    for (NSString *key in [router_.app_info allKeys]) {
      client_info[[key UTF8String]] = [router_.app_info[key] UTF8String];
    }
    return client_info;
  }

  std::unordered_map<int, std::string> GetSessionList() override {
    std::unordered_map<int, std::string> session_list;
    if (router_.slots) {
      // FIXME: (zhoumingsong.smile) remove synchronized and unify thread policy
      @synchronized(router_.slots) {
        for (NSNumber *id in router_.slots) {
          DebugRouterSlot *slot = router_.slots[id];
          Json::Value session_info;
          session_info["type"] = std::string([slot.type UTF8String]);
          session_info["url"] = std::string([[slot getTemplateUrl] UTF8String]);
          session_list[[id intValue]] = session_info.toStyledString();
        }
      }
    }
    return session_list;
  }

  void OnMessage(const std::string &type, int session_id,
                 const std::string &message) override {
    if (session_id < 0) {
      // dispatch to global handler
      for (id handler in router_.global_handlers) {
        if ([handler conformsToProtocol:@protocol(DebugRouterGlobalHandler)]) {
          [handler onMessage:[NSString stringWithUTF8String:message.c_str()]
                    withType:[NSString stringWithUTF8String:type.c_str()]];
        }
      }
      return;
    }

    if (router_.slots) {
      // FIXME: (zhoumingsong.smile) remove synchronized and unify thread policy
      @synchronized(router_.slots) {
        for (NSNumber *id in router_.slots) {
          if ([id intValue] == session_id) {
            DebugRouterSlot *slot = router_.slots[id];
            [slot onMessage:[NSString stringWithUTF8String:message.c_str()]
                   WithType:[NSString stringWithUTF8String:type.c_str()]];
            break;
          }
        }
      }
    }
  }

  void SendMessage(const std::string &message) override {
    [router_ send:[NSString stringWithUTF8String:message.c_str()]];
  }

  void OpenCard(const std::string &url) override {
    LLogWarn(@"openCard %@", [NSString stringWithUTF8String:url.c_str()]);
    for (id handler in router_.global_handlers) {
      if ([handler conformsToProtocol:@protocol(DebugRouterGlobalHandler)]) {
        [handler openCard:[NSString stringWithUTF8String:url.c_str()]];
      }
    }
  }

  std::string HandleAppAction(const std::string &method,
                              const std::string &params) override {
    NSString *medthodNSString =
        [NSString stringWithCString:method.c_str()
                           encoding:[NSString defaultCStringEncoding]];
    id<DebugRouterMessageHandler> handler =
        [router_.messageHandlers objectForKey:medthodNSString];
    if (handler == nil) {
      NSString *noHandlerResultStr = [[[DebugRouterMessageHandleResult alloc]
          initWithCode:CODE_NOT_IMPLEMENTED
               message:NOT_IMPLETEMTED_MESSAGE] toJsonString];
      return std::string([noHandlerResultStr UTF8String]);
    }
    LLogInfo(@"%@ # %@ is handling", [handler getName], handler);
    Json::Value paramsJson;
    Json::Reader reader;
    bool result = reader.parse(params, paramsJson);
    if (!result) {
      LLogError(@"HandleAppAction: params is invalid json: %s ",
                params.c_str());
      NSString *errorStr = [[[DebugRouterMessageHandleResult alloc]
          initWithCode:-1
               message:@"params resolve error"] toJsonString];
      return std::string([errorStr UTF8String]);
    }
    NSMutableDictionary<NSString *, NSString *> *paramsMap =
        [[NSMutableDictionary alloc] init];
    for (auto it = paramsJson.begin(); it != paramsJson.end(); it++) {
      NSString *key =
          [NSString stringWithCString:it.key().asString().c_str()
                             encoding:[NSString defaultCStringEncoding]];
      std::string valueStr;
      if (it->isConvertibleTo(Json::stringValue)) {
        valueStr = it->asString();
      } else {
        valueStr = it->toStyledString();
      }
      NSString *value =
          [NSString stringWithCString:valueStr.c_str()
                             encoding:[NSString defaultCStringEncoding]];
      [paramsMap setObject:value forKey:key];
    }
    DebugRouterMessageHandleResult *handleResult =
        [handler handleMessageWithParams:paramsMap];
    if (handleResult == nil) {
      handleResult = [[DebugRouterMessageHandleResult alloc] init];
    }
    return std::string([[handleResult toJsonString] UTF8String]);
  }

  void ChangeRoomServer(const std::string &url,
                        const std::string &room) override {
    [router_ connect:[NSString stringWithUTF8String:url.c_str()]
              ToRoom:[NSString stringWithUTF8String:room.c_str()]];
  }

private:
  __weak DebugRouter *router_;
};

#pragma mark - DebugRouter
@interface DebugRouter () <MessageTransceiverDelegate>

@end

@implementation DebugRouter {
  MessageTransceiver *currentTransceiver_;
  NSArray *messageTransceivers_;
  int max_session_id_;
  std::unique_ptr<debugrouter::processor::Processor> processor_;
  dispatch_queue_t work_queue_;
  NSMutableArray *stateListeners_;
  int retry_times_;
  NSMutableDictionary *configs_;
}

+ (DebugRouter *)instance {
  static DebugRouter *instance_ = nil;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    instance_ = [[DebugRouter alloc] init];
  });
  return instance_;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    DebugRouterAddDebugLogObserver();
    currentTransceiver_ = nil;
    messageTransceivers_ =
        [NSArray arrayWithObjects:[[WebSocketClient alloc] init],
#ifdef OS_IOS
#if !(TARGET_IPHONE_SIMULATOR)
                                  [[PeertalkClient alloc] init],
#endif
#endif
#ifndef OS_IOS
                                  [[DebugRouterSocketServerClient alloc] init],
#endif
                                  nil];
    for (MessageTransceiver *transceiver in messageTransceivers_) {
      transceiver.delegate_ = self;
    }
    max_session_id_ = 0;
    self.slots = [[NSMutableDictionary alloc] init];
    self.views = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory
                                       valueOptions:NSMapTableWeakMemory];
    std::unique_ptr<debugrouter::processor::MessageHandler> handler =
        std::make_unique<MessageHandlerDarwin>(self);
    processor_ =
        std::make_unique<debugrouter::processor::Processor>(std::move(handler));
    self.connection_state = DISCONNECTED;
    work_queue_ = dispatch_queue_create("DebugRouter", DISPATCH_QUEUE_SERIAL);
    self.global_handlers = [[NSMutableArray alloc] init];
    self.messageHandlers = [[NSMutableDictionary alloc] init];
    self.app_info = [[NSMutableDictionary alloc] init];
    self.app_info[@"App"] = [[NSProcessInfo processInfo] processName];
    self.app_info[@"debugRouterVersion"] = [DebugRouterVersion versionString];
    stateListeners_ = [[NSMutableArray alloc] init];
    configs_ = [[NSMutableDictionary alloc] init];
    _cronet_initialized = NO;
  }
  return self;
}

- (void)connect:(NSString *)url ToRoom:(NSString *)room {
  LLogInfo(@"connect url: %@, room: %@", url, room);
  [self disconnect];
  for (MessageTransceiver *transceiver in messageTransceivers_) {
    if ([transceiver connect:url]) {
      break;
    }
  }
  self.connection_state = CONNECTING;
  self.server_url = url;
  self.room_id = room;
}

- (void)disconnect {
  LLogInfo(@"disconnect");
  if (self.connection_state != DISCONNECTED) {
    [currentTransceiver_ disconnect];
    self.connection_state = DISCONNECTED;
    currentTransceiver_ = nil;
  }
}

- (void)reconnect {
  if (self.server_url && self.room_id) {
    [self connect:self.server_url ToRoom:self.room_id];
  }
}

- (void)send:(NSString *)message {
  if (self.connection_state == CONNECTED) {
    [currentTransceiver_ send:message];
  } else {
    LLogWarn(@"send message error: not connected:%@", message);
  }
}

- (void)sendData:(NSString *)data
        WithType:(NSString *)type
      ForSession:(int)session {
  [self sendData:data WithType:type ForSession:session WithMark:-1];
}

- (void)sendData:(NSString *)data
        WithType:(NSString *)type
      ForSession:(int)session
        WithMark:(int)mark {
  [self sendData:data WithType:type ForSession:session WithMark:-1 isObject:NO];
}

- (void)sendObject:(NSDictionary *)data
          WithType:(NSString *)type
        ForSession:(int)session {
  [self sendObject:data WithType:type ForSession:session WithMark:-1];
}

- (void)sendObject:(NSDictionary *)data
          WithType:(NSString *)type
        ForSession:(int)session
          WithMark:(int)mark {
  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:data
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];
  NSString *jsonString;
  if (jsonData) {
    jsonString = [[NSString alloc] initWithData:jsonData
                                       encoding:NSUTF8StringEncoding];
    [self sendData:jsonString
          WithType:type
        ForSession:session
          WithMark:mark
          isObject:YES];
  }
}

- (void)sendData:(NSString *)data
        WithType:(NSString *)type
      ForSession:(int)session
        WithMark:(int)mark
        isObject:(BOOL)isObject {
  if (data == nil) {
    return;
  }
  if (self.connection_state == CONNECTED) {
    std::string message = processor_->WrapCustomizedMessage(
        [type UTF8String], session, [data UTF8String], mark, isObject);
    [self send:[NSString stringWithUTF8String:message.c_str()]];
  } else {
    LLogWarn(@"sendData error: not connected: %@", data);
  }
}

- (void)sendAsync:(NSString *)message {
  dispatch_async(work_queue_, ^{
    [self send:message];
  });
}

- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
           ForSession:(int)session {
  [self sendDataAsync:data WithType:type ForSession:session WithMark:-1];
}

- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
           ForSession:(int)session
             WithMark:(int)mark {
  dispatch_async(work_queue_, ^{
    [self sendData:data WithType:type ForSession:session WithMark:mark];
  });
}

- (void)sendObjectAsync:(NSDictionary *)data
               WithType:(NSString *)type
             ForSession:(int)session {
  [self sendObjectAsync:data WithType:type ForSession:session WithMark:-1];
}

- (void)sendObjectAsync:(NSDictionary *)data
               WithType:(NSString *)type
             ForSession:(int)session
               WithMark:(int)mark {
  dispatch_async(work_queue_, ^{
    [self sendObject:data WithType:type ForSession:session WithMark:mark];
  });
}

- (int)plug:(DebugRouterSlot *)slot {
  max_session_id_++;
  // FIXME: (zhoumingsong.smile) remove synchronized and unify thread policy
  @synchronized(self.slots) {
    self.slots[@(max_session_id_)] = slot;
  }
#if defined(OS_IOS)
  UIView *view = [slot getTemplateView];
#elif defined(OS_OSX)
  NSView *view = [slot getTemplateView];
#endif
  [self.views setObject:@(max_session_id_) forKey:(id)view];
  LLogWarn(@"plug session %d", max_session_id_);
  if (self.connection_state == CONNECTED) {
    processor_->FlushSessionList();
  } else {
    LLogWarn(@"plug session error: not connected: %d", max_session_id_);
  }
  return max_session_id_;
}

- (void)pull:(int)sessionId {
  LLogWarn(@"pull session %d", sessionId);
  // FIXME: (zhoumingsong.smile) remove synchronized and unify thread policy
  @synchronized(self.slots) {
    [self.slots removeObjectForKey:@(sessionId)];
  }
  if (self.connection_state == CONNECTED) {
    processor_->FlushSessionList();
  } else {
    LLogWarn(@"pull session error: not connected: %d", sessionId);
  }
}

#if defined(OS_IOS)
- (int)getSessionIdByView:(UIView *)view {
#elif defined(OS_OSX)
- (int)getSessionIdByView:(NSView *)view {
#endif
  NSNumber *session_number = [self.views objectForKey:(id)view];
  return session_number ? [session_number intValue] : 0;
}

- (void)onOpen:(MessageTransceiver *)transceiver {
  if (self.connection_state == CONNECTED) {
    [currentTransceiver_ disconnect];
  }
  currentTransceiver_ = transceiver;
  self.connection_state = CONNECTED;

  for (id<DebugRouterStateListener> listener in stateListeners_) {
    [listener onOpen:[currentTransceiver_ isKindOfClass:[WebSocketClient class]]
                         ? WebSocket
                         : USB];
  }
  retry_times_ = 0;
}

- (void)onClosed:(MessageTransceiver *)transceiver {
  LLogInfo(@"onClosed");
  if (transceiver != currentTransceiver_ ||
      self.connection_state == DISCONNECTED) {
    return;
  }
  self.connection_state = DISCONNECTED;

  for (id<DebugRouterStateListener> listener in stateListeners_) {
    [listener onClose];
  }

  if (![self isForbidReconnectOnClose] &&
      [transceiver isKindOfClass:WebSocketClient.class]) {
    LLogWarn(@"onClosed: try to reconnect");
    [self tryToReconnect];
  }
}

- (void)onFailure:(MessageTransceiver *)transceiver {
  LLogInfo(@"onFailure");
  if (transceiver != currentTransceiver_ ||
      self.connection_state == DISCONNECTED) {
    return;
  }
  self.connection_state = DISCONNECTED;

  for (id<DebugRouterStateListener> listener in stateListeners_) {
    [listener onError];
  }

  if ([transceiver isKindOfClass:WebSocketClient.class]) {
    LLogWarn(@"onFailure: try to reconnect");
    [self tryToReconnect];
  }
}

- (void)onMessage:(NSString *)message
    fromTransceiver:(MessageTransceiver *)transceiver {
  if (transceiver != currentTransceiver_) {
    return;
  }
  processor_->Process([message UTF8String]);

  for (id<DebugRouterStateListener> listener in stateListeners_) {
    [listener onMessage:message];
  }
}

- (void)addGlobalHandler:(id<DebugRouterGlobalHandler>)handler {
  if (![self.global_handlers containsObject:handler]) {
    [self.global_handlers addObject:handler];
  }
}

- (void)addMessageHandler:(id<DebugRouterMessageHandler>)handler {
  if (handler == nil) {
    LLogWarn(@"addMessageControlHandler handle == nullptr");
    return;
  }
  id<DebugRouterMessageHandler> existHandler =
      [self.messageHandlers valueForKey:[handler getName]];

  if (existHandler != nil) {
    LLogWarn(@"handler override, previous: %@, now: %@", existHandler, handler);
  } else {
    LLogInfo(@"add new handler: %@", handler);
  }

  [self.messageHandlers setValue:handler forKey:[handler getName]];
}

- (BOOL)isValidSchema:(NSString *)schema {
  return [schema containsString:@"remote_debug_lynx"];
}

- (BOOL)handleSchema:(NSString *)schema {
  LLogInfo(@"handleSchema: %@", schema);
  NSURLComponents *components = [NSURLComponents componentsWithString:schema];
  NSString *cmd = components.path;
  NSArray *queryItems = components.queryItems;
  NSString *url = nil;
  NSString *room = nil;
  for (NSURLQueryItem *item in queryItems) {
    if ([item.name isEqualToString:@"url"]) {
      url = [NSString stringWithString:item.value];
    }
    if ([item.name isEqualToString:@"room"]) {
      room = [NSString stringWithString:item.value];
    }
  }

  if (!url || !room) {
    LLogError(@"Invalid schema");
    return NO;
  }

  if ([cmd isEqualToString:@"/enable"]) {
    [[DebugRouter instance] disconnect];
    [[DebugRouter instance] connect:url ToRoom:room];
  } else if ([cmd isEqualToString:@"/disable"]) {
    [[DebugRouter instance] disconnect];
  }

  return YES;
}

- (void)addStateListener:(id<DebugRouterStateListener>)listener {
  [stateListeners_ addObject:listener];
}

- (void)tryToReconnect {
  if (retry_times_ < 30) {
    retry_times_++;
    LLogWarn(@"try to reconnect: #%d", retry_times_);
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
        work_queue_, ^{
          if (self.connection_state != CONNECTED) {
            [self reconnect];
          }
        });
  } else {
    retry_times_ = 0;
  }
}

- (void)setCronet_engine:(void *)cronet_engine {
#ifdef OS_OSX
  if (!_cronet_initialized) {
    _cronet_initialized = YES;
    for (MessageTransceiver *transceiver in messageTransceivers_) {
      if ([transceiver isKindOfClass:[WebSocketClient class]]) {
        WebSocketClient *ws_client = (WebSocketClient *)transceiver;
        [ws_client setCronet_engine:cronet_engine];
        break;
      }
    }
  }
#endif
}

- (void *)cronet_engine {
#ifdef OS_OSX
  if (_cronet_initialized) {
    for (MessageTransceiver *transceiver in messageTransceivers_) {
      if ([transceiver isKindOfClass:[WebSocketClient class]]) {
        WebSocketClient *ws_client = (WebSocketClient *)transceiver;
        return ws_client.cronet_engine;
      }
    }
  }
#endif
  return nullptr;
}

- (int)usb_port {
#ifdef OS_IOS
  for (MessageTransceiver *transceiver in messageTransceivers_) {
    if ([transceiver isKindOfClass:[PeertalkClient class]]) {
      PeertalkClient *client = (PeertalkClient *)transceiver;
      return client.port;
    }
  }
#endif
  return -1;
}

- (void)setConfig:(BOOL)value forKey:(NSString *)configKey {
  @synchronized(configs_) {
    [configs_ setValue:[NSNumber numberWithBool:value] forKey:configKey];
  }
}

- (BOOL)getConfig:(NSString *)configKey withDefaultValue:(BOOL)defaultValue {
  BOOL res = defaultValue;
  @synchronized(configs_) {
    id value = [configs_ valueForKey:configKey];
    if (value) {
      res = [value boolValue];
    }
  }
  return res;
}

- (BOOL)isForbidReconnectOnClose {
  return [self getConfig:KEY_FORBID_RECONNECT_ON_CLOSE withDefaultValue:NO];
}

@end
