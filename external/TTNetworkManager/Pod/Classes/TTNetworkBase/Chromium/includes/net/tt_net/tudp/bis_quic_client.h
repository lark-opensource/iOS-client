#ifndef NET_TT_NET_TUDP_BIS_QUIC_CLIENT_H_
#define NET_TT_NET_TUDP_BIS_QUIC_CLIENT_H_

#include "base/memory/weak_ptr.h"
#include "net/tt_net/tudp/bis_client.h"

namespace net {

class BisQuicClient : public BisClient {
 public:
  BisQuicClient(Delegate* delegate, const ConnConfig& config);
  ~BisQuicClient() override;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class BisQuicClientTest;

  // BisClient implemenations:
  void SetUTInfoForTesting(uint32_t stream_id, uint32_t case_id) override;
#endif
  // BisClient implemenations:
  void CreateStreamInternal(uint32_t stream_id,
                            int32_t priority,
                            const std::string& early_data) override;
  void OnStreamComplete(int rv, uint32_t stream_id) override;
  void OnReadComplete(int rv, uint32_t stream_id) override;

  void ReportQuicError(uint32_t stream_id) const;

  base::WeakPtrFactory<BisQuicClient> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(BisQuicClient);
};

}  // namespace net

#endif  // NET_TT_NET_TUDP_BIS_QUIC_CLIENT_H_
