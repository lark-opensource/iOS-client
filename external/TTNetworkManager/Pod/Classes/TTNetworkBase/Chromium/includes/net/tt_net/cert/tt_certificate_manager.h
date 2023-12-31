#ifndef NET_TT_NET_CERT_TT_CERTIFICATE_MANAGER_H_
#define NET_TT_NET_CERT_TT_CERTIFICATE_MANAGER_H_

#include <string>
#include <vector>

#include "base/memory/singleton.h"
#include "net/cert/internal/parsed_certificate.h"
#include "net/net_buildflags.h"
#include "net/tt_net/cert/tt_client_cert_identity.h"

namespace net {

struct ClientCertInfo {
  ClientCertInfo();
  ClientCertInfo(const ClientCertInfo&);
  ~ClientCertInfo();

  std::vector<std::string> host_list;

  std::string certificate;

  std::vector<std::string> certificate_chain;

  std::string private_key;
};

class TTCertificateManager {
 public:
  static TTCertificateManager* GetInstance();
  ~TTCertificateManager();

  void InstallServerCertificates(const std::vector<std::string>& certificates);
  void InstallClientCertificates(
      const std::vector<ClientCertInfo>& certificates);

  bool IsValidOfTTTrustStore();

  TTClientCertIdentity* FindClientCertIdentity(const std::string& host) const;

  ParsedCertificateList GetInstalledServerCertificates() const;

  void ClearClientCertificates();

  void RemoveClientCertificate(const std::string& host);

 private:
  friend struct base::DefaultSingletonTraits<TTCertificateManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, InvalidCertificate);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, ValidCertificate);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, ClientCertificate);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, ClientCertificateChain);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, BothValidAndInvalidCertExist);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, RemoveClientCertificate);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager,
                           RemoveClientCertificateSameHost);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManager, ClearClientCertificates);
  FRIEND_TEST_ALL_PREFIXES(TTCertificateManagerTest,
                           ClearSessionCacheOnClientCertChange);
#endif

  TTCertificateManager();

  std::vector<std::string> certificates_;

  std::vector<std::unique_ptr<TTClientCertIdentity>> client_certificates_;

  ParsedCertificateList chain_;

  DISALLOW_COPY_AND_ASSIGN(TTCertificateManager);
};

}  // namespace net
#endif  // NET_TT_NET_CERT_TT_CERTIFICATE_MANAGER_H_
