#ifndef NET_TT_NET_TUDP_BIS_QUIC_CONNECTION_H_
#define NET_TT_NET_TUDP_BIS_QUIC_CONNECTION_H_

#include "net/quic/quic_chromium_client_session.h"
#include "net/tt_net/tudp/bis_connection.h"

namespace net {

class QuicStreamRequest;

class BisQuicConnection : public BisConnection {
 public:
  class Delegate final {
   public:
    Delegate();
    ~Delegate();

    void OnCollectDNSInfo(const LoadTimingInfo::ConnectTiming& connect_timing);
    void OnCollectSSLInfo(const SSLInfo& ssl_info);
    void OnBisQuicErrorCode(const quic::QuicErrorCode error);

    LoadTimingInfo::ConnectTiming GetConnectTiming() const {
      return connect_timing_;
    }
    SSLInfo GetSSLInfo() const { return ssl_info_; }
    int GetInternalError() const { return quic_internal_error_; }

    base::WeakPtr<BisQuicConnection::Delegate> GetWeakPtr();

   private:
    LoadTimingInfo::ConnectTiming connect_timing_;
    SSLInfo ssl_info_;
    quic::QuicErrorCode quic_internal_error_;

    base::WeakPtrFactory<Delegate> weak_ptr_factory_;
  };

  BisQuicConnection(const HostPortPair& destination,
                    uint32_t timeout,
                    uint32_t ping_peroid);
  ~BisQuicConnection() override;

  // BisConnection implementations:
  int DoResolveProxy() override;
  int DoResolveProxyComplete(int rv) override;
  void InitConnection(CompletionOnceCallback callback) override;
  void CloseConnection(CompletionOnceCallback callback) override;
  bool IsConnected() const override;
  std::unique_ptr<base::Value> GetExtraInfo() override;
  void ReportQuicError(quic::QuicErrorCode rv);

  QuicChromiumClientSession::Handle* session_handle() const;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisQuicClientTest;
#endif

  // BisConnection implementations:
  int DoInitConnection() override;
  int DoInitConnecting(int rv) override;
  int DoInitConnectionComplete(int rv) override;
  int DoCloseConnection() override;
  int DoCloseConnectionComplete(int rv) override;

  void OnIOComplete(int rv);
  void OnFailedOnDefaultNetwork(int rv);
  void Close();

  std::unique_ptr<base::Value> GetCurrentInfo() const;

  std::unique_ptr<QuicStreamRequest> quic_request_;
  uint32_t ping_period_;
  NetErrorDetails net_error_details_;
  const NetLogWithSource net_log_;
  CompletionOnceCallback callback_;

  Delegate delegate_;

  std::unique_ptr<QuicChromiumClientSession::Handle> session_handle_;

  base::WeakPtrFactory<BisQuicConnection> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisQuicConnection);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_QUIC_CONNECTION_H_
