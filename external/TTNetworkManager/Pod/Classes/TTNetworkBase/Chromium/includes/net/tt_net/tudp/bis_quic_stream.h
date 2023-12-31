// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_TUDP_BIS_QUIC_STREAM_H_
#define NET_TT_NET_TUDP_BIS_QUIC_STREAM_H_

#include "net/quic/quic_chromium_client_session.h"
#include "net/quic/quic_chromium_client_stream.h"
#include "net/tt_net/tudp/bis_stream.h"

namespace net {

class QuicChromiumClientSession;

class BisQuicStream : public BisStream,
                      public QuicChromiumClientStream::RawStreamDelegate {
 public:
  BisQuicStream(uint32_t stream_id,
                int32_t priority,
                const std::string& early_data,
                std::unique_ptr<QuicChromiumClientSession::Handle> session);
  ~BisQuicStream() override;

  // BisStream implementations:
  bool IsStreamReady() const override;
  int WriteData(const std::string& data, StreamOnceCallback callback) override;
  int ReadData(StreamOnceCallback callback) override;
  bool fin_received() const override;

  // QuicChromiumClientStream::RawStreamDelegate implementations:
  bool IsSkipReadingHeader() const override;

  const QuicChromiumClientStream::Handle* quic_stream() const {
    return stream_.get();
  }
 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisQuicClientTest;

  void InitializationForTesting(const std::string& early_data);
  void WriteDataForTesting(const std::string& data);

  // BisStream implementations:
  void SetUTInfoForTesting(uint32_t case_id) override;

  std::string read_body_for_testing_;
  bool one_rtt_key_ready_for_testing_;
  uint32_t stream_error_for_testing_;
#endif

  // BisStream implementations:
  void Close() override;
  int DoInitStream() override;
  int DoInitStreamComplete(int rv) override;
  int DoSendEarlyData() override;
  int DoSendEarlyDataComplete(int rv) override;

  void DidCompleteWrite(int rv);
#if !BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void DidCompleteRead(int rv);
  int WriteDataInternal(const std::string& data);
#endif

  int MapStreamError(int rv);

  // If |has_response_status_| is false, sets |response_status| to the result
  // of ComputeResponseStatus(). Returns |response_status_|.
  int GetResponseStatus();
  // Sets the result of |ComputeResponseStatus()| as the |response_status_|.
  void SaveResponseStatus();
  // Sets |response_status_| to |response_status| and sets
  // |has_response_status_| to true.
  void SetResponseStatus(int response_status);
  // Computes the correct response status based on the status of the handshake,
  // |session_error|, |connection_error| and |stream_error|.
  int ComputeResponseStatus() const;

  QuicChromiumClientSession::Handle* quic_session() {
    return static_cast<QuicChromiumClientSession::Handle*>(session_.get());
  }

  const QuicChromiumClientSession::Handle* quic_session() const {
    return static_cast<const QuicChromiumClientSession::Handle*>(
        session_.get());
  }

  const std::unique_ptr<MultiplexedSessionHandle> session_;
  std::unique_ptr<QuicChromiumClientStream::Handle> stream_;

  // Error code from the connection shutdown.
  int session_error_;
  // true if response_status_ as been set.
  bool has_response_status_;
  int response_status_;
  bool write_queue_full_;

  base::WeakPtrFactory<BisQuicStream> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisQuicStream);
};

}  // namespace net
#endif  // NET_TT_NET_TUDP_BIS_QUIC_STREAM_H_
