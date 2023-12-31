// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NETLOG_TT_ENCRYPT_UTIL_H_
#define NET_TT_NET_NETLOG_TT_ENCRYPT_UTIL_H_

#include <memory>
#include "base/macros.h"

namespace crypto {
class SymmetricKey;
class Encryptor;
}  // namespace crypto

namespace net {

class TokenEncryptor final {
 public:
  TokenEncryptor();
  ~TokenEncryptor();

  bool EncryptString(const std::string& value, std::string& encrypted);
  bool DecryptString(const std::string& encrypted, std::string& value);
  bool Sign(const std::string& value, std::string& hmac);
  bool CheckSign(const std::string& value, const std::string& sign);

  bool InitByDerivation(const std::string& password);
  bool InitByImport(const std::string& encryption_key,
                    const std::string& mac_key);
  bool ExportKeys(std::string& encryption_key, std::string& mac_key) const;

 protected:
  std::unique_ptr<crypto::Encryptor> encryptor_;
  std::unique_ptr<crypto::SymmetricKey> encryption_key_;
  std::unique_ptr<crypto::SymmetricKey> mac_key_;

 private:
  static const char kSaltSalt[];
  static const size_t kSaltKeySizeInBits = 128;
  static const size_t kDerivedKeySizeInBits = 128;
  static const size_t kIvSize = 16;
  static const size_t kHashSize = 32;

  static const size_t kSaltIterations = 1001;
  static const size_t kEncryptionIterations = 1003;
  static const size_t kSigningIterations = 1004;

 private:
  DISALLOW_COPY_AND_ASSIGN(TokenEncryptor);
};

}  // namespace net
#endif