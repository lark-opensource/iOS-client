// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_STREAM_ADAPTERS_H_
#define NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_STREAM_ADAPTERS_H_

#include <memory>

#include "base/memory/weak_ptr.h"
#include "net/base/completion_once_callback.h"
#include "net/quic/bidirectional_stream_quic_impl.h"
#include "net/websockets/websocket_basic_stream.h"

namespace spdy {
class SpdyHeaderBlock;
}

namespace net {

class IOBuffer;

class WebSocketQuicStreamAdapter : public WebSocketBasicStream::Adapter,
                                   public BidirectionalStreamImpl::Delegate {
 public:
  class Delegate {
   public:
    virtual ~Delegate() = default;
    virtual void OnStreamReady(bool request_headers_sent) = 0;
    virtual void OnHeadersReceived(
        const spdy::SpdyHeaderBlock& response_headers) = 0;
    virtual void OnTrailersReceived(const spdy::SpdyHeaderBlock& trailers) = 0;
    // Might destroy |this|.
    virtual void OnFailed(int status) = 0;
  };

  // |delegate| must be valid until DetachDelegate() is called.
  WebSocketQuicStreamAdapter(
      std::unique_ptr<BidirectionalStreamQuicImpl> stream,
      Delegate* delegate);
  ~WebSocketQuicStreamAdapter() override;

  void DetachDelegate() { delegate_ = nullptr; }
  // WebSocketBasicStream::Adapter methods.

  int Read(IOBuffer* buf,
           int buf_len,
           CompletionOnceCallback callback) override;

  // Write() must not be called before Delegate::OnHeadersSent() is called.
  // Write() always returns asynchronously.
  int Write(IOBuffer* buf,
            int buf_len,
            CompletionOnceCallback callback,
            const NetworkTrafficAnnotationTag& traffic_annotation) override;

  void Disconnect() override;
  bool is_initialized() const override;

  // BidirectionalStreamImpl::Delegate
  void OnStreamReady(bool request_headers_sent) override;
  void OnHeadersReceived(
      const spdy::SpdyHeaderBlock& response_headers) override;
  void OnDataRead(int bytes_read) override;
  void OnDataSent() override;
  void OnTrailersReceived(const spdy::SpdyHeaderBlock& trailers) override;
  void OnFailed(int status) override;

 private:
  // The underlying SpdyStream.
  std::unique_ptr<BidirectionalStreamQuicImpl> stream_;
  Delegate* delegate_{nullptr};
  // The error code with which SpdyStream was closed.
  int stream_error_;

  // Read callback saved for asynchronous reads.
  // Whenever |read_data_| is not empty, |read_callback_| must be null.
  CompletionOnceCallback read_callback_;

  // Write length saved to be passed to |write_callback_|.  This is necessary
  // because SpdyStream::Delegate::OnDataSent() does not pass number of bytes
  // written.
  int write_length_;

  // Write callback saved for asynchronous writes (all writes are asynchronous).
  CompletionOnceCallback write_callback_;

  base::WeakPtrFactory<WebSocketQuicStreamAdapter> weak_factory_;
};

}  // namespace net

#endif  // NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_QUIC_STREAM_ADAPTERS_H_
