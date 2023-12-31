#ifndef NET_TT_NET_CERT_TT_SSL_PRIVATE_KEY_H_
#define NET_TT_NET_CERT_TT_SSL_PRIVATE_KEY_H_

#include "base/memory/ref_counted.h"
#include "third_party/boringssl/src/include/openssl/base.h"

namespace net {

class SSLPrivateKey;

// Returns a new SSLPrivateKey which uses |key| for signing operations or
// nullptr on error.
scoped_refptr<SSLPrivateKey> WrapTTSSLPrivateKey(bssl::UniquePtr<EVP_PKEY> key);
}  // namespace net

#endif  // NET_TT_NET_CERT_TT_SSL_PRIVATE_KEY_H_
