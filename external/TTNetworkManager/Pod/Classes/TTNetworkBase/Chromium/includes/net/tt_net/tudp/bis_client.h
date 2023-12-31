#ifndef NET_TT_NET_TUDP_BIS_CLIENT_H_
#define NET_TT_NET_TUDP_BIS_CLIENT_H_

#include <map>
#include <vector>

#include "base/macros.h"
#include "base/values.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class BisConnection;
class BisStream;

class BisClient : public NetworkChangeNotifier::NetworkChangeObserver,
                  public TTServerConfigObserver {
 public:
  class Delegate {
   public:
    virtual void OnConnected(const std::string& info_json) = 0;
    virtual void OnStreamReady(uint32_t stream_id,
                               const std::string& info_json) = 0;
    virtual void OnError(uint32_t stream_id,
                         int32_t error,
                         const std::string& info_json) = 0;
    virtual void OnReceivedData(uint32_t stream_id,
                                const std::string& data,
                                bool fin) = 0;
    virtual void OnFeedbackLog(uint32_t stream_id,
                               const std::string& info_json) = 0;
    virtual ~Delegate() {}
  };

  class EarlyDataDelegate {
   public:
    virtual ~EarlyDataDelegate() {}
    virtual std::string ModifyEarlyData(uint32_t stream_id,
                                        const std::string& early_data) = 0;
  };

  enum TransportType {
    // transport via QUIC.
    TRANSPORT_UDP = 0,
    // transport via TLS.
    TRANSPORT_TLS = 1,
    // transport via HTTP2.
    TRANSPORT_H2 = 2,
    // transport via SPDY (not implement yet).
    TRANSPORT_SPDY = 3,
  };

  struct ConnConfig {
    ConnConfig();
    ConnConfig(const ConnConfig&);
    ~ConnConfig();

    std::string host;
    uint16_t port;
    uint32_t timeout{10000};
    uint32_t ping_period{10000};
    TransportType transport_type{TRANSPORT_UDP};
    bool auto_rebuild{false};
    int32_t load_flags{0};
  };

  ~BisClient() override;

  virtual void CreateConnection();

  virtual void CreateStream(uint32_t stream_id,
                            int32_t priority,
                            const std::string& early_data);

  virtual bool IsConnectionReady() const;

  virtual bool IsStreamReady(uint32_t stream_id) const;

  virtual void SendData(uint32_t stream_id, const std::string& data);

  virtual void CloseStream(uint32_t stream_id);

  virtual void CloseConnection();

  void SetEarlyDataDelegate(EarlyDataDelegate* delegate) {
    early_data_delegate_ = delegate;
  }

  std::string ModifyEarlyData(uint32_t stream_id,
                              const std::string& early_data);

  static std::unique_ptr<BisClient> CreateBisClient(Delegate* delegate,
                                                    const ConnConfig& config);

  virtual void OnStreamComplete(int rv, uint32_t stream_id);

  virtual void OnReadComplete(int rv, uint32_t stream_id) = 0;

  uint64_t sent_bytes(uint32_t stream_id) const;

  uint64_t received_bytes(uint32_t stream_id) const;

 protected:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisHttp2ClientTest;
  friend class BisTlsClientTest;
  friend class BisQuicClientTest;

  virtual void SetUTInfoForTesting(uint32_t stream_id, uint32_t case_id);
#endif

  BisClient(Delegate* delegate, const ConnConfig& config);

  virtual void OnSendDataComplete(int rv, uint32_t stream_id);

  virtual void OnCloseConnectionComplete(int rv);

  virtual void OnCloseStreamComplete(int rv, uint32_t stream_id);

  virtual void OnConnectionComplete(int rv);

  virtual std::string ConstructExtraInfo(uint32_t stream_id,
                                         const std::string& extra_info);

  virtual void CreateStreamInternal(uint32_t stream_id,
                                    int32_t priority,
                                    const std::string& early_data) = 0;

  void RemoveStream(uint32_t stream_id);

  // NetworkChangeObserver implementations:
  void OnNetworkChanged(NetworkChangeNotifier::ConnectionType type) override;

  void NetworkChanged(NetworkChangeNotifier::ConnectionType type);

  // TTServerConfigObserver implementations:
  void OnServerConfigChanged(
      UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  void OnCloseConnectionByConfig();

  int64_t DoRetry(int rv);

  uint64_t sent_bytes_;
  uint64_t received_bytes_;
  uint32_t retry_cnt_;
  uint32_t retry_max_attempts_;
  int64_t retry_interval_;
  bool is_connected_;
  std::set<int> retry_error_list_;

  Delegate* delegate_;
  ConnConfig config_;
  EarlyDataDelegate* early_data_delegate_;
  std::unique_ptr<BisConnection> connection_;
  std::map<uint32_t, std::unique_ptr<BisStream>> streams_;
  std::unique_ptr<base::Value> request_log_;
  base::OneShotTimer retry_timer_;

  base::WeakPtrFactory<BisClient> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisClient);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_CLIENT_H_
