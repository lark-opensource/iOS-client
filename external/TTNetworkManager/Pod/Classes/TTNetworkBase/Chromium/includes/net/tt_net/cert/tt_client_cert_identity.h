#ifndef NET_TT_NET_CERT_TT_CLIENT_CERT_IDENTITY_H_
#define NET_TT_NET_CERT_TT_CLIENT_CERT_IDENTITY_H_

#include "net/ssl/client_cert_identity.h"

namespace net {

struct ClientCertInfo;

class TTClientCertIdentity : public ClientCertIdentity {
 public:
  TTClientCertIdentity(scoped_refptr<X509Certificate> cert,
                       scoped_refptr<SSLPrivateKey> key,
                       const std::vector<std::string>& host_list);
  ~TTClientCertIdentity() override;

  static std::unique_ptr<TTClientCertIdentity> CreateFromClientCertInfo(
      const ClientCertInfo& client_cert_info);

  bool in_host_list(const std::string& host_name) const;

  // Returns the SSLPrivateKey in a more convenient way, for tests.
  SSLPrivateKey* ssl_private_key() const { return key_.get(); }

  // ClientCertIdentity implementation:
  void AcquirePrivateKey(base::OnceCallback<void(scoped_refptr<SSLPrivateKey>)>
                             private_key_callback) override;

  const std::vector<std::string>& host_list() const { return host_list_; }
#if defined(OS_APPLE)
  SecIdentityRef sec_identity_ref() const override;
#endif

 private:
  scoped_refptr<SSLPrivateKey> key_;

  std::vector<std::string> host_list_;
};

}  // namespace net

#endif  // NET_TT_NET_CERT_TT_CLIENT_CERT_IDENTITY_H_
