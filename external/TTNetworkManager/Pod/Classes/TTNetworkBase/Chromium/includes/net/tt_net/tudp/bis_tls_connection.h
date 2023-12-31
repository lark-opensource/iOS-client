#ifndef NET_TT_NET_TUDP_BIS_TLS_CONNECTION_H_
#define NET_TT_NET_TUDP_BIS_TLS_CONNECTION_H_

#include "net/log/net_log_with_source.h"
#include "net/tt_net/tudp/bis_connection.h"

namespace net {

class ClientSocketHandle;
class HttpAuthController;
class HttpResponseInfo;
class HttpNetworkSession;
class ProxyResolutionRequest;
class StreamSocket;

class BisTlsConnection : public BisConnection {
 public:
  BisTlsConnection(const HostPortPair& destination,
                   uint32_t timeout,
                   int32_t load_flags,
                   bool is_preconnect);
  ~BisTlsConnection() override;

  // BisConnection implementations:
  void InitConnection(CompletionOnceCallback callback) override;
  void CloseConnection(CompletionOnceCallback callback) override;
  bool IsConnected() const override;
  std::unique_ptr<base::Value> GetExtraInfo() override;
  StreamSocket* socket() const;

 protected:
  std::unique_ptr<ClientSocketHandle> socket_handle_;
  HttpNetworkSession* const session_;
  CompletionOnceCallback callback_;
  std::unique_ptr<base::DictionaryValue> connection_info_;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisHttp2ClientTest;
  friend class BisTlsClientTest;
#endif

  // BisConnection implementations:
  int DoResolveProxy() override;
  int DoResolveProxyComplete(int rv) override;
  int DoInitConnection() override;
  int DoInitConnecting(int rv) override;
  int DoInitConnectionComplete(int rv) override;
  int DoCloseConnection() override;
  int DoCloseConnectionComplete(int rv) override;

  void OnIOComplete(int rv);
  void OnIOCompleteWithInfo(
      int rv,
      std::unique_ptr<base::DictionaryValue> connection_info);
  void OnNeedsProxyAuthCallback(const HttpResponseInfo& response,
                                HttpAuthController* auth_controller,
                                base::OnceClosure restart_with_auth_callback);
  void Close();

  const NetLogWithSource net_log_;
  bool is_preconnect_;
  int32_t load_flags_;
  std::unique_ptr<ProxyResolutionRequest> proxy_resolve_request_;

  base::WeakPtrFactory<BisTlsConnection> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisTlsConnection);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_TLS_CONNECTION_H_
