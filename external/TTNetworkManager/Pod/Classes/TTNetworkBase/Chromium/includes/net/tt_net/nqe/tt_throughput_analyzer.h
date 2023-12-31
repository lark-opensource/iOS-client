// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_THROUGHPUT_ANALYZER_H_
#define NET_TT_NET_NQE_TT_THROUGHPUT_ANALYZER_H_

namespace net {

class URLRequest;

class TTThroughputAnalyzer {
 public:
  TTThroughputAnalyzer();
  ~TTThroughputAnalyzer();
  void OnRequestTransactionStarted(const URLRequest& request);
  // For HTTP RTT computing.
  void OnRequestHeaderReceived(const URLRequest& request);
  // For rx throughput computing.
  void OnRequestBytesReceived(const URLRequest& request);
  void OnRequestCompleted(const URLRequest& request);
  void OnRequestDestroyed(const URLRequest& request);
};

}  // namespace net

#endif