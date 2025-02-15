// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_WEBSOCKETS_WEBSOCKET_CHANNEL_H_
#define NET_WEBSOCKETS_WEBSOCKET_CHANNEL_H_

#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include "base/callback.h"
#include "base/compiler_specific.h"  // for WARN_UNUSED_RESULT
#include "base/containers/queue.h"
#include "base/macros.h"
#include "base/memory/scoped_refptr.h"
#include "base/time/time.h"
#include "base/timer/timer.h"
#include "net/base/net_export.h"
#include "net/websockets/websocket_event_interface.h"
#include "net/websockets/websocket_frame.h"
#include "net/websockets/websocket_stream.h"
#include "url/gurl.h"

#if !BUILDFLAG(TTNET_IMPLEMENT) || defined(BASE_I18N_IMPLEMENTATION)
#include "base/i18n/streaming_utf8_validator.h"
#endif

namespace url {
class Origin;
}  // namespace url

namespace net {

class HttpRequestHeaders;
class IOBuffer;
class IPEndPoint;
class NetLogWithSource;
class IsolationInfo;
class SiteForCookies;
class URLRequest;
class URLRequestContext;
struct WebSocketHandshakeRequestInfo;
struct WebSocketHandshakeResponseInfo;
struct NetworkTrafficAnnotationTag;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
class Throttle;
#endif

// Transport-independent implementation of WebSockets. Implements protocol
// semantics that do not depend on the underlying transport. Provides the
// interface to the content layer. Some WebSocket concepts are used here without
// definition; please see the RFC at http://tools.ietf.org/html/rfc6455 for
// clarification.
class NET_EXPORT WebSocketChannel {
 public:
  // The type of a WebSocketStream creator callback. Must match the signature of
  // WebSocketStream::CreateAndConnectStream().
  typedef base::OnceCallback<std::unique_ptr<WebSocketStreamRequest>(
      const GURL&,
      const std::vector<std::string>&,
      const url::Origin&,
      const SiteForCookies&,
      const IsolationInfo&,
      const HttpRequestHeaders&,
      URLRequestContext*,
      const NetLogWithSource&,
      NetworkTrafficAnnotationTag,
      std::unique_ptr<WebSocketStream::ConnectDelegate>)>
      WebSocketStreamRequestCreationCallback;

  // Methods which return a value of type ChannelState may delete |this|. If the
  // return value is CHANNEL_DELETED, then the caller must return without making
  // any further access to member variables or methods.
  enum ChannelState { CHANNEL_ALIVE, CHANNEL_DELETED };

  // Creates a new WebSocketChannel in an idle state.
  // SendAddChannelRequest() must be called immediately afterwards to start the
  // connection process.
  WebSocketChannel(std::unique_ptr<WebSocketEventInterface> event_interface,
                   URLRequestContext* url_request_context);
  virtual ~WebSocketChannel();

  // Starts the connection process.
  void SendAddChannelRequest(
      const GURL& socket_url,
      const std::vector<std::string>& requested_protocols,
      const url::Origin& origin,
      const SiteForCookies& site_for_cookies,
      const IsolationInfo& isolation_info,
      const HttpRequestHeaders& additional_headers,
      NetworkTrafficAnnotationTag traffic_annotation);

  // Sends a data frame to the remote side. It is the responsibility of the
  // caller to ensure that they have sufficient send quota to send this data,
  // otherwise the connection will be closed without sending. |fin| indicates
  // the last frame in a message, equivalent to "FIN" as specified in section
  // 5.2 of RFC6455. |buffer->data()| is the "Payload Data". If |op_code| is
  // kOpCodeText, or it is kOpCodeContinuation and the type the message is
  // Text, then |buffer->data()| must be a chunk of a valid UTF-8 message,
  // however there is no requirement for |buffer->data()| to be split on
  // character boundaries. Calling SendFrame may result in synchronous calls to
  // |event_interface_| which may result in this object being deleted. In that
  // case, the return value will be CHANNEL_DELETED.
  ChannelState SendFrame(bool fin,
                         WebSocketFrameHeader::OpCode op_code,
                         scoped_refptr<IOBuffer> buffer,
                         size_t buffer_size) WARN_UNUSED_RESULT;

  // Calls WebSocketStream::ReadFrames() with the appropriate arguments. Stops
  // calling ReadFrames if no writable buffer in dataframe or WebSocketStream
  // starts async read.
  ChannelState ReadFrames() WARN_UNUSED_RESULT;

  // Starts the closing handshake for a client-initiated shutdown of the
  // connection. There is no API to close the connection without a closing
  // handshake, but destroying the WebSocketChannel object while connected will
  // effectively do that. |code| must be in the range 1000-4999. |reason| should
  // be a valid UTF-8 string or empty.
  //
  // Calling this function may result in synchronous calls to |event_interface_|
  // which may result in this object being deleted. In that case, the return
  // value will be CHANNEL_DELETED.
  ChannelState StartClosingHandshake(uint16_t code, const std::string& reason)
      WARN_UNUSED_RESULT;

  // Starts the connection process, using a specified creator callback rather
  // than the default. This is exposed for testing.
  void SendAddChannelRequestForTesting(
      const GURL& socket_url,
      const std::vector<std::string>& requested_protocols,
      const url::Origin& origin,
      const SiteForCookies& site_for_cookies,
      const IsolationInfo& isolation_info,
      const HttpRequestHeaders& additional_headers,
      NetworkTrafficAnnotationTag traffic_annotation,
      WebSocketStreamRequestCreationCallback callback);

  // The default timout for the closing handshake is a sensible value (see
  // kClosingHandshakeTimeoutSeconds in websocket_channel.cc). However, we can
  // set it to a very small value for testing purposes.
  void SetClosingHandshakeTimeoutForTesting(base::TimeDelta delay);

  // The default timout for the underlying connection close is a sensible value
  // (see kUnderlyingConnectionCloseTimeoutSeconds in websocket_channel.cc).
  // However, we can set it to a very small value for testing purposes.
  void SetUnderlyingConnectionCloseTimeoutForTesting(base::TimeDelta delay);

  // Called when the stream starts the WebSocket Opening Handshake.
  // This method is public for testing.
  void OnStartOpeningHandshake(
      std::unique_ptr<WebSocketHandshakeRequestInfo> request);

#if BUILDFLAG(TTNET_IMPLEMENT)
  ChannelState AddReceiveFlowControlQuota(int64_t quota) WARN_UNUSED_RESULT;

  GURL url() const { return socket_url_; }
  void SetConnectionTimeout(int timeout) { connection_timeout_ = timeout; }
  int GetConnectionTimeout() const { return connection_timeout_; }
  void SetRequestFlag(int request_flag) { request_flag_ = request_flag; }
  int GetRequestFlag() const { return request_flag_; }
  int64_t GetHeartBeatFrameSentBytesAndReset();
  int64_t GetHeartBeatFrameReceivedBytesAndReset();
  int64_t GetDataFrameSentBytesAndReset();
  int64_t GetDataFrameReceivedBytesAndReset();

  // Called when the stream ends the WebSocket Opening Handshake.
  // This method is public for testing.
  void OnFinishOpeningHandshake(
      std::unique_ptr<WebSocketHandshakeResponseInfo> response);

 private:
  friend class WSClient;
  friend class WSClientTest;
  class PendingReceivedFrame;
  int connection_timeout_{0};
  int request_flag_{0};
  int64_t sent_heartbeat_frame_bytes_{0};
  int64_t received_heartbeat_frame_bytes_{0};
  int64_t sent_data_frame_bytes_{0};
  int64_t received_data_frame_bytes_{0};
  // Frames that have been read but not yet forwarded to the renderer due to
  // lack of quota.
  base::queue<PendingReceivedFrame> pending_received_frames_;
  // The remaining amount of quota that the renderer will allow us to send on
  // this logical channel (quota units).
  uint64_t current_receive_quota_{0};

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
  uint64_t recv_frame_size_{0};

  std::unique_ptr<Throttle> upload_throttle_;
  std::unique_ptr<Throttle> download_throttle_;

  int64_t pre_given_up_speed_{-1};
  int64_t pre_given_down_speed_{-1};
  int64_t cur_given_up_speed_{-1};
  int64_t cur_given_down_speed_{-1};

  uint64_t accumulate_recv_bytes_;
  uint64_t accumulate_sent_bytes_;
  base::TimeTicks throttle_start_timing_;

  void InitAndUpdateThrottles();
  void CalculateAndNotifyThrottleInfo(bool channel_dropped = false);
#endif

#endif

 private:
  // The object passes through a linear progression of states from
  // FRESHLY_CONSTRUCTED to CLOSED, except that the SEND_CLOSED and RECV_CLOSED
  // states may be skipped in case of error.
  enum State {
    FRESHLY_CONSTRUCTED,
    CONNECTING,
    CONNECTED,
    SEND_CLOSED,  // A Close frame has been sent but not received.
    RECV_CLOSED,  // Used briefly between receiving a Close frame and sending
                  // the response. Once the response is sent, the state changes
                  // to CLOSED.
    CLOSE_WAIT,   // The Closing Handshake has completed, but the remote server
                  // has not yet closed the connection.
    CLOSED,       // The Closing Handshake has completed and the connection
                  // has been closed; or the connection is failed.
  };

  // Implementation of WebSocketStream::ConnectDelegate for
  // WebSocketChannel. WebSocketChannel does not inherit from
  // WebSocketStream::ConnectDelegate directly to avoid cluttering the public
  // interface with the implementation of those methods, and because the
  // lifetime of a WebSocketChannel is longer than the lifetime of the
  // connection process.
  class ConnectDelegate;

  // Starts the connection process, using the supplied stream request creation
  // callback.
  void SendAddChannelRequestWithSuppliedCallback(
      const GURL& socket_url,
      const std::vector<std::string>& requested_protocols,
      const url::Origin& origin,
      const SiteForCookies& site_for_cookies,
      const IsolationInfo& isolation_info,
      const HttpRequestHeaders& additional_headers,
      NetworkTrafficAnnotationTag traffic_annotation,
      WebSocketStreamRequestCreationCallback callback);

  // Called when a URLRequest is created for handshaking.
  void OnCreateURLRequest(URLRequest* request);

  // Success callback from WebSocketStream::CreateAndConnectStream(). Reports
  // success to the event interface. May delete |this|.
  void OnConnectSuccess(
      std::unique_ptr<WebSocketStream> stream,
      std::unique_ptr<WebSocketHandshakeResponseInfo> response);

  // Failure callback from WebSocketStream::CreateAndConnectStream(). Reports
  // failure to the event interface. May delete |this|.
  void OnConnectFailure(const std::string& message);

  // SSL certificate error callback from
  // WebSocketStream::CreateAndConnectStream(). Forwards the request to the
  // event interface.
  void OnSSLCertificateError(
      std::unique_ptr<WebSocketEventInterface::SSLErrorCallbacks>
          ssl_error_callbacks,
      int net_error,
      const SSLInfo& ssl_info,
      bool fatal);

  // Authentication request from WebSocketStream::CreateAndConnectStream().
  // Forwards the request to the event interface.
  int OnAuthRequired(const AuthChallengeInfo& auth_info,
                     scoped_refptr<HttpResponseHeaders> response_headers,
                     const IPEndPoint& remote_endpoint,
                     base::OnceCallback<void(const AuthCredentials*)> callback,
                     base::Optional<AuthCredentials>* credentials);

  // Sets |state_| to |new_state| and updates UMA if necessary.
  void SetState(State new_state);

  // Returns true if state_ is SEND_CLOSED, CLOSE_WAIT or CLOSED.
  bool InClosingState() const;

  // Calls WebSocketStream::WriteFrames() with the appropriate arguments
  ChannelState WriteFrames() WARN_UNUSED_RESULT;

  // Callback from WebSocketStream::WriteFrames. Sends pending data or adjusts
  // the send quota of the renderer channel as appropriate. |result| is a net
  // error code, usually OK. If |synchronous| is true, then OnWriteDone() is
  // being called from within the WriteFrames() loop and does not need to call
  // WriteFrames() itself.
  ChannelState OnWriteDone(bool synchronous, int result) WARN_UNUSED_RESULT;

  // Callback from WebSocketStream::ReadFrames. Handles any errors and processes
  // the returned chunks appropriately to their type. |result| is a net error
  // code. If |synchronous| is true, then OnReadDone() is being called from
  // within the ReadFrames() loop and does not need to call ReadFrames() itself.
  ChannelState OnReadDone(bool synchronous, int result) WARN_UNUSED_RESULT;

  // Handles a single frame that the object has received enough of to process.
  // May call |event_interface_| methods, send responses to the server, and
  // change the value of |state_|.
  //
  // This method performs sanity checks on the frame that are needed regardless
  // of the current state. Then, calls the HandleFrameByState() method below
  // which performs the appropriate action(s) depending on the current state.
  ChannelState HandleFrame(std::unique_ptr<WebSocketFrame> frame)
      WARN_UNUSED_RESULT;

  // Handles a single frame depending on the current state. It's used by the
  // HandleFrame() method.
  ChannelState HandleFrameByState(const WebSocketFrameHeader::OpCode opcode,
                                  bool final,
                                  base::span<const char> payload)
      WARN_UNUSED_RESULT;

  // Forwards a received data frame to the renderer, if connected. If
  // |expecting_continuation| is not equal to |expecting_to_read_continuation_|,
  // will fail the channel. Also checks the UTF-8 validity of text frames.
  ChannelState HandleDataFrame(WebSocketFrameHeader::OpCode opcode,
                               bool final,
                               base::span<const char> payload)
      WARN_UNUSED_RESULT;

  // Handles an incoming close frame with |code| and |reason|.
  ChannelState HandleCloseFrame(uint16_t code,
                                const std::string& reason) WARN_UNUSED_RESULT;

  // Responds to a closing handshake initiated by the server.
  ChannelState RespondToClosingHandshake() WARN_UNUSED_RESULT;

  // Low-level method to send a single frame. Used for both data and control
  // frames. Either sends the frame immediately or buffers it to be scheduled
  // when the current write finishes. |fin| and |op_code| are defined as for
  // SendFrame() above, except that |op_code| may also be a control frame
  // opcode.
  ChannelState SendFrameInternal(bool fin,
                                 WebSocketFrameHeader::OpCode op_code,
                                 scoped_refptr<IOBuffer> buffer,
                                 uint64_t buffer_size) WARN_UNUSED_RESULT;

  // Performs the "Fail the WebSocket Connection" operation as defined in
  // RFC6455. A NotifyFailure message is sent to the renderer with |message|.
  // The renderer will log the message to the console but not expose it to
  // Javascript. Javascript will see a Close code of AbnormalClosure (1006) with
  // an empty reason string. If state_ is CONNECTED then a Close message is sent
  // to the remote host containing the supplied |code| and |reason|. If the
  // stream is open, closes it and sets state_ to CLOSED. This function deletes
  // |this|.
  void FailChannel(const std::string& message,
                   uint16_t code,
                   const std::string& reason);

  // Sends a Close frame to Start the WebSocket Closing Handshake, or to respond
  // to a Close frame from the server. As a special case, setting |code| to
  // kWebSocketErrorNoStatusReceived will create a Close frame with no payload;
  // this is symmetric with the behaviour of ParseClose.
  ChannelState SendClose(uint16_t code,
                         const std::string& reason) WARN_UNUSED_RESULT;

  // Parses a Close frame payload. If no status code is supplied, then |code| is
  // set to 1005 (No status code) with empty |reason|. If the reason text is not
  // valid UTF-8, then |reason| is set to an empty string. If the payload size
  // is 1, or the supplied code is not permitted to be sent over the network,
  // then false is returned and |message| is set to an appropriate console
  // message.
  bool ParseClose(base::span<const char> payload,
                  uint16_t* code,
                  std::string* reason,
                  std::string* message);

  // Drop this channel.
  // If there are pending opening handshake notifications, notify them
  // before dropping. This function deletes |this|.
  void DoDropChannel(bool was_clean, uint16_t code, const std::string& reason);

  // Called if the closing handshake times out. Closes the connection and
  // informs the |event_interface_| if appropriate.
  void CloseTimeout();

  // The URL of the remote server.
  GURL socket_url_;

  // The object receiving events.
  const std::unique_ptr<WebSocketEventInterface> event_interface_;

  // The URLRequestContext to pass to the WebSocketStream creator.
  URLRequestContext* const url_request_context_;

  // The WebSocketStream on which to send and receive data.
  std::unique_ptr<WebSocketStream> stream_;

  // A data structure containing a vector of frames to be sent and the total
  // number of bytes contained in the vector.
  class SendBuffer;
  // Data that is currently pending write, or NULL if no write is pending.
  std::unique_ptr<SendBuffer> data_being_sent_;
  // Data that is queued up to write after the current write completes.
  // Only non-NULL when such data actually exists.
  std::unique_ptr<SendBuffer> data_to_send_next_;

  // Destination for the current call to WebSocketStream::ReadFrames
  std::vector<std::unique_ptr<WebSocketFrame>> read_frames_;

  // Handle to an in-progress WebSocketStream creation request. Only non-NULL
  // during the connection process.
  std::unique_ptr<WebSocketStreamRequest> stream_request_;

  // Timer for the closing handshake.
  base::OneShotTimer close_timer_;

  // Timeout for the closing handshake.
  base::TimeDelta closing_handshake_timeout_;

  // Timeout for the underlying connection close after completion of closing
  // handshake.
  base::TimeDelta underlying_connection_close_timeout_;

  // Storage for the status code and reason from the time the Close frame
  // arrives until the connection is closed and they are passed to
  // OnDropChannel().
  bool has_received_close_frame_;
  uint16_t received_close_code_;
  std::string received_close_reason_;

  // The current state of the channel. Mainly used for sanity checking, but also
  // used to track the close state.
  State state_;

#if !BUILDFLAG(TTNET_IMPLEMENT) || defined(BASE_I18N_IMPLEMENTATION)
  // UTF-8 validator for outgoing Text messages.
  base::StreamingUtf8Validator outgoing_utf8_validator_;
  bool sending_text_message_;

  // UTF-8 validator for incoming Text messages.
  base::StreamingUtf8Validator incoming_utf8_validator_;
#else
  bool sending_text_message_;
#endif
  bool receiving_text_message_;

  // True if we are in the middle of receiving a message.
  bool expecting_to_handle_continuation_;

  // True if we have already sent the type (Text or Binary) of the current
  // message to the renderer. This can be false if the message is empty so far.
  bool initial_frame_forwarded_;

#if !BUILDFLAG(TTNET_IMPLEMENT) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  // UT Fix WebSocketEndToEndTest.HstsHttpsToWebSocket ,tcmalloc::Abort
  // True if we're waiting for OnReadDone() callback.
  bool is_reading_ = false;
#endif

  DISALLOW_COPY_AND_ASSIGN(WebSocketChannel);
};

}  // namespace net

#endif  // NET_WEBSOCKETS_WEBSOCKET_CHANNEL_H_
