// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_BASE_TT_NETWORK_DETECT_ERRORS_H_
#define NET_TT_NET_NET_DETECT_BASE_TT_NETWORK_DETECT_ERRORS_H_

namespace net {
enum NetworkDetectError {

#define NETWORK_DETECT_ERROR(label, value) ND_ERR_##label = value,
#include "net/tt_net/net_detect/base/tt_network_detect_error_list.h"
#undef NETWORK_DETECT_ERROR

};
}  // namespace net

#endif