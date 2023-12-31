// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_FRONTIER_DETECT_MANAGER_H_
#define NET_TT_NET_NET_DETECT_TT_FRONTIER_DETECT_MANAGER_H_

#include <string>

#include "base/memory/singleton.h"
#include "base/values.h"

#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/tt_net/websocket/tt_websocket_client.h"

namespace net {

class TTFrontierDetectManager : public TTServerConfigObserver,
                                public WSClient::Delegate {
 public:
  static TTFrontierDetectManager* GetInstance();

  void Init();

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;
  bool HandleResponseResult(URLRequest* url_request, int net_error);

  // net::WSClient::Delegate implementations:
  void OnConnectionStateChanged(WSClient::Delegate::ConnectionState state,
                                const std::string& url) override;
  void OnConnectionError(WSClient::Delegate::ConnectionState state,
                         const std::string& url,
                         const std::string& error) override;
  void OnMessageReceived(const std::string& message, int type) override;
  void OnFeedbackLog(const std::string& log) override;
  void OnTrafficChanged(const std::string& url,
                        int64_t sent_bytes,
                        int64_t received_bytes,
                        bool is_heartbeat_frame) override;

 private:
  friend struct base::DefaultSingletonTraits<TTFrontierDetectManager>;
  TTFrontierDetectManager();
  ~TTFrontierDetectManager() override;

  bool has_inited_{false};

  WSClient* connection_{nullptr};
  std::unique_ptr<net::WSClient> owned_connection_;
  WSClient::ConnectionParams frontier_params_;
  bool frontier_has_started_{false};
  int64_t local_detect_version_{0};
  int64_t local_detect_stop_time_{0};
  int64_t remote_detect_version_{0};
  int64_t remote_detect_interval_{60};

  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;

  void StartConnection();
  void StopConnection();
  bool TryStartConnection();
  bool IsConnectionAlive() const;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTFrontierDetectTest;
  FRIEND_TEST_ALL_PREFIXES(TTFrontierDetectTest, TryStartConnection);
#endif

  DISALLOW_COPY_AND_ASSIGN(TTFrontierDetectManager);
};

}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_FRONTIER_DETECT_MANAGER_H_
