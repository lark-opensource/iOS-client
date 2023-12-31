// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_HANDSHAKE_STREAM_H_
#define NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_HANDSHAKE_STREAM_H_

#include <memory>
#include <string>
#include <vector>

#include "base/memory/weak_ptr.h"
#include "net/base/completion_once_callback.h"
#include "net/http/bidirectional_stream_request_info.h"
#include "net/tt_net/websocket/tt_websocket_quic_stream_adapters.h"
#include "net/websockets/websocket_handshake_stream_base.h"

namespace net {

class WebSocketQuicHandshakeStream
    : public WebSocketHandshakeStreamBase,
      public WebSocketQuicStreamAdapter::Delegate {
 public:
  // |connect_delegate| and |request| must out-live this object.
  WebSocketQuicHandshakeStream(
      std::unique_ptr<QuicChromiumClientSession::Handle> session,
      WebSocketStream::ConnectDelegate* connect_delegate,
      std::vector<std::string> requested_sub_protocols,
      std::vector<std::string> requested_extensions,
      WebSocketStreamRequestAPI* request);

  ~WebSocketQuicHandshakeStream() override;

  // HttpStream methods.
  int InitializeStream(const HttpRequestInfo* request_info,
                       bool can_send_early,
                       RequestPriority priority,
                       const NetLogWithSource& net_log,
                       CompletionOnceCallback callback) override;
  int SendRequest(const HttpRequestHeaders& request_headers,
                  HttpResponseInfo* response,
                  CompletionOnceCallback callback) override;
  int ReadResponseHeaders(CompletionOnceCallback callback) override;
  int ReadResponseBody(IOBuffer* buf,
                       int buf_len,
                       CompletionOnceCallback callback) override;
  void Close(bool not_reusable) override;
  bool IsResponseBodyComplete() const override;
  bool IsConnectionReused() const override;
  void SetConnectionReused() override;
  bool CanReuseConnection() const override;
  int64_t GetTotalReceivedBytes() const override;
  int64_t GetTotalSentBytes() const override;
  bool GetAlternativeService(
      AlternativeService* alternative_service) const override;
  bool GetLoadTimingInfo(LoadTimingInfo* load_timing_info) const override;
  void GetSSLInfo(SSLInfo* ssl_info) override;
  void GetSSLCertRequestInfo(SSLCertRequestInfo* cert_request_info) override;
  bool GetRemoteEndpoint(IPEndPoint* endpoint) override;
  void GetSocketPoolInfo(SocketPoolInfo* socket_pool_info) override;
  HttpResponseInfo::ConnectionInfo GetConnectionInfo() const override;
  void Drain(HttpNetworkSession* session) override;
  void SetPriority(RequestPriority priority) override;
  void PopulateNetErrorDetails(NetErrorDetails* details) override;
  HttpStream* RenewStreamForAuth() override;

  // WebSocketHandshakeStreamBase methods.

  // This is called from the top level once correct handshake response headers
  // have been received. It creates an appropriate subclass of WebSocketStream
  // depending on what extensions were negotiated. This object is unusable after
  // Upgrade() has been called and should be disposed of as soon as possible.
  std::unique_ptr<WebSocketStream> Upgrade(
      const HttpResponseInfo& info) override;

  base::WeakPtr<WebSocketHandshakeStreamBase> GetWeakPtr() override;

  // WebSocketQuicStreamAdapter::Delegate
  void OnStreamReady(bool request_headers_sent) override;
  void OnHeadersReceived(
      const spdy::SpdyHeaderBlock& response_headers) override;
  void OnTrailersReceived(const spdy::SpdyHeaderBlock& trailers) override;
  void OnFailed(int status) override;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class WebSocketQuicHandshakeStreamTest;
  friend class WebSocketQuicStreamAdapterTest;
#endif
  // Validates the response and sends the finished handshake event.
  int ValidateResponse();

  // Check that the headers are well-formed and have a 200 status code,
  // in which case returns OK, otherwise returns ERR_INVALID_RESPONSE.
  int ValidateUpgradeResponse(const HttpResponseHeaders* headers);

  void OnFinishOpeningHandshake();

  void OnFailure(const std::string& message);

  HandshakeResult result_;

  std::unique_ptr<QuicChromiumClientSession::Handle> session_;
  std::unique_ptr<BidirectionalStreamQuicImpl> quic_stream_;
  BidirectionalStreamRequestInfo bidirectionalRequestInfo_;

  // Owned by another object.
  // |connect_delegate| will live during the lifetime of this object.
  WebSocketStream::ConnectDelegate* const connect_delegate_;

  HttpResponseInfo* http_response_info_;

  // The required value for the Sec-WebSocket-Accept header.
  std::string handshake_challenge_response_;

  // The sub-protocols we requested.
  std::vector<std::string> requested_sub_protocols_;

  // The extensions we requested.
  std::vector<std::string> requested_extensions_;

  WebSocketStreamRequestAPI* const stream_request_;

  const HttpRequestInfo* request_info_;

  RequestPriority priority_;

  NetLogWithSource net_log_;

  // WebSocketQuicStreamAdapter holding a WeakPtr to |stream_|.
  // This can be passed on to WebSocketBasicStream when created.
  std::unique_ptr<WebSocketQuicStreamAdapter> stream_adapter_;

  // True if |stream_| has been created then closed.
  bool stream_closed_;

  // The error code corresponding to the reason for closing the stream.
  // Only meaningful if |stream_closed_| is true.
  int stream_error_;

  // True if complete response headers have been received.
  bool response_headers_complete_;

  // Save callback provided in asynchronous HttpStream methods.
  CompletionOnceCallback callback_;

  // The sub-protocol selected by the server.
  std::string sub_protocol_;

  // The extension(s) selected by the server.
  std::string extensions_;

  SSLInfo ssl_info_;

  HttpResponseInfo::ConnectionInfo connection_info_;

  // The extension parameters. The class is defined in the implementation file
  // to avoid including extension-related header files here.
  std::unique_ptr<WebSocketExtensionParams> extension_params_;

  base::WeakPtrFactory<WebSocketQuicHandshakeStream> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(WebSocketQuicHandshakeStream);
};

}  // namespace net

#endif  // NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_HANDSHAKE_STREAM_H_
