// Copyright 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_UTIL_TTNET_H_
#define NET_TT_NET_BASE_UTIL_TTNET_H_

#include <string>

namespace net {

// Return true if pattern string is valid regular expression.
bool IsPatternStringValidForTTNet(const std::string& pattern);

}  // namespace net

#endif  // NET_TT_NET_BASE_UTIL_TTNET_H_