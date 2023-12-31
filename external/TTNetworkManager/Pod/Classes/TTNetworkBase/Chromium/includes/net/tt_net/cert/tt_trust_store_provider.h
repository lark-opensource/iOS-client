#ifndef NET_TT_NET_CERT_TT_TRUST_STORE_PROVIDER_H_
#define NET_TT_NET_CERT_TT_TRUST_STORE_PROVIDER_H_

#include "net/cert/cert_verify_proc_builtin.h"

namespace net {

class TTTrustStoreProvider : public SystemTrustStoreProvider {
 public:
  TTTrustStoreProvider();
  ~TTTrustStoreProvider() override;

  std::unique_ptr<SystemTrustStore> CreateSystemTrustStore() override;
};

}  // namespace net
#endif  // NET_TT_NET_CERT_TT_TRUST_STORE_PROVIDER_H_
