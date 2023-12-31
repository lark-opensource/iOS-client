// Copyright (c) 2022 The Bytedance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_TT_REQUEST_TYPE_FLAGS_H_
#define NET_TT_NET_BASE_TT_REQUEST_TYPE_FLAGS_H_

namespace net {

enum {

#define TT_REQ_FLAG(label, value) TT_REQ_FLAG_##label = value,
#include "net/tt_net/base/tt_request_type_flags_list.h"
#undef TT_REQ_FLAG

};

}  // namespace net

#endif  // NET_TT_NET_BASE_TT_REQUEST_TYPE_FLAGS_H_