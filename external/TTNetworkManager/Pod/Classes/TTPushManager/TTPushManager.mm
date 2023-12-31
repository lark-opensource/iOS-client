//
//  TTPushManager.m
//  TTPushManager
//
//  Created by gaohaidong on 4/25/16.
//  Copyright © 2016 bytedance. All rights reserved.
//

#import "TTPushManager.h"

#import "components/cronet/ios/cronet_environment.h"
#import "net/tt_net/websocket/tt_websocket_client.h"
#import "net/tt_net/websocket/tt_websocket_manager.h"

#import <UIKit/UIKit.h>

#import <sstream> //for ostringstream
#import <vector>
#import <atomic>

#import "TTPushMessageDispatcher.h"
#import "TTPushMessageBaseObject.h"
#import "TTPushMessageReceiver.hpp"
#import "TTNetworkManager.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerLog.h"

//onPushMessageReceived related
NSString * const kTTPushManagerUnknownPushMessage = @"kTTPushManagerUnknownPushMessage";
NSString * const kTTPushManagerUnknownPushMessageUserInfoKey = @"kTTPushManagerUnknownPushMessageUserInfoKey";

NSString * const kTTPushManagerOnReceivingMessage = @"kTTPushManagerOnReceivingMessage";
NSString * const kTTPushManagerOnReceivingMessageUserInfoKey = @"kTTPushManagerOnReceivingMessageUserInfoKey";

NSString * const kTTPushManagerOnReceivingWSChannelMessage = @"kTTPushManagerOnReceivingWSChannelMessage";
NSString * const kTTPushManagerOnReceivingWSChannelMessageUserInfoKey = @"kTTPushManagerOnReceivingWSChannelMessageUserInfoKey";

//onFeedbackLog related
NSString * const kTTPushManagerOnFeedbackLog= @"kTTPushManagerOnFeedbackLog";
NSString * const kTTPushManagerOnFeedbackLogUserInfoKey = @"kTTPushManagerOnFeedbackLogUserInfoKey";

//onConnectionErrorWithState related
NSString * const kTTPushManagerConnectionError = @"kTTPushManagerConnectionError";
NSString * const kTTPushManagerConnectionErrorUserInfoKeyURL = @"kTTPushManagerConnectionErrorUserInfoKeyURL";
NSString * const kTTPushManagerConnectionErrorUserInfoKeyConnectionState = @"kTTPushManagerConnectionErrorUserInfoKeyConnectionState";
NSString * const kTTPushManagerConnectionErrorUserInfoKeySpecificError = @"kTTPushManagerConnectionErrorUserInfoKeySpecificError";

//onConnectionStateChanged related
NSString * const kTTPushManagerConnectionStateChanged = @"kTTPushManagerConnectionStateChanged";
NSString * const kTTPushManagerConnectionStateChangedInfoKeyConnectionState = @"kTTPushManagerConnectionStateChangedInfoKeyConnectionState";
NSString * const kTTPushManagerConnectionStateChangedInfoKeyURL = @"kTTPushManagerConnectionStateChangedInfoKeyURL";

//onTrafficChanged related
NSString * const kTTPushManagerOnTrafficChanged= @"kTTPushManagerOnTrafficChanged";
NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyURL = @"kTTPushManagerOnTrafficChangedUserInfoKeyURL";
NSString * const kTTPushManagerOnTrafficChangedUserInfoKeySentBytes = @"kTTPushManagerOnTrafficChangedUserInfoKeySentBytes";
NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes = @"kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes";
NSString * const kTTPushManagerOnTrafficChangedUserInfoKeyIsHeartBeatFrame = @"kTTPushManagerOnTrafficChangedUserInfoKeyIsHeartBeatFrame";

NSString * const kAppKey = @"e92afe409d29ce57cd31b483c25981de";


using namespace net;
using namespace std;

@protocol Push <NSObject>

- (void)onPushMessageReceived:(const std::string &)message type:(int)type;
- (void)onFeedbackLog:(NSString *)log;
- (void)onConnectionErrorWithState:(WSClient::Delegate::ConnectionState)state url:(NSString *)url error:(NSString *)error;
- (void)onConnectionStateChanged:(WSClient::Delegate::ConnectionState)state url:(NSString *)url;
- (void)onTrafficChanged:(NSString *)url sentBytes:(int64_t)sentBytes receivedBytes:(int64_t)receivedBytes isHeartbeatFrame:(bool)isHeartbeatFrame;

@end


class PushDelegate : public WSClient::Delegate {
public:
    PushDelegate(__weak id<Push> observer, bool shared, TTPushManagerConnectionMode mode): observer_(observer), serial_queue_(dispatch_queue_create("PushDelegate_serial_queue", DISPATCH_QUEUE_SERIAL)) {
      NewConnection(shared, mode);
    }
    ~PushDelegate() override {
//      LOGE(@"~PushDelegate");
    }

public:
  void NewConnection(bool shared, TTPushManagerConnectionMode mode) {
      dispatch_async(serial_queue_, ^{
        DoNewConnection(shared, mode);
      });
  }
  void StartConnection() {
      dispatch_async(serial_queue_, ^{
        DoStartConnection();
      });
  }
  void StopConnection() {
      dispatch_async(serial_queue_, ^{
        DoStopConnection();
      });
  }
  void ConfigConnection(const WSClient::ConnectionParams &params) {
      WSClient::ConnectionParams clone = params;
      dispatch_async(serial_queue_, ^{
        DoConfigConnection(clone);
      });
  }
  void AsyncSendText(const std::string &data) {
      std::string clone = data;
      dispatch_async(serial_queue_, ^{
        DoAsyncSendText(clone);
      });
  }
  void AsyncSendBinary(const std::string &data) {
      std::string clone = data;
      dispatch_async(serial_queue_, ^{
        DoAsyncSendBinary(clone);
      });
  }

  void AsyncSendPing() {
      dispatch_async(serial_queue_, ^{
        DoAsyncSendPing();
      });
  }

  void Destroy() {
      dispatch_async(serial_queue_, ^{
        DoDestroy();
      });
  }

  bool IsConnected() const {
    return is_connected_;
  }

private:
  void PostTaskToNetworkThread(const base::Location& from_here, const base::Closure& task) {
    if (![[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
      return;
    }
    cronet::CronetEnvironment* engine = (cronet::CronetEnvironment*)[(TTNetworkManagerChromium *)[TTNetworkManager shareInstance] getEngine];
    if (!engine || !engine->GetURLRequestContextGetter() || !engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()) {
      LOGE(@"engine in bad state");
      return;
    }
    engine->GetURLRequestContextGetter()->GetNetworkTaskRunner()->PostTask(from_here,task);
  }
    
  void DoNewConnection(bool shared, TTPushManagerConnectionMode mode) {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::NewConnectionOnNetworkThread,base::Unretained(this), shared, mode));
  }
  void DoStartConnection() {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::StartConnectionOnNetworkThread,base::Unretained(this)));
  }
  void DoStopConnection() {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::StopConnectionOnNetworkThread,base::Unretained(this)));
  }
  void DoConfigConnection(const WSClient::ConnectionParams &params) {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::ConfigConnectionOnNetworkThread, base::Unretained(this), params));
  }
  void DoAsyncSendBinary(const std::string &data) {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::AsyncSendBinaryOnNetworkThread, base::Unretained(this), data));
  }
  void DoAsyncSendText(const std::string &data) {
    if (!CheckTTNetIsInitialized()) {
        return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::AsyncSendTextOnNetworkThread, base::Unretained(this), data));
  }
  void DoAsyncSendPing() {
    if (!CheckTTNetIsInitialized()) {
        return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::AsyncSendPingOnNetworkThread, base::Unretained(this)));
  }
  void DoDestroy() {
    if (!CheckTTNetIsInitialized()) {
      return;
    }
    PostTaskToNetworkThread(FROM_HERE, base::Bind(&PushDelegate::DestroyOnNetworkThread, base::Unretained(this)));
  }
    
private:
  void NewConnectionOnNetworkThread(bool shared, TTPushManagerConnectionMode mode) {
    WSClient::ConnectionMode connection_mode = WSClient::CONNECTION_FRONTIER;
    switch (mode) {
      case TTPushManagerConnectionMode_Frontier:
        connection_mode = WSClient::CONNECTION_FRONTIER;
        break;
      case TTPushManagerConnectionMode_WSChannel:
        connection_mode = WSClient::CONNECTION_WSCHANNEL;
        break;
      default:
        assert(false);
        break;
    }

    if (shared) {
      ws_client_ = net::WSManager::GetInstance()->SharedConnection(connection_mode);
    } else {
      owned_ws_client_ = net::WSManager::GetInstance()->NewConnection(connection_mode);
      ws_client_ = owned_ws_client_.get();
    }

    ws_client_->SetupMode(WSClient::Mode::Run);
    ws_client_->AddDelegate(this);
  }

  void StartConnectionOnNetworkThread() {
    if (ws_client_) {
      ws_client_->SetHasStartedConnection(true);
      ws_client_->StartConnection();
    }
  }
  void StopConnectionOnNetworkThread() {
    if (ws_client_) {
      ws_client_->SetHasStartedConnection(false);
      ws_client_->StopConnection();
    }
  }
  void ConfigConnectionOnNetworkThread(const WSClient::ConnectionParams &params) {
    if (ws_client_) {
      ws_client_->ConfigConnection(params);
    }
  }
  void AsyncSendBinaryOnNetworkThread(const std::string &data) {
    if (ws_client_) {
      ws_client_->AsyncSendBinary(data);
    }
  }
  void AsyncSendTextOnNetworkThread(const std::string &data) {
    if (ws_client_) {
      ws_client_->AsyncSendText(data);
    }
  }
  void AsyncSendPingOnNetworkThread() {
    if (ws_client_) {
        ws_client_->AsyncSendPing();
    }
  }
  void DestroyOnNetworkThread() {
    if (ws_client_) {
      ws_client_->RemoveDelegate(this);
    }
    if (owned_ws_client_) {
      owned_ws_client_.reset();
    }
    delete this;
  }

  bool CheckTTNetIsInitialized() {
    if ([[TTNetworkManager shareInstance] isKindOfClass:[TTNetworkManagerChromium class]]) {
      TTNetworkManagerChromium *ttnetworkManager = (TTNetworkManagerChromium *)[TTNetworkManager shareInstance];
      if ([ttnetworkManager ensureEngineStarted]) {
        LOGE(@"TTNet is not initalized");
        return false;
      }
      return true;
    } else {
      LOGE(@"TTPushMananger is ONLY supported when cronet is open");
      return false;
    }
  }

private:
  // WSClient::Delegate implementation
  void OnConnectionStateChanged(ConnectionState state, const std::string &url) override {
    if (observer_) {
      [observer_ onConnectionStateChanged:state url:@(url.c_str())];
    }

    if (state == Connected) {
      is_connected_ = true;
    } else {
      is_connected_ = false;
    }
  }

  void OnConnectionError(ConnectionState state, const std::string &url, const std::string &error) override {
    NSString *errorMsg = @(error.c_str());
    NSString *urlString = @(url.c_str());
    if (observer_) {
      [observer_ onConnectionErrorWithState:state url:urlString error:errorMsg];
    }
  }

  void OnMessageReceived(const std::string &message, int type) override {
    if (observer_) {
      [observer_ onPushMessageReceived:message type:type];
    }
  }

  void OnFeedbackLog(const std::string &log) override {
    NSString *logString = @(log.c_str());
    if (observer_) {
      [observer_ onFeedbackLog:logString];
    }
  }
 
  void OnTrafficChanged(const std::string &url,
                        int64_t sent_bytes,
                        int64_t received_bytes,
                        bool is_heartbeat_frame) override {
    NSString *urlString = @(url.c_str());
    if (observer_) {
        [observer_ onTrafficChanged:urlString sentBytes:sent_bytes receivedBytes:received_bytes isHeartbeatFrame:is_heartbeat_frame];
    }
  }

private:
  __weak id<Push> observer_;

  WSClient* ws_client_{nullptr};
  unique_ptr<WSClient> owned_ws_client_;
  std::atomic_bool is_connected_{false};
  
  dispatch_queue_t serial_queue_;
};

@implementation TTPushConfig
@end

@interface TTPushManager () <Push> {
  PushDelegate* pushDelegate;
  unique_ptr<WSClient::ConnectionParams> parameters;
}

@property (atomic, strong) TTPushMessageDispatcher *msgDispatcher;
@property (nonatomic, strong) dispatch_queue_t dispatch_queue;

@property (atomic, assign) BOOL isForeground;
@property (atomic, assign) BOOL isBroadcasting;
@property (atomic, assign) BOOL isSecondInstance;
@property (atomic, assign) BOOL shared;
@property (atomic, assign) TTPushManagerConnectionMode connection_mode;


@end

@implementation TTPushManager

#pragma mark - Implement life cycle

+ (instancetype)sharedManager {
    static TTPushManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedManager = [[self alloc] init:YES ConnectionMode:TTPushManagerConnectionMode_Frontier];
    });
    return sharedManager;
}

+ (instancetype)anotherSharedManager {
    static TTPushManager *anotherSharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        anotherSharedManager = [[self alloc] init:NO ConnectionMode:TTPushManagerConnectionMode_Frontier];
    });
    return anotherSharedManager;
}

- (instancetype)init:(BOOL)shared ConnectionMode:(TTPushManagerConnectionMode) mode {
  self = [super init];
  if (self) {
    // Shared should set to false for wschannel mode.
    if (mode == TTPushManagerConnectionMode_WSChannel) {
        shared = NO;
    }
    self.connection_mode = mode;
    self.shared = shared;
    self.dispatch_queue = dispatch_queue_create("lcs_dispatch_queue", DISPATCH_QUEUE_SERIAL);
    pushDelegate = new PushDelegate(self, shared, mode);

    parameters = std::unique_ptr<WSClient::ConnectionParams>(new WSClient::ConnectionParams());

    parameters->sdkVersion = 3;

//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(handleEnteredBackground)
//                                                 name: UIApplicationDidEnterBackgroundNotification
//                                               object: nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver: self
//                                             selector: @selector(handleEnteredForeground)
//                                                 name: UIApplicationDidBecomeActiveNotification
//                                               object: nil];

    self.msgDispatcher = [[TTPushMessageDispatcher alloc] init];

    self.isForeground = YES;

  }
  return self;
}

- (void)dealloc {
  //LOGE(@"TTPushManager dealloc");
//  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (pushDelegate) {
    pushDelegate->Destroy();
  }
  parameters = nullptr;
}

#pragma mark - Implement notification observer

//- (void)handleEnteredBackground {
//    self.isForeground = NO;
////  if ([self checkIfWellConstructed_])
////    pushManager->appStateChanged(PushManager::AppState::WillEnterBackground);
//}
//
//- (void)handleEnteredForeground {
//    self.isForeground = YES;
////  if ([self checkIfWellConstructed_])
////    pushManager->appStateChanged(PushManager::AppState::DidEnterForeground);
//}

#pragma mark - Implement Push protocol

- (void)onPushMessageReceived:(const std::string &)obj type:(int)type {
    ENTER;
    // move to background thread to do the PB parsing, do not in main thread.
    __weak typeof(self) weakSelf = self;
    std::string copy = obj;
    dispatch_async(self.dispatch_queue, ^(void) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.connection_mode == TTPushManagerConnectionMode_Frontier) {
            if (strongSelf.delegate && !strongSelf.shared && [strongSelf.delegate respondsToSelector:@selector(onFrontierMessageReceived:message:)]) {
                [strongSelf.msgDispatcher delegateMessage:copy pushManager:strongSelf];
                return;
            }
            [strongSelf.msgDispatcher dispatchMessage:copy];
        } else if (strongSelf.connection_mode == TTPushManagerConnectionMode_WSChannel) {
            TTPushManagerMessageType messageType = [strongSelf.class convertMessageType_:type];
            // Only handle text and binary message.
            id msg;
            if (messageType == TTPushManagerMessageType_Text) {
                msg = @(copy.c_str());
            } else if (messageType == TTPushManagerMessageType_Binary) {
                msg = [[NSData alloc] initWithBytes: copy.data() length: copy.length()];
            } else {
                return;
            }
        
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(onPushMessageReceived:message:type:)]) {
                [strongSelf.delegate onPushMessageReceived:strongSelf message:msg type:messageType];
                return;
            }

            NSDictionary *userInfo = @{kTTPushManagerOnReceivingWSChannelMessageUserInfoKey : msg};
            // NOTE! NSNotification is not in MAIN thread!
            [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerOnReceivingWSChannelMessage object:nil userInfo:userInfo];
        }
    });
}

- (void)onFeedbackLog:(NSString *)log {
  ENTER;
  dispatch_async(self.dispatch_queue, ^(void) {
    if (self.delegate && !self.shared && [self.delegate respondsToSelector:@selector(onFeedbackLog:feedbacklog:)]) {
        [self.delegate onFeedbackLog:self feedbacklog:log];
        return;
    }
    NSDictionary *userInfo = @{kTTPushManagerOnFeedbackLogUserInfoKey : log};
    // NOTE! NSNotification is not in MAIN thread!
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerOnFeedbackLog object:nil userInfo:userInfo];
  });
}

- (void)onConnectionErrorWithState:( WSClient::Delegate::ConnectionState)state url:(NSString *)url error:(NSString *)error {
    ENTER;
    dispatch_async(self.dispatch_queue, ^(void) {
        TTPushManagerConnectionState connectionState = [self.class convertConnectionState_:state];
        if (self.delegate && !self.shared && [self.delegate respondsToSelector:@selector(onConnectionErrorWithState:connectionState:url:error:)]) {
            [self.delegate  onConnectionErrorWithState:self connectionState:connectionState url:url error:error];
            return;
        }
        
        NSDictionary *userInfo = @{kTTPushManagerConnectionErrorUserInfoKeyURL : url ?: @"",kTTPushManagerConnectionErrorUserInfoKeyConnectionState : @(connectionState),kTTPushManagerConnectionErrorUserInfoKeySpecificError : error ?: @""};
        
        // NOTE! NSNotification is not in MAIN thread!
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerConnectionError object:nil userInfo:userInfo];
    });
}

- (void)onConnectionStateChanged:( WSClient::Delegate::ConnectionState)state url:(NSString *)url {
    ENTER;
    dispatch_async(self.dispatch_queue, ^(void) {
        TTPushManagerConnectionState connectionState = [self.class convertConnectionState_:state];
        if (self.delegate && !self.shared && [self.delegate respondsToSelector:@selector(onConnectionStateChanged:connectionState:url:)]) {
            [self.delegate onConnectionStateChanged:self connectionState:connectionState url:url];
            return;
        }
        
        NSDictionary *userInfo = @{kTTPushManagerConnectionStateChangedInfoKeyConnectionState : @(connectionState), kTTPushManagerConnectionStateChangedInfoKeyURL : url ?: @""};
        
        // NOTE! NSNotification is not in MAIN thread!
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerConnectionStateChanged object:nil userInfo:userInfo];
    });
}

-(void)onTrafficChanged:(NSString *)url sentBytes:(int64_t)sentBytes receivedBytes:(int64_t)receivedBytes isHeartbeatFrame:(bool)isHeartbeatFrame {
  ENTER;
  dispatch_async(self.dispatch_queue, ^(void) {
      NSDictionary *userInfo = @{kTTPushManagerOnTrafficChangedUserInfoKeyURL : url, kTTPushManagerOnTrafficChangedUserInfoKeySentBytes : @(sentBytes), kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes : @(receivedBytes), kTTPushManagerOnTrafficChangedUserInfoKeyIsHeartBeatFrame : @(isHeartbeatFrame)};
           
      // NOTE! NSNotification is not in MAIN thread!
      [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerOnTrafficChanged object:nil userInfo:userInfo];
  });
}

#pragma mark - Public functions
- (void)configConnection:(TTPushConfig *)config {
    switch (self.connection_mode) {
        case TTPushManagerConnectionMode_Frontier:
            NSAssert(config.urls.count > 0 && config.appId != 0
                     && config.appKey.length > 0 && config.deviceId != 0
                     && config.fpid != 0 && config.appVersion > 0, @"Must set these parameters");
            parameters->appKey = CPPSTR(config.appKey);
            parameters->deviceId = config.deviceId;
            parameters->appId = config.appId;
            parameters->fpid = config.fpid;
            parameters->appVersion = config.appVersion;
            parameters->sessionId = CPPSTR(config.sessionId);
            parameters->webId = config.webId;
            parameters->network = config.network;
            parameters->platform = config.platform;
            parameters->installId = config.installId;
            parameters->mode = WSClient::CONNECTION_FRONTIER;
            parameters->appStateReportEnabled = config.enableAppStateReport;
            break;
        case TTPushManagerConnectionMode_WSChannel:
            NSAssert(config.urls.count > 0, @"Must set these parameters");
            parameters->mode = WSClient::CONNECTION_WSCHANNEL;
            break;
        default:
            NSAssert(false, @"Unsupported connection mode!");
            return;
    }
    vector<string> urlVector;
    for (NSString *url in config.urls) {
        urlVector.push_back(CPPSTR(url));
    }

    parameters->urls = urlVector;
    parameters->sdkVersion = 3;
    if (config.customParams) {
        map<string, string> customParamsMap;
        for (NSString *key in config.customParams.allKeys) {
            customParamsMap[CPPSTR(key)] = CPPSTR(config.customParams[key]);
        }
        parameters->customParams = customParamsMap;
    }
    if (config.customHeaders) {
        map<string, string> customHeadersMap;
        for (NSString *key in config.customHeaders.allKeys) {
            customHeadersMap[CPPSTR(key)] = CPPSTR(config.customHeaders[key]);
        }
        parameters->customHeaders = customHeadersMap;
    }
    pushDelegate->ConfigConnection(*parameters);
}

- (void)asyncStartConnection {
  pushDelegate->StartConnection();
}

- (void)asyncStopConnection {
  pushDelegate->StopConnection();
}

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
                   fpid:(/*nonnull*/ int32_t)fpid
                 appKey:(/*nonnull*/ NSString *)appKey
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network
           customParams:(/*nullable*/ NSDictionary<NSString *, NSString *> *)customParams {
    NSAssert(urls.count > 0 && appId != 0 && appKey.length > 0 && deviceId != 0 && fpid != 0 && appVersion > 0, @"Must set these parameters");

    vector<string> urlVector;
    for (NSString *url in urls) {
        urlVector.push_back(CPPSTR(url));
    }
    
    parameters->urls = urlVector;
    parameters->appKey = CPPSTR(appKey);
    parameters->deviceId = deviceId;
    parameters->appId = appId;
    parameters->fpid = fpid;
    
    parameters->appVersion = appVersion;
    parameters->sdkVersion = 3;
    
    parameters->sessionId = CPPSTR(sessionId);
    parameters->webId = webId;
    parameters->network = network;
    parameters->platform = platform;
    parameters->installId = installId;
    
    if (customParams) {
        map<string, string> customParamsMap;
        for (NSString *key in customParams.allKeys) {
            customParamsMap[CPPSTR(key)] = CPPSTR(customParams[key]);
        }
        parameters->customParams = customParamsMap;
    }
    pushDelegate->ConfigConnection(*parameters);
    pushDelegate->StartConnection();
}

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
                   fpid:(/*nonnull*/ int32_t)fpid
                 appKey:(/*nonnull*/ NSString *)appKey
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network {
    [self startConnection:urls
                    appId:appId
                     fpid:fpid
                   appKey:appKey
                 deviceId:deviceId
               appVersion:appVersion
               sdkVersion:sdkVersion
                installId:installId
                sessionId:sessionId
                    webId:webId
                 platform:platform
                  network:network
             customParams:nil];
}

- (void)startConnection:(/*nonnull*/ NSArray *)urls
                  appId:(/*nonnull*/ int32_t)appId
               deviceId:(/*nonnull*/ int64_t)deviceId
             appVersion:(/*nonnull*/ int32_t)appVersion
             sdkVersion:(/*nonnull*/ int32_t)sdkVersion
              installId:(/*nullable*/ int64_t)installId
              sessionId:(/*nullable*/ NSString *)sessionId
                  webId:(/*nullable*/ int64_t)webId
               platform:(/*nullable*/ int32_t)platform
                network:(/*nullable*/ int32_t)network {
    
    [self startConnection:urls
                    appId:appId
                     fpid:1
                   appKey:kAppKey
                 deviceId:deviceId
               appVersion:appVersion
               sdkVersion:sdkVersion
                installId:installId
                sessionId:sessionId
                    webId:webId
                 platform:platform
                  network:network];
}

- (void)stopConnection {
  pushDelegate->StopConnection();
}

- (BOOL)isConnected {
  return pushDelegate->IsConnected();
}

- (BOOL)asyncSendTextMessage:(/*nonnull*/ NSString *)message {
    if (message.length > 0) {
        std::string data = CPPSTR(message);
        pushDelegate->AsyncSendText(data);
        return YES;
    } else {
        NSAssert(false, @"Message must not be nil or empty.");
        return NO;
    }
}

- (BOOL)asyncSendBinaryMessage:(/*nonnull*/ NSData *)message {
    if (message.length > 0) {
      std::string data((char*)message.bytes, message.length);
      pushDelegate->AsyncSendBinary(data);
      return YES;
    } else {
        NSAssert(false, @"Message must not be nil or empty.");
        return NO;
    }
}

- (void)asyncSendPing {
  pushDelegate->AsyncSendPing();
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (BOOL)asyncSendPushMessage:(/*nonnull*/ PushMessageBaseObject *)message {
    NSData *data = [TTPushMessageDispatcher serializeObject:message];
    if (data) {
        return [self asyncSendBinaryMessage:data];
    } else {
        NSAssert(false, @"Message serialization to PB failed.");
        return NO;
    }
}
#pragma GCC diagnostic pop

- (void)onNetworkStateChanged:(TTPushManagerNetworkState)networkState {
    ENTER;
//    PushManager::ReachabilityState state{PushManager::ReachabilityState::ReachableUnKnown};
//    if (networkState == TTPushManagerNetworkState_NotReachable) {
//        state = PushManager::ReachabilityState::NotReachable;
//    } else if (networkState == TTPushManagerNetworkState_ReachableViaWiFi) {
//        state = PushManager::ReachabilityState::ReachableViaWiFi;
//    } else if (networkState == TTPushManagerNetworkState_ReachableViaWWAN) {
//        state = PushManager::ReachabilityState::ReachableViaWWAN;
//    }
//
//    pushManager->networkStateChanged(state);
}

- (void)enableDebugLog:(BOOL)enabled {
  [[TTNetworkManager shareInstance] enableVerboseLog];
}

- (void)setCustomizedMessageReceiver:(TTPushMessageReceiver *)messageReceiver {
    NSParameterAssert(messageReceiver != nil);
    [self.msgDispatcher setCustomizedMessageReceiver:messageReceiver];
}

- (void)setBroadcastingMessage:(BOOL)value {
    self.isBroadcasting = value;
    if (self.msgDispatcher) {
        [self.msgDispatcher setBroadcastingMessage:value];
    }
}

#pragma mark - Private functions

+ (TTPushManagerConnectionState)convertConnectionState_:(WSClient::Delegate::ConnectionState)cppState {
    TTPushManagerConnectionState ret = TTPushManagerConnectionState_ConnectUnknown;
    switch (cppState) {
        case WSClient::Delegate::ConnectionState::ConnectUnknown:
            ret = TTPushManagerConnectionState_ConnectUnknown;
            break;

        case WSClient::Delegate::ConnectionState::Connecting:
            ret = TTPushManagerConnectionState_Connecting;
            break;

        case WSClient::Delegate::ConnectionState::ConnectFailed:
            ret = TTPushManagerConnectionState_ConnectFailed;
            break;

        case WSClient::Delegate::ConnectionState::ConnectClosed:
            ret = TTPushManagerConnectionState_ConnectClosed;
            break;

        case WSClient::Delegate::ConnectionState::Connected:
            ret = TTPushManagerConnectionState_Connected;
            break;

        case WSClient::Delegate::ConnectionState::Disconnecting:
            ret = TTPushManagerConnectionState_Disconnecting;
            break;

        default:
            NSAssert(false, @"Unsupported type!");
            break;
    }
    return ret;
}

+ (TTPushManagerMessageType)convertMessageType_:(int)type {
    TTPushManagerMessageType ret = TTPushManagerMessageType_Unknown;
    switch (type) {
        case 1:
            ret = TTPushManagerMessageType_Text;
            break;
            
        case 2:
            ret = TTPushManagerMessageType_Binary;
            break;
            
        default:
            NSAssert(false, @"Unsupported type!");
            break;
    }
    return ret;
}

@end
