// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_NETLOG_COMPRESS_UTIL_H_
#define NET_TTNET_NETLOG_COMPRESS_UTIL_H_

#include <stddef.h>
#include <string>

namespace net {
// from compression_util.h

// Compresses the data in |input| using gzip, storing the result in |output|.
// |input| and |output| are allowed to be the same string (in-place operation).
bool GzipCompress(const std::string& input, std::string* output);

// Uncompresses the data in |input| using gzip, storing the result in |output|.
// |input| and |output| are allowed to be the same string (in-place operation).
bool GzipUncompress(const std::string& input, std::string* output);

}  // namespace net

#endif /* NET_TTNET_NETLOG_COMPRESS_UTIL_H_ */
