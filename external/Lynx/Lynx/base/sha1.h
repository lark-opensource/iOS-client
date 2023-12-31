// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_BASE_SHA1_H_
#define LYNX_BASE_SHA1_H_

#include <stddef.h>

#include <string>

namespace lynx {
namespace base {

// These functions perform SHA-1 operations.

static constexpr size_t kSHA1Length = 20;  // Length in bytes of a SHA-1 hash.

// Computes the SHA-1 hash of the input string |str| and returns the full
// hash.
std::string SHA1HashString(const std::string& str);

// Computes the SHA-1 hash of the |len| bytes in |data| and puts the hash
// in |hash|. |hash| must be kSHA1Length bytes long.
void SHA1HashBytes(const unsigned char* data, size_t len, unsigned char* hash);

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_SHA1_H_
