// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
//  tt_websocket_client.h
//  sources
//
//  Created by gaohaidong on 2018/8/23.
//

#ifndef NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_CLIENT_H_
#define NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_CLIENT_H_

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>
#include "base/power_monitor/power_observer.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/lock.h"
#include "base/timer/timer.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/websockets/websocket_channel.h"
#include "net/websockets/websocket_event_interface.h"
#include "net/websockets/websocket_frame.h"

#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
#include "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager.h"
#endif

#define ENTER DVLOG(1) << __FUNCTION__ << ": Enter.";
#define EXIT DVLOG(1) << __FUNCTION__ << ": Exit.";

namespace net {
class TTWebsocketMessageHandler;
class URLRequestContext;
class WebSocketChannel;
class WSClient;

class WSEventHandler final : public WebSocketEventInterface {
 public:
  WSEventHandler(WSClient* client) : ws_client_(client) {}
  ~WSEventHandler() override {}

  // WebSocketEventInterface implementation:
  void OnCreateURLRequest(URLRequest* request) override;
  void OnAddChannelResponse(
      std::unique_ptr<WebSocketHandshakeResponseInfo> response,
      const std::string& selected_subprotocol,
      const std::string& extensions,
      const HttpResponseInfo& info) override;
  void OnDataFrame(bool fin,
                   WebSocketEventInterface::WebSocketMessageType type,
                   base::span<const char> payload) override;
  bool HasPendingDataFrames() override;
  void OnSendDataFrameDone() override;
  void OnClosingHandshake() override;
  void OnDropChannel(bool was_clean,
                     uint16_t code,
                     const std::string& reason) override;
  void OnFailChannel(const std::string& message) override;
  void OnStartOpeningHandshake(
      std::unique_ptr<WebSocketHandshakeRequestInfo> request) override;
  void OnFinishOpeningHandshake(
      std::unique_ptr<WebSocketHandshakeResponseInfo> response) override;
  void OnSSLCertificateError(
      std::unique_ptr<SSLErrorCallbacks> ssl_error_callbacks,
      const GURL& url,
      int net_error,
      const SSLInfo& ssl_info,
      bool fatal) override;
  int OnAuthRequired(const AuthChallengeInfo& auth_info,
                     scoped_refptr<HttpResponseHeaders> response_headers,
                     const IPEndPoint& socket_address,
                     base::OnceCallback<void(const AuthCredentials*)> callback,
                     base::Optional<AuthCredentials>* credentials) override;
  void OnPing() override;
  void OnPong() override;

 private:
  WSClient* ws_client_{nullptr};

  DISALLOW_COPY_AND_ASSIGN(WSEventHandler);
};

class TTNET_IMPLEMENT_EXPORT WSClient final
    : public NetworkChangeNotifier::NetworkChangeObserver,
#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
      public TTMultiNetworkManager::StateChangeObserver,
#endif
      public base::PowerObserver,
      public ConfigManager::Observer {
 public:
  class NET_EXPORT Delegate {
   public:
    enum ConnectionState {
      ConnectUnknown = -1,
      Connecting,
      Disconnecting,
      // there were errors when trying to connect the server
      ConnectFailed,
      // the connection was connected before, but closed due to some reason
      ConnectClosed,
      Connected,
    };

    virtual void OnConnectionStateChanged(ConnectionState state,
                                          const std::string& url) = 0;
    virtual void OnConnectionError(ConnectionState state,
                                   const std::string& url,
                                   const std::string& error) = 0;
    virtual void OnMessageReceived(const std::string& message, int type) = 0;
    virtual void OnFeedbackLog(const std::string& log) = 0;
    virtual void OnTrafficChanged(const std::string& url,
                                  int64_t sent_bytes,
                                  int64_t received_bytes,
                                  bool is_heartbeat_frame) = 0;
    virtual ~Delegate() {}
  };

  enum ConnectionMode {
    // Use frontier protocol to build connection.
    CONNECTION_FRONTIER = 0,
    // Use original interface of websocket channel to build connection.
    CONNECTION_WSCHANNEL
  };

  enum Mode {
    Stop,
    Run,
    RunAndKeepAlive,
  };

  // The WsState indicates the state of frontier connection
  // when report ws_all log.
  enum WsState {
    UNKNOWN = -1,
    CONNECT_SUCCESS,
    FIRST_CONNECT_FAILED,
    RETRY_CONNECT_FAILED,
    CONNECTED_FAILED
  };

  WSClient(URLRequestContext* context,
           scoped_refptr<base::SingleThreadTaskRunner> task_runner,
           ConnectionMode mode);
  ~WSClient() override;

  void SetupMode(Mode m);

  /**
   * See: https://docs.google.com/document/d/
   1IDjl5u1lOEWHtgyHl4NY7hkhVllbKpHqohf0mpm4vms/edit#heading=h.3131syoqvo2d
   * platform
   * 0: android
   * 1: iphone
   * 4: ipad
   * 8: wap
   *
   * network:
   * 0: unknown
   * 1: wifi
   * 2: 2G
   * 3: 3G
   * 4: 4G
   */
  struct ConnectionParams {
    // must-have params
    std::vector<std::string> urls{};
    std::string appKey{""};
    int32_t appId{0};
    int64_t deviceId{0};
    int32_t fpid{0};

    // optional params
    int32_t sdkVersion{0};
    int32_t appVersion{0};
    int64_t installId{0};
    std::string sessionId{""};
    int64_t webId{0};
    int32_t platform{-1};
    int32_t timeout{0};
    int32_t requestFlag{0};
    mutable int32_t network{-1};
    std::string appToken{""};
    bool appStateReportEnabled{false};
    std::map<std::string, std::string> customParams{};
    std::map<std::string, std::string> customHeaders{};
    bool sharedConnection{true};
    ConnectionMode mode{CONNECTION_FRONTIER};
    ConnectionParams();
    ConnectionParams(const ConnectionParams& other);
    ~ConnectionParams();
  };

  struct ConnectErrorMessage {
    std::string url{""};
    int code{0};
    std::string message{""};
  };

  static void SetWSOpaque(void* ws_callback);
  typedef char* (*tt_ws_callback)(const char* const headers);

  void ConfigConnection(const ConnectionParams& params);
  bool StartConnection(bool clear_counter = true);
  bool DoDropChannel(const std::string& reason) const;
  bool StopConnection();
  void SetHasStartedConnection(bool has_started_connection) {
    has_started_connection_ = has_started_connection;
  }
  bool IsConnected() const;
  bool IsConnecting() const;
  bool AsyncSendText(const std::string& text);
  bool AsyncSendBinary(const std::string& data);
  bool AsyncSendPing();

  void AddDelegate(Delegate* delegate);
  void RemoveDelegate(Delegate* delegate);
  void SetMessageHandler(std::unique_ptr<TTWebsocketMessageHandler> handler);
  void DeleteThis() { delete this; }

  void ChangeConnectionTimeout(int timeout);

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetWebSocketStreamRequestCreationCallbackForTesting(
      WebSocketChannel::WebSocketStreamRequestCreationCallback callback) {
    callback_for_testing_ = std::move(callback);
  }

  const ConnectionParams& connection_params() const {
    return connection_params_;
  }
#endif

#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
  void OnMultiNetworkStateChanged(
      TTMultiNetworkManager::State previous_state,
      TTMultiNetworkManager::State current_state) override;

  void ForceWebsocketReconnect();
#endif

 private:
  friend class WSClientTest;
  friend class WSEventHandler;

  // called by WSEventHandler
  void OnDropChannel(bool was_clean, uint16_t code, const std::string& reason);
  void OnFailChannel(const std::string& message);
  void OnClosingHandshake();
  void OnAddChannelResponse(
      std::unique_ptr<WebSocketHandshakeResponseInfo> response,
      const HttpResponseInfo& info,
      const std::string& selected_subprotocol,
      const std::string& extensions);
  std::string DoCollectMetrics(const int flag,
                               const std::string& error = "");
  void CollectErrorMessage(int code, const std::string& message);
  std::string ConstructErrorMessage(int code, const std::string& message) const;
  void OnStartOpeningHandshake(
      std::unique_ptr<WebSocketHandshakeRequestInfo> request);
  void OnFinishOpeningHandshake(WebSocketHandshakeResponseInfo* response);
  void OnSSLCertificateError(
      std::unique_ptr<WSEventHandler::SSLErrorCallbacks> ssl_error_callbacks,
      const GURL& url,
      int net_error,
      const SSLInfo& ssl_info,
      bool fatal);
  // Handle fragmented and unfragmented messages before NotifyMessageReceived.
  // see(https://tools.ietf.org/html/rfc6455#section-5.4)
  void OnDataFrame(bool fin,
                   WebSocketEventInterface::WebSocketMessageType type,
                   base::span<const char> payload);
  void OnCreateURLRequest(URLRequest* request);
  void OnSendDataFrameDone();
  void OnPing();
  void OnPong();

  // NetworkChangeNotifier::NetworkChangeObserver implementation:
  void OnNetworkChanged(NetworkChangeNotifier::ConnectionType type) override;

  // PowerObserver delegate methods:
  void OnPowerStateChange(bool on_battery_power) override {}
  void OnSuspend() override;
  void OnResume() override;

  // ConfigManager::Observer methods:
  void OnNetConfigChanged(const NetConfig* config_ptr) override;

  void DropAndReconnectIfMatchWebSocketConfig(const NetConfig* config);

  std::string ComposeURLWithWSChannel(const ConnectionParams& parameters);
  std::string ComposeURLWithFrontier(const ConnectionParams& params);
  bool SendData(WebSocketFrameHeader::OpCode code, const std::string& data);
  bool SendPing();

  void OnPongTimeout();

  void DoReconnectIfNeeded(int32_t delay = 0, const std::string& reason = "");
  void SendMessageAckIfNeeded(const std::string& msg);

  void NotifyConnectionStateChanged(Delegate::ConnectionState state);
  void NotifyConnectionError(Delegate::ConnectionState state,
                             const std::string& error);
  void NotifyMessageReceived(const std::string& message, int type);
  void NotifyFeedbackLog(const std::string& log);
  void ResetHeartbeatTimer();
  void SendFlowControlOnNetThread(int64_t quota);
  void OnHeartbeatTimeout();
  void OnBackgroundTimeout();
  void AppStateChangeOnNetThread(bool is_background);
  void ResumeOnNetThread();
  void SuspendOnNetThread();
  void NetworkChangedOnNetThread(NetworkChangeNotifier::ConnectionType type);
  void SendWsPingLog(bool success);

  bool OnCallToAddWSSecurityFactor(const WebSocketFrameHeader::OpCode code,
                                   const std::string& data,
                                   std::string& payload);

  std::unique_ptr<WebSocketChannel> ws_channel_;
  URLRequestContext* url_request_context_{nullptr};
  // Not the owner and Only non-NULL during the connection process.
  base::WeakPtr<URLRequest> request_for_connect_;
  scoped_refptr<base::SingleThreadTaskRunner> network_task_runner_;

  Mode mode_{Mode::Stop};
  ConnectionParams connection_params_;

  int64_t current_quota_{1024 * 10};

  int last_http_statuse_code_{0};
  int last_handshake_statuse_code_{0};
  int last_ping_interval_{4 * 60};  // default 4 minutes
  bool is_heartbeat_settings_by_user_{false};
  int last_reconnect_interval_{5};

  uint32_t current_url_index_{0};
  uint32_t url_try_count_{0};
  uint32_t current_url_reconnect_count_{0};
  GURL ws_connected_url_;

  const static int32_t kReconnectCountMax;
  const static int32_t kBackoffTimeoutMaxInSeconds;  // 120 seconds
  const static int32_t kBackoffBaseTimeoutInSeconds;

  std::set<Delegate*> delegates_;

  base::RepeatingTimer heartbeat_timer_;
  base::OneShotTimer ping_timer_;
  base::OneShotTimer background_timer_;

  enum AppState {
    FOREGROUND,
    BACKGROUND,
    BACKGROUND_INACTIVE,
  };

  AppState app_state_{FOREGROUND};

  WsState ws_state_{UNKNOWN};

  struct HeartBeatMetaInfo {
    int16_t seqId{0};

    int32_t lastSuccessHeartBeatInterval{4 * 60};
    int32_t lastFailedHeartBeatInterval{0};
    int32_t nextTryInterval{0};

    int32_t finalHeartBeatInterval{0};
    int32_t successHeartBeatCount{0};
    int32_t failHeartBeatCount{0};
  };

  HeartBeatMetaInfo heartBeatMetaInfo_;
  void DoHeartbeatInBackgroundInactiveState();
  void ResetHeartBeatMetaInfo();

  struct WebSocketMetrics {
    std::string failReason{""};
    int failCode{0};
    int connectRetryCount{0};
    int64_t connectionAliveTime{0};
    int64_t totalConnectionAliveTime{0};
    int64_t buildConnectionTime{0};
    int64_t lastConnectTime{0};

    base::TimeTicks appStartTime;
    base::TimeTicks lastConnectStartTime;
    base::TimeTicks connectStartTime;
    base::TimeTicks connectSuccessTime;
    // True if using QUIC to build websocket connection.
    bool didUseQuic{false};

    // Related info for latest ping frame sent on frontier connection.
    // Time interval between sending ping and receiving pong.
    int64_t rtt{-1};
    // The start time of latest ping frame sent.
    base::TimeTicks lastPingStartTime;

    WebSocketMetrics();
    WebSocketMetrics(const WebSocketMetrics& other);
    ~WebSocketMetrics();
  };

  WebSocketMetrics webSocketMetrics_;
  // Get request_log_ from DoCollectMetrics() and use it in
  // ConstructErrorMessage() since request_for_connect_ is always lost,
  // and we need some infomation from connected request.
  std::string request_log_;
  // How many times the frontier connection has been disconnected when App
  // alive.
  int disconnect_times_{0};
  // True indicates that App is in the process of establishing a connection.
  bool is_connecting_{false};
  std::deque<ConnectErrorMessage> connect_error_message_;
  bool has_started_connection_{true};
  // True to indicate that no delay for reconnecting.
  bool ttnet_delay_reconnect_{true};
  // Receiving both fragmented and unfragmented messages from server.
  // We need to combine fragmented messages before notify.
  std::string message_received_;
  // Record message type when received fragmented messages from server.
  WSEventHandler::WebSocketMessageType latest_fragment_message_type_{
      WebSocketFrameHeader::kOpCodeBinary};
  std::unique_ptr<TTWebsocketMessageHandler> message_handler_{nullptr};
  scoped_refptr<HttpResponseHeaders> response_headers_;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  WebSocketChannel::WebSocketStreamRequestCreationCallback
      callback_for_testing_;
#endif
  base::Lock delegate_callback_lock_;
  base::Time wsclient_initial_time_;
  int64_t ws_callback_max_cost_{-1};
  int64_t payload_sign_max_cost_{-1};
  base::WeakPtrFactory<WSClient> weak_factory_;
  DISALLOW_COPY_AND_ASSIGN(WSClient);
};

}  // namespace net

#endif /* NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_CLIENT_H_ */
