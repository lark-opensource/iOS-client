#ifndef NET_TT_NET_TUDP_BIS_HTTP2_CONNECTION_H_
#define NET_TT_NET_TUDP_BIS_HTTP2_CONNECTION_H_

#include "net/tt_net/tudp/bis_tls_connection.h"

namespace net {

class BisHttp2Connection : public BisTlsConnection {
 public:
  BisHttp2Connection(const HostPortPair& destination,
                     uint32_t timeout,
                     int32_t load_flags);
  ~BisHttp2Connection() override;

  // BisConnection implementations:
  bool IsConnected() const override;
  // Non idempotent. Connection info is sent back once.
  std::unique_ptr<base::Value> GetExtraInfo() override;

 private:
  // BisConnection implementations:
  int DoCloseConnection() override;

  DISALLOW_COPY_AND_ASSIGN(BisHttp2Connection);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_HTTP2_CONNECTION_H_
