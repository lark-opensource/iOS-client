#ifndef NET_TT_NET_TUDP_BIS_HTTP2_CLIENT_H_
#define NET_TT_NET_TUDP_BIS_HTTP2_CLIENT_H_

#include "base/memory/weak_ptr.h"
#include "net/tt_net/tudp/bis_client.h"

namespace net {

class BisHttp2Client : public BisClient {
 public:
  BisHttp2Client(Delegate* delegate, const ConnConfig& config);
  ~BisHttp2Client() override;

 private:
  friend class BisHttp2ClientTest;

  // BisClient implemenations:
  void CreateStreamInternal(uint32_t stream_id,
                            int32_t priority,
                            const std::string& early_data) override;
  void OnReadComplete(int rv, uint32_t stream_id) override;

  base::WeakPtrFactory<BisHttp2Client> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisHttp2Client);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_HTTP2_CLIENT_H_
