// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef QUICHE_QUIC_CORE_UBER_QUIC_STREAM_ID_MANAGER_H_
#define QUICHE_QUIC_CORE_UBER_QUIC_STREAM_ID_MANAGER_H_

#include "net/third_party/quiche/src/quic/core/quic_stream_id_manager.h"
#include "net/third_party/quiche/src/quic/core/quic_types.h"

namespace quic {

namespace test {
class QuicSessionPeer;
class UberQuicStreamIdManagerPeer;
}  // namespace test

class QuicSession;

// This class comprises two QuicStreamIdManagers, which manage bidirectional and
// unidirectional stream IDs, respectively.
class QUIC_EXPORT_PRIVATE UberQuicStreamIdManager {
 public:
  UberQuicStreamIdManager(
      Perspective perspective,
      ParsedQuicVersion version,
      QuicStreamIdManager::DelegateInterface* delegate,
      QuicStreamCount max_open_outgoing_bidirectional_streams,
      QuicStreamCount max_open_outgoing_unidirectional_streams,
      QuicStreamCount max_open_incoming_bidirectional_streams,
      QuicStreamCount max_open_incoming_unidirectional_streams);

  // Called on |max_open_streams| outgoing streams can be created because of 1)
  // config negotiated or 2) MAX_STREAMS received. Returns true if new
  // streams can be created.
  bool MaybeAllowNewOutgoingBidirectionalStreams(
      QuicStreamCount max_open_streams);
  bool MaybeAllowNewOutgoingUnidirectionalStreams(
      QuicStreamCount max_open_streams);

  // Sets the limits to max_open_streams.
  void SetMaxOpenIncomingBidirectionalStreams(QuicStreamCount max_open_streams);
  void SetMaxOpenIncomingUnidirectionalStreams(
      QuicStreamCount max_open_streams);

  // Returns true if next outgoing bidirectional stream ID can be allocated.
  bool CanOpenNextOutgoingBidirectionalStream() const;

  // Returns true if next outgoing unidirectional stream ID can be allocated.
  bool CanOpenNextOutgoingUnidirectionalStream() const;

  // Returns the next outgoing bidirectional stream id.
  QuicStreamId GetNextOutgoingBidirectionalStreamId();

  // Returns the next outgoing unidirectional stream id.
  QuicStreamId GetNextOutgoingUnidirectionalStreamId();

  // Returns true if the incoming |id| is within the limit.
  bool MaybeIncreaseLargestPeerStreamId(QuicStreamId id,
                                        std::string* error_details);

  // Called when |id| is released.
  void OnStreamClosed(QuicStreamId id);

  // Called when a STREAMS_BLOCKED frame is received.
  bool OnStreamsBlockedFrame(const QuicStreamsBlockedFrame& frame,
                             std::string* error_details);

  // Returns true if |id| is still available.
  bool IsAvailableStream(QuicStreamId id) const;

  QuicStreamCount GetMaxAllowdIncomingBidirectionalStreams() const;

  QuicStreamCount GetMaxAllowdIncomingUnidirectionalStreams() const;

  QuicStreamId GetLargestPeerCreatedStreamId(bool unidirectional) const;

  QuicStreamId next_outgoing_bidirectional_stream_id() const;
  QuicStreamId next_outgoing_unidirectional_stream_id() const;

  QuicStreamCount max_outgoing_bidirectional_streams() const;
  QuicStreamCount max_outgoing_unidirectional_streams() const;

  QuicStreamCount max_incoming_bidirectional_streams() const;
  QuicStreamCount max_incoming_unidirectional_streams() const;

  QuicStreamCount advertised_max_incoming_bidirectional_streams() const;
  QuicStreamCount advertised_max_incoming_unidirectional_streams() const;

  QuicStreamCount outgoing_bidirectional_stream_count() const;
  QuicStreamCount outgoing_unidirectional_stream_count() const;

#if BUILDFLAG(TTNET_IMPLEMENT)
  QuicStreamCount GetNumOutgoingBidirectionalStreams() const;
#endif

 private:
  friend class test::QuicSessionPeer;
  friend class test::UberQuicStreamIdManagerPeer;

  ParsedQuicVersion version_;
  // Manages stream IDs of bidirectional streams.
  QuicStreamIdManager bidirectional_stream_id_manager_;

  // Manages stream IDs of unidirectional streams.
  QuicStreamIdManager unidirectional_stream_id_manager_;
};

}  // namespace quic

#endif  // QUICHE_QUIC_CORE_UBER_QUIC_STREAM_ID_MANAGER_H_
